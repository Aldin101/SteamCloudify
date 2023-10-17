param (
    [string]$1,
    [string]$2
)
$host.ui.RawUI.WindowTitle = "Build Tool"
cls
function Format-Json([Parameter(Mandatory, ValueFromPipeline)][String] $json) {
    $indent = 0;
    ($json -Split '\n' |
        % {
            if ($_ -match '[\}\]]') {
                $indent--
            }
            $line = (' ' * $indent * 2) + $_.TrimStart().Replace(':  ', ': ')
            if ($_ -match '[\{\[]') {
                $indent++
            }
            $line
    }) -Join "`n"
}
cd $script:PSScriptRoot
$Config = Get-Content .\BuildTool.json | ConvertFrom-Json
while (1) {
    while (1) {
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $false) {
            echo "[1] Build database"
            echo "[2] Build multi game installer"
            echo "[3] Build single game installer"
            echo "[4] Build Steam Cloud runtime and background executables"
            echo "[5] Search for game save locations"
            echo "[6] Add a new game to the build config"
            echo "[7] Sync Background.ps1 game specific information with other files"
            if (test-path "c:/program files (x86)/resource hacker/") {
                echo "[8] Uninstall Resource Hacker"
            }
            $selection = Read-Host "What would you like to do"
        } else {
            $selection = [int]$1
        }
        if ($selection -eq 1) {
            echo "Building scripts..."
            foreach ($games in $config.games) {
                $s = Get-Content "$($games.installer)OnlineInstaller.ps1"
                $s.Split([Environment]::NewLine) | Out-Null
                if (test-path ".\$($s[0].TrimStart("# "))\OnlineInstaller.ps1") {
                    $template = get-content ".\$($s[0].TrimStart("# "))\OnlineInstaller.ps1"
                    $newfile = New-Object System.Collections.ArrayList
                    $i=0
                    while ($s[$i].TrimEnd("-") -ne "# Game specific end") {
                        $newfile.Add($s[$i]) | Out-Null
                        ++$i
                    }
                    $i=0
                    while ($template[$i].TrimEnd("-") -ne "# Game specific end") {
                        ++$i
                    }
                    while ($i -lt $template.count) {
                        $newfile.Add($template[$i]) | Out-Null
                        ++$i
                    }
                    $newfile | Set-Content ".\temp.ps1"
                    $s = Get-Content ".\temp.ps1"
                    del ".\temp.ps1"
                }
                $j = [PSCustomObject]@{
                    "Script" =  [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($s))
                }
                $games.installer = $j
            }
            $Config | ConvertTo-Json -depth 32 | Format-Json | Set-Content ".\Database\GameList.json"
            $Config = Get-Content .\BuildTool.json | ConvertFrom-Json
            echo "Transferring files..."
            foreach ($games in $config.games) {
                mkdir ".\Database\$($games.name)" -Force | out-null
                Copy-Item "$($games.installer)\Built Executables\*" ".\Database\$($games.name)\" -Force
                Copy-Item "$($games.installer)\$($games.name).json" ".\Database\$($games.name)\" -Force
            }
        }

        if ($selection -eq 2 -or $selection -eq 3 -or $selection -eq 4 -and !(test-path "C:\Program Files (x86)\Resource Hacker\")) {
            echo "Resource Hacker is not installed, it is required to build executables."
            $choice = read-host "Would you like to install Resource Hacker [Y/n]"
            if ($choice -ne "n" -and $choice -ne "N" -and $choice -ne "no") {
                echo "Installing..."
                winget install AngusJohnson.ResourceHacker --source winget --force --silent
                if (!(test-path "C:\Program Files (x86)\Resource Hacker\")) {
                    echo "Failed to install Resource Hacker, please check your internet connection and try again, or install manually from https://www.angusj.com/resourcehacker/"
                    timeout -1
                    break
                }
            } else {
                echo "Resource Hacker is required to build executables, please install before continuing"
                timeout -1
                break
            }
        }

        if ($selection -eq 2 -or $selection -eq 3 -or $selection -eq 4 -and !(test-path "C:\Program Files\PowerShell\7\") -and !(test-path "C:\Program Files (x86)\PowerShell\7\")) {
            echo "PowerShell 7 is not installed, it is required to build executables."
            $choice = read-host "Would you like to install PowerShell 7 [Y/n]"
            if ($choice -ne "n" -and $choice -ne "N" -and $choice -ne "no") {
                echo "Installing..."
                winget install Microsoft.PowerShell --source winget --force --silent
                if (!(test-path "C:\Program Files\PowerShell\7\") -and !(test-path "C:\Program Files (x86)\PowerShell\7\")) {
                    echo "Failed to install PowerShell 7, please check your internet connection and try again, or install manually from https://github.com/PowerShell/PowerShell/releases/latest"
                    timeout -1
                    break
                }
            } else {
                echo "Powershell 7 is required to build executables, please install before continuing"
                timeout -1
                break
            }
        }
        
        if ($selection -eq 2 -or $selection -eq 3 -or $selection -eq 4 -and !(test-path ".\executionEnabled")) {
            echo "The execution policy for PowerShell 7 will cause builds to fail, would you like to disable execution policy restrictions?"
            $choice = Read-Host "[Y/n]"
            if ($choice -ne "n" -and $choice -ne "N" -and $choice -ne "no") {
                try {
                    Start-Process pwsh -Verb runas -WindowStyle Hidden -ArgumentList "-command `"set-executionpolicy unrestricted`""
                } catch {
                    echo "you need to accept the admin prompt"
                    timeout -1
                    break
                }
                echo "Now you need to allow build.ps1 to execute"
                timeout -1
                try {
                    Start-Process pwsh -Verb runas -WindowStyle Hidden -ArgumentList "-command `"unblock-file $($MyInvocation.MyCommand.Path)`""
                } catch {
                    echo "you need to accept the admin prompt"
                    timeout -1
                    break
                }
                "funnyWord" | Set-Content ".\executionEnabled"
            } else {
                echo "You can not build without disabling policy restrictions, please disable before continuing"
                timeout -1
                break
            }
        }
        
        if ($selection -eq 2) {
            if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $false) {
                $versionString = read-host "What is the desired version number, you can have up to 4 numbers separated by periods"
                $version = $versionString.Split(".")
                if ($version.count -gt 4) {
                    echo "Invalid version number"
                    timeout -1
                    break
                }
                $i=0
                while ($i -lt 4) {
                    if ($version[$i] -eq $null) {
                        $versionNumber = [System.Collections.ArrayList]($version)
                        $versionNumber.Add(0) | out-null
                        $version = $versionNumber.ToArray()
                    }
                    if ($version[$i] -lt 0 -or $version[$i] -gt 65535) {
                        $version[$i] = 0
                    }
                    ++$i
                }
                $rc = Get-Content ".\Multi Game Installer\VersionInfo.rc"
                $rc.Split([Environment]::NewLine) | Out-Null
                $rc[1] = "FILEVERSION $($version[0]),$($version[1]),$($version[2]),$($version[3])"
                $rc[2] = "PRODUCTVERSION $($version[0]),$($version[1]),$($version[2]),$($version[3])"
                $rc[12] = "		VALUE `"FileVersion`", `"$versionString`""
                $rc[17] = "		VALUE `"ProductVersion`", `"$versionString`""
                $rc | Set-Content ".\Multi Game Installer\VersionInfo.rc"
                echo "Building..."
                try {
                    Start-Process pwsh -Verb runAs -WindowStyle Hidden -Wait -ArgumentList "`"$($MyInvocation.MyCommand.Path)`" 2"
                }
                catch {
                    echo "You need to accept the admin prompt"
                    timeout -1
                    break
                }
                echo "Build completed"
                timeout -1
            }
            if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $true) {
                $sed = Get-Content ".\Multi Game Installer\SteamCloudInstaller.sed"
                $sed.Split([Environment]::NewLine)
                $sed[26] = "TargetName=$(Get-Location)\Multi Game Installer\Steam Cloud Installer.exe"
                $sed[34] = "SourceFiles0=$(Get-Location)\Multi Game Installer"
                $sed | Set-Content "C:\SteamCloudInstaller.sed"
                Start-Process "iexpress.exe" "/Q /N C:\SteamCloudInstaller.sed" -Wait
                del "C:\SteamCloudInstaller.sed"
                Start-Process "C:\Program Files (x86)\Resource Hacker\ResourceHacker.exe" "-open `"$($script:PSScriptRoot)\Multi Game Installer\VersionInfo.rc`" -save `"$($script:PSScriptRoot)\Multi Game Installer\VersionInfo.res`" -action compile" -Wait
                Start-Process "C:\Program Files (x86)\Resource Hacker\ResourceHacker.exe" "-open `"$($script:PSScriptRoot)\Multi Game Installer\Steam Cloud Installer.exe`" -save `"$($script:PSScriptRoot)\Multi Game Installer\Steam Cloud Installer.exe`" -action addoverwrite -res `"$($script:PSScriptRoot)\Multi Game Installer\Icon.ico`" -mask ICONGROUP,3000,1033" -Wait
                Start-Process "C:\Program Files (x86)\Resource Hacker\ResourceHacker.exe" "-open `"$($script:PSScriptRoot)\Multi Game Installer\Steam Cloud Installer.exe`" -save `"$($script:PSScriptRoot)\Multi Game Installer\Steam Cloud Installer.exe`" -action addoverwrite -res `"$($script:PSScriptRoot)\Multi Game Installer\VersionInfo.res`" -mask VERSIONINFO,1,1033" -Wait
                del ".\Multi Game Installer\*.res" -Force
                exit
            }
        }

        if ($selection -eq 3) {
            if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $false) {
                $i=1
                foreach ($game in $Config.games) {
                    echo "[$i] $($game.name)"
                    ++$i
                }
                echo "[$i] All games"
                $selection = read-host "What game would you like to build executables for"
                if ($selection -eq $i) {
                    $i=$i*4-4
                    $i=$i/3
                    $i=$i+4
                    if ($i -lt 5) {
                        $i = 5
                    }
                    if ($i -gt 60) {
                        $timeunit = "minutes"
                        $i=$i/60
                    } else {
                        $timeunit = "seconds"
                    }
                    $selection = read-host "Building all games will take approximately $i $timeunit, would you like to build all games? [Y/n]"
                    if ($selection -eq "n" -or $selection -eq "N" -or $selection -eq "no") {
                        echo "Canceled"
                        timeout -1
                        break
                    } else {
                        foreach ($game in $config.games) {
                            if (!(test-path "$($game.installer)Built Executables\SteamCloudSync.exe")) {
                                echo "Steam Cloud Sync executables for $($game.name) not found, please build it first using option 4"
                                echo "Press any key to exit"
                                timeout -1 | out-null
                                exit
                            }
                        }
                        $versionString = read-host "What is the desired version number for the exe, you can have up to 4 numbers separated by periods"
                        $version = $versionString.Split(".")
                        if ($version.count -gt 4) {
                            echo "Invalid version number"
                            timeout -1
                            break
                        }
                        $i=0
                        while ($i -lt 4) {
                            if ($version[$i] -eq $null) {
                                $versionNumber = [System.Collections.ArrayList]($version)
                                $versionNumber.Add(0) | out-null
                                $version = $versionNumber.ToArray()
                            }
                            if ($version[$i] -lt 0 -or $version[$i] -gt 65535) {
                                $version[$i] = 0
                            }
                            ++$i
                        }
                        foreach ($game in $config.games) {
                            $rc = Get-Content "$($game.installer)Resources\Offline.rc"
                            $rc.Split([Environment]::NewLine) | Out-Null
                            $rc[2] = "FILEVERSION $($version[0]),$($version[1]),$($version[2]),$($version[3])"
                            $rc[3] = "PRODUCTVERSION $($version[0]),$($version[1]),$($version[2]),$($version[3])"
                            $rc[13] = "		VALUE `"FileVersion`", `"$versionString`""
                            $rc[18] = "		VALUE `"ProductVersion`", `"$versionString`""
                            $rc | Set-Content "$($game.installer)Resources\Offline.rc"
                        }
                        try {
                            Start-Process pwsh -Verb runAs -ArgumentList "`"$($MyInvocation.MyCommand.Path)`" 103"
                        }
                        catch {
                            echo "You need to accept the admin prompt"
                            timeout -1
                            break
                        }
                        break
                    }
                }
                $selection = [int]$selection
                $path = $Config.games[$selection-1].installer
                if ($path -eq $null) {
                    echo "Invalid game"
                    timeout -1
                    break
                }
                if (!(test-path "$($path)Built Executables\SteamCloudSync.exe")) {
                    echo "Steam Cloud Sync executables not found, please build it first using option 4"
                    timeout -1
                    break
                }
                $versionString = read-host "What is the desired version number for the exe, you can have up to 4 numbers separated by periods"
                $version = $versionString.Split(".")
                if ($version.count -gt 4) {
                    echo "Invalid version number"
                    timeout -1
                    break
                }
                $i=0
                while ($i -lt 4) {
                    if ($version[$i] -eq $null) {
                        $versionNumber = [System.Collections.ArrayList]($version)
                        $versionNumber.Add(0) | out-null
                        $version = $versionNumber.ToArray()
                    }
                    if ($version[$i] -lt 0 -or $version[$i] -gt 65535) {
                        $version[$i] = 0
                    }
                    ++$i
                }
                $rc = Get-Content "$($path)Resources\Offline.rc"
                $rc.Split([Environment]::NewLine) | Out-Null
                $rc[2] = "FILEVERSION $($version[0]),$($version[1]),$($version[2]),$($version[3])"
                $rc[3] = "PRODUCTVERSION $($version[0]),$($version[1]),$($version[2]),$($version[3])"
                $rc[13] = "		VALUE `"FileVersion`", `"$versionString`""
                $rc[18] = "		VALUE `"ProductVersion`", `"$versionString`""
                $rc | Set-Content "$($path)Resources\Offline.rc"
                echo "Building..."
                try {
                    Start-Process pwsh -Verb runAs -WindowStyle Hidden -Wait -ArgumentList "`"$($MyInvocation.MyCommand.Path)`" 3 `"$($path.trimend("\"))`""
                }
                catch {
                    echo "You need to accept the admin prompt"
                    timeout -1
                    break
                }
                echo "Build completed"
                timeout -1
            }
            if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $true) {
                $path = $2
                $path = $path.TrimStart(".\")
                foreach ($game in $config.games) {
                    if ($game.installer -eq ".\$path\") {
                        $gameName = $game.name
                    }
                }
                $s = Get-Content ".\$path\OfflineInstaller.ps1"
                $s.Split([Environment]::NewLine) | Out-Null
                if (test-path ".\$($s[0].TrimStart("# "))\OfflineInstaller.ps1") {
                    $template = get-content ".\$($s[0].TrimStart("# "))\OfflineInstaller.ps1"
                    $newfile = New-Object System.Collections.ArrayList
                    $i=0
                    while ($s[$i].TrimEnd("-") -ne "# Game specific end") {
                        $newfile.Add($s[$i]) | Out-Null
                        ++$i
                    }
                    $i=0
                    while ($template[$i].TrimEnd("-") -ne "# Game specific end") {
                        ++$i
                    }
                    while ($i -lt $template.count) {
                        $newfile.Add($template[$i]) | Out-Null
                        ++$i
                    }
                    Rename-Item ".\$path\OfflineInstaller.ps1" "OfflineInstaller.ps1.bak"
                    $newfile | Set-Content ".\$path\OfflineInstaller.ps1"
                }
                $sed = Get-Content ".\$path\SEDs\OfflineInstaller.sed"
                $sed.Split([Environment]::NewLine)
                $sed[26] = "TargetName=$(Get-Location)\$path\Built Executables\Steam Cloud Installer for $gameName.exe"
                $sed[36] = "SourceFiles0=$(Get-Location)\$path\"
                $sed[37] = "SourceFiles1=$(Get-Location)\$path\Built Executables\"
                mkdir "C:\$($pid)\"
                $sed | Set-Content "C:\$($pid)\OfflineInstaller.sed"
                Start-Process "iexpress.exe" "/Q /N C:\$($pid)\OfflineInstaller.sed"  -Wait
                "funnyword" | Set-Content ".\done"
                del "C:\$($pid)\OfflineInstaller.sed"
                rmdir "C:\$($pid)\" -Force
                if (test-path ".\$path\OfflineInstaller.ps1.bak") {
                    del ".\$path\OfflineInstaller.ps1"
                    Rename-Item ".\$path\OfflineInstaller.ps1.bak" "OfflineInstaller.ps1"
                }
                Start-Process "C:\Program Files (x86)\Resource Hacker\ResourceHacker.exe" "-open `"$($script:PSScriptRoot)\$path\Resources\Offline.rc`" -save `"$($script:PSScriptRoot)\$path\Resources\Offline.res`" -action compile"  -Wait
                Start-Process "C:\Program Files (x86)\Resource Hacker\ResourceHacker.exe" "-open `"$($script:PSScriptRoot)\$path\Built Executables\Steam Cloud Installer for $gameName.exe`" -save `"$($script:PSScriptRoot)\$path\Built Executables\Steam Cloud Installer for $gameName.exe`" -action addoverwrite -res `"$($script:PSScriptRoot)\$path\Resources\Offline.res`" -mask VERSIONINFO,1,1033"  -Wait
                Start-Process "C:\Program Files (x86)\Resource Hacker\ResourceHacker.exe" "-open `"$($script:PSScriptRoot)\$path\Built Executables\Steam Cloud Installer for $gameName.exe`" -save `"$($script:PSScriptRoot)\$path\Built Executables\Steam Cloud Installer for $gameName.exe`" -action addoverwrite -res `"$($script:PSScriptRoot)\$path\Resources\Icon.ico`" -mask ICONGROUP,3000,1033"  -Wait
                del ".\$path\Resources\*.res" -Force
                exit
            }
        }
        if ($selection -eq 4) {
            if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $false) {
                $i=1
                foreach ($game in $Config.games) {
                    echo "[$i] $($game.name)"
                    ++$i
                }
                echo "[$i] All games"
                $selection = read-host "What game would you like to build executables for"
                if ($selection -eq $i) {
                    $i=$i*9-9
                    $i=$i/3
                    $i=$i+6
                    if ($i -lt 9) {
                        $i = 9
                    }
                    if ($i -gt 60) {
                        $timeunit = "minutes"
                        $i=$i/60
                    } else {
                        $timeunit = "seconds"
                    }
                    $selection = read-host "Building all games will take approximately $i $timeunit, would you like to build all games? [Y/n]"
                    if ($selection -eq "n" -or $selection -eq "N" -or $selection -eq "no") {
                        echo "Canceled"
                        timeout -1
                        break
                    } else {
                        mkdir "$($path)Built Executables" -Force | out-null
                        $versionString = read-host "What is the desired version number for the runtime exe, you can have up to 4 numbers separated by periods"
                        $version = $versionString.Split(".")
                        if ($version.count -gt 4) {
                            echo "Invalid version number"
                            timeout -1
                            break
                        }
                        $i=0
                        while ($i -lt 4) {
                            if ($version[$i] -eq $null) {
                                $versionNumber = [System.Collections.ArrayList]($version)
                                $versionNumber.Add(0) | out-null
                                $version = $versionNumber.ToArray()
                            }
                            if ($version[$i] -lt 0 -or $version[$i] -gt 65535) {
                                $version[$i] = 0
                            }
                            ++$i
                        }
                        foreach ($game in $config.games) {
                            $rc = Get-Content "$($game.installer)Resources\CloudSync.rc"
                            $rc.Split([Environment]::NewLine) | Out-Null
                            $rc[2] = "FILEVERSION $($version[0]),$($version[1]),$($version[2]),$($version[3])"
                            $rc[3] = "PRODUCTVERSION $($version[0]),$($version[1]),$($version[2]),$($version[3])"
                            $rc[13] = "		VALUE `"FileVersion`", `"$versionString`""
                            $rc[18] = "		VALUE `"ProductVersion`", `"$versionString`""
                            $rc | Set-Content "$($game.installer)Resources\CloudSync.rc"
                        }
                        $versionString = read-host "What is the desired version number for the background exe, you can have up to 4 numbers separated by periods"
                        $version = $versionString.Split(".")
                        if ($version.count -gt 4) {
                            echo "Invalid version number"
                            timeout -1
                            break
                        }
                        $i=0
                        while ($i -lt 4) {
                            if ($version[$i] -eq $null) {
                                $versionNumber = [System.Collections.ArrayList]($version)
                                $versionNumber.Add(0) | out-null
                                $version = $versionNumber.ToArray()
                            }
                            if ($version[$i] -lt 0 -or $version[$i] -gt 65535) {
                                $version[$i] = 0
                            }
                            ++$i
                        }
                        foreach ($game in $config.games) {
                            $rc = Get-Content "$($game.installer)Resources\Background.rc"
                            $rc.Split([Environment]::NewLine) | Out-Null
                            $rc[2] = "FILEVERSION $($version[0]),$($version[1]),$($version[2]),$($version[3])"
                            $rc[3] = "PRODUCTVERSION $($version[0]),$($version[1]),$($version[2]),$($version[3])"
                            $rc[13] = "		VALUE `"FileVersion`", `"$versionString`""
                            $rc[18] = "		VALUE `"ProductVersion`", `"$versionString`""
                            $rc | Set-Content "$($game.installer)Resources\Background.rc"
                        }
                        try {
                            Start-Process pwsh -Verb runAs -ArgumentList "`"$($MyInvocation.MyCommand.Path)`" 104"
                        }
                        catch {
                            echo "You need to accept the admin prompt"
                            timeout -1
                            break
                        }
                        break
                    }
                }
                $selection = [int]$selection
                $path = $Config.games[$selection-1].installer
                if ($path -eq $null) {
                    echo "Invalid game"
                    timeout -1
                    break
                }
                mkdir "$($path)Built Executables" -Force | out-null
                $versionString = read-host "What is the desired version number for the runtime exe, you can have up to 4 numbers separated by periods"
                $version = $versionString.Split(".")
                if ($version.count -gt 4) {
                    echo "Invalid version number"
                    timeout -1
                    break
                }
                $i=0
                while ($i -lt 4) {
                    if ($version[$i] -eq $null) {
                        $versionNumber = [System.Collections.ArrayList]($version)
                        $versionNumber.Add(0) | out-null
                        $version = $versionNumber.ToArray()
                    }
                    if ($version[$i] -lt 0 -or $version[$i] -gt 65535) {
                        $version[$i] = 0
                    }
                    ++$i
                }
                $rc = Get-Content "$($path)Resources\CloudSync.rc"
                $rc.Split([Environment]::NewLine) | Out-Null
                $rc[2] = "FILEVERSION $($version[0]),$($version[1]),$($version[2]),$($version[3])"
                $rc[3] = "PRODUCTVERSION $($version[0]),$($version[1]),$($version[2]),$($version[3])"
                $rc[13] = "		VALUE `"FileVersion`", `"$versionString`""
                $rc[18] = "		VALUE `"ProductVersion`", `"$versionString`""
                $rc | Set-Content "$($path)Resources\CloudSync.rc"

                $versionString = read-host "What is the desired version number for the background exe, you can have up to 4 numbers separated by periods"
                $version = $versionString.Split(".")
                if ($version.count -gt 4) {
                    echo "Invalid version number"
                    timeout -1
                    break
                }
                $i=0
                while ($i -lt 4) {
                    if ($version[$i] -eq $null) {
                        $versionNumber = [System.Collections.ArrayList]($version)
                        $versionNumber.Add(0) | out-null
                        $version = $versionNumber.ToArray()
                    }
                    if ($version[$i] -lt 0 -or $version[$i] -gt 65535) {
                        $version[$i] = 0
                    }
                    ++$i
                }
                $rc = Get-Content "$($path)Resources\Background.rc"
                $rc.Split([Environment]::NewLine) | Out-Null
                $rc[2] = "FILEVERSION $($version[0]),$($version[1]),$($version[2]),$($version[3])"
                $rc[3] = "PRODUCTVERSION $($version[0]),$($version[1]),$($version[2]),$($version[3])"
                $rc[13] = "		VALUE `"FileVersion`", `"$versionString`""
                $rc[18] = "		VALUE `"ProductVersion`", `"$versionString`""
                $rc | Set-Content "$($path)Resources\Background.rc"
                echo "Building..."
                try {
                    Start-Process pwsh -Verb runAs -WindowStyle Hidden -Wait -ArgumentList "`"$($MyInvocation.MyCommand.Path)`" 4 `"$($path.trimend("\"))`""
                }
                catch {
                    echo "You need to accept the admin prompt"
                    timeout -1
                    break
                }
                echo "Build completed"
                timeout -1
            }
            if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $true) {
                $path = $2
                $path = $path.TrimStart(".\")
                $s = Get-Content ".\$path\SteamCloudSync.ps1"
                $s.Split([Environment]::NewLine) | Out-Null
                if (test-path ".\$($s[0].TrimStart("# "))\SteamCloudSync.ps1") {
                    $template = get-content ".\$($s[0].TrimStart("# "))\SteamCloudSync.ps1"
                    $newfile = New-Object System.Collections.ArrayList
                    $i=0
                    while ($s[$i].TrimEnd("-") -ne "# Game specific end") {
                        $newfile.Add($s[$i]) | Out-Null
                        ++$i
                    }
                    $i=0
                    while ($template[$i].TrimEnd("-") -ne "# Game specific end") {
                        ++$i
                    }
                    while ($i -lt $template.count) {
                        $newfile.Add($template[$i]) | Out-Null
                        ++$i
                    }
                    Rename-Item ".\$path\SteamCloudSync.ps1" "SteamCloudSync.ps1.bak"
                    $newfile | Set-Content ".\$path\SteamCloudSync.ps1"
                }
                $sed = Get-Content ".\$path\SEDs\SteamCloudSync.sed"
                $sed.Split([Environment]::NewLine)
                $sed[26] = "TargetName=$(Get-Location)\$path\Built Executables\SteamCloudSync.exe"
                $sed[34] = "SourceFiles0=$(Get-Location)\$path\"
                mkdir "C:\$($pid)\"
                $sed | Set-Content "C:\$($pid)\SteamCloudSync.sed"
                Start-Process "iexpress.exe" "/Q /N C:\$($pid)\SteamCloudSync.sed" -Wait
                del "C:\$($pid)\SteamCloudSync.sed"
                rmdir "C:\$($pid)\" -Force
                if (test-path ".\$path\SteamCloudSync.ps1.bak") {
                    del ".\$path\SteamCloudSync.ps1"
                    Rename-Item ".\$path\SteamCloudSync.ps1.bak" "SteamCloudSync.ps1"
                }
                $s = Get-Content ".\$path\Background.ps1"
                $s.Split([Environment]::NewLine) | Out-Null
                if (test-path ".\$($s[0].TrimStart("# "))\Background.ps1") {
                    $template = get-content ".\$($s[0].TrimStart("# "))\Background.ps1"
                    $newfile = New-Object System.Collections.ArrayList
                    $i=0
                    while ($s[$i].TrimEnd("-") -ne "# Game specific end") {
                        $newfile.Add($s[$i]) | Out-Null
                        ++$i
                    }
                    $i=0
                    while ($template[$i].TrimEnd("-") -ne "# Game specific end") {
                        ++$i
                    }
                    while ($i -lt $template.count) {
                        $newfile.Add($template[$i]) | Out-Null
                        ++$i
                    }
                    Rename-Item ".\$path\Background.ps1" "Background.ps1.bak"
                    $newfile | Set-Content ".\$path\Background.ps1"
                }
                $sed = Get-Content ".\$path\SEDs\Background.sed"
                $sed.Split([Environment]::NewLine)
                $sed[26] = "TargetName=$(Get-Location)\$path\Built Executables\SteamCloudBackground.exe"
                $sed[34] = "SourceFiles0=$(Get-Location)\$path\"
                mkdir "C:\$($pid)\"
                $sed | Set-Content "C:\$($pid)\Background.sed"
                Start-Process "iexpress.exe" "/Q /N C:\$($pid)\Background.sed" -Wait
                "funnyword" | Set-Content ".\done"
                del "C:\$($pid)\Background.sed"
                rmdir "C:\$($pid)\" -Force
                if (test-path ".\$path\Background.ps1.bak") {
                    del ".\$path\Background.ps1"
                    Rename-Item ".\$path\Background.ps1.bak" "Background.ps1"
                }
                Start-Process "C:\Program Files (x86)\Resource Hacker\ResourceHacker.exe" "-open `"$($script:PSScriptRoot)\$path\Resources\CloudSync.rc`" -save `"$($script:PSScriptRoot)\$path\Resources\CloudSync.res`" -action compile" -Wait
                Start-Process "C:\Program Files (x86)\Resource Hacker\ResourceHacker.exe" "-open `"$($script:PSScriptRoot)\$path\Built Executables\SteamCloudSync.exe`" -save `"$($script:PSScriptRoot)\$path\Built Executables\SteamCloudSync.exe`" -action addoverwrite -res `"$($script:PSScriptRoot)\$path\Resources\CloudSync.res`" -mask VERSIONINFO,1,1033" -Wait
                Start-Process "C:\Program Files (x86)\Resource Hacker\ResourceHacker.exe" "-open `"$($script:PSScriptRoot)\$path\Built Executables\SteamCloudSync.exe`" -save `"$($script:PSScriptRoot)\$path\Built Executables\SteamCloudSync.exe`" -action addoverwrite -res `"$($script:PSScriptRoot)\$path\Resources\Icon.ico`" -mask ICONGROUP,3000,1033" -Wait
                Start-Process "C:\Program Files (x86)\Resource Hacker\ResourceHacker.exe" "-open `"$($script:PSScriptRoot)\$path\Resources\Background.rc`" -save `"$($script:PSScriptRoot)\$path\Resources\Background.res`" -action compile"  -Wait
                Start-Process "C:\Program Files (x86)\Resource Hacker\ResourceHacker.exe" "-open `"$($script:PSScriptRoot)\$path\Built Executables\SteamCloudBackground.exe`" -save `"$($script:PSScriptRoot)\$path\Built Executables\SteamCloudBackground.exe`" -action addoverwrite -res `"$($script:PSScriptRoot)\$path\Resources\Background.res`" -mask VERSIONINFO,1,1033"  -Wait
                Start-Process "C:\Program Files (x86)\Resource Hacker\ResourceHacker.exe" "-open `"$($script:PSScriptRoot)\$path\Built Executables\SteamCloudBackground.exe`" -save `"$($script:PSScriptRoot)\$path\Built Executables\SteamCloudBackground.exe`" -action addoverwrite -res `"$($script:PSScriptRoot)\$path\Resources\Icon.ico`" -mask ICONGROUP,3000,1033"  -Wait
                del ".\$path\Resources\*.res" -Force
                exit
            }
        }
        if ($selection -eq 103) {
            foreach ($game in $config.games) {
                echo "Building $($game.name)..."
                try {
                    if (!($game -eq $config.games[$config.games.count-1])) {
                        Start-Process pwsh -WindowStyle Hidden -ArgumentList "`"$($MyInvocation.MyCommand.Path)`" 3 `"$($game.installer.trimend("\"))`""
                        while (!(test-path ".\done")) {
                            timeout 1 /nobreak | Out-Null
                        }
                        del ".\done"
                    } else {
                        Start-Process pwsh -WindowStyle Hidden -Wait -ArgumentList "`"$($MyInvocation.MyCommand.Path)`" 3 `"$($game.installer.trimend("\"))`""
                        del ".\done"
                    }
                }
                catch {
                    echo "An error occurred, please try again"
                    echo "Press any key to exit"
                    timeout -1 | out-null
                    exit
                }
                ++$i
            }
            echo "Build completed"
            echo "Press any key to exit"
            timeout -1 | out-null
            exit
        }
        if ($selection -eq 104) {
            foreach ($game in $config.games) {
                echo "Building $($game.name)..."
                try {
                    if (!($game -eq $config.games[$config.games.count-1])) {
                        Start-Process pwsh -WindowStyle Hidden -ArgumentList "`"$($MyInvocation.MyCommand.Path)`" 4 `"$($game.installer.trimend("\"))`""
                        while (!(test-path ".\done")) {
                            timeout 1 /nobreak | Out-Null
                        }
                        del ".\done"
                    } else {
                        Start-Process pwsh -WindowStyle Hidden -Wait -ArgumentList "`"$($MyInvocation.MyCommand.Path)`" 4 `"$($game.installer.trimend("\"))`""
                        del ".\done"
                    }
                }
                catch {
                    echo "An error occurred, please try again"
                    echo "Press any key to exit"
                    timeout -1 | out-null
                    exit
                }
                ++$i
            }
            echo "Build completed"
            echo "Press any key to exit"
            timeout -1 | out-null
            exit
        }

        if ($selection -eq 5) {
            $gameName = read-host "What is the name of the game"
            echo "Searching..."
            $appdata = Get-ChildItem "$env:appdata\..\" -Depth 2 -Include "*$gameName*" -ErrorAction SilentlyContinue
            $documents = Get-ChildItem "C:\Users\$env:username\Documents\" -Depth 1 -Include "*$gameName*" -ErrorAction SilentlyContinue
            $savedGames = Get-ChildItem "C:\Users\$env:username\Saved Games\" -Depth 1 -Include "*$gameName*" -ErrorAction SilentlyContinue
            $reg = Get-ChildItem "HKCU:\SOFTWARE\" -Depth 1 -Include "*$gameName*" -ErrorAction SilentlyContinue
            if ($appdata -ne $null -or $documents -ne $null -or $savedGames -ne $null) {
                cls
                echo "Possable locations include:"
                foreach ($h in $appdata) {
                    echo "$h"
                }
                foreach ($h in $documents) {
                    echo "$h"
                }
                foreach ($h in $savedGames) {
                    echo "$h"
                }
                if ($reg -ne $null) {
                    echo "Possable Windows Registry locations:"
                    foreach ($h in $reg) {
                        echo "REG$($h.hive)\$($h.name)"
                    }
                }
                echo "If you do not find save data in any of those locations it might be in the steam userdata folder"
            } else {
                echo "No results found, expanding search..."
                $gamearray = $gameName -split ' '
                $appdata = Get-ChildItem "$env:appdata\..\" -Depth 2 -Include ($gamearray | ForEach-Object { "*$_*" }) -ErrorAction SilentlyContinue
                $documents = Get-ChildItem "C:\Users\$env:username\Documents\" -Depth 1 -Include ($gamearray | ForEach-Object { "*$_*" }) -ErrorAction SilentlyContinue
                $savedGames = Get-ChildItem "C:\Users\$env:username\Saved Games\" -Depth 1 -Include ($gamearray | ForEach-Object { "*$_*" }) -ErrorAction SilentlyContinue
                $reg = Get-ChildItem "HKCU:\SOFTWARE\" -Depth 1 -Include ($gamearray | ForEach-Object { "*$_*" }) -ErrorAction SilentlyContinue
            if ($appdata -ne $null -or $documents -ne $null -or $savedGames -ne $null) {
                    cls
                    echo "Expanded search was used, not all possable location are revelent"
                    echo "Possable location include:"
                    foreach ($h in $appdata) {
                        echo "$h"
                    }
                    foreach ($h in $documents) {
                        echo "$h"
                    }
                    foreach ($h in $savedGames) {
                        echo $h
                    }
                    if ($reg -ne $null) {
                        echo "Possable Windows Registry locations:"
                        foreach ($h in $reg) {
                            echo "REG$($h.hive)\$($h.name)"
                        }
                    }
                    echo "If you do not find save data in any of those locations it might be in the steam userdata folder"
                } else {
                    echo "No results found. Please note that this tool only searches common save location." 
                    echo "some other possable save location include the steam userdata folder"
                }
            }
            echo "[steam install path]\userdata\[steam app id]"
            echo "Or it might be in the game install"
            echo "[steam install path]\steamapps\common\$gameName"
            echo "If you still can not find it look up `"Where is save data for $gameName on Google`""
            timeout -1
        }

        if ($selection -eq 6) {
            $gamesList = [System.Collections.ArrayList]($config.games)
            $files = get-childitem -path ".\" -Depth 1 -include "*.json" -Exclude "BuildTool.json", "Settings.json", "GameList.json"
            $i=1
            foreach ($file in $files) {
                echo "[$i] $($file.basename)"
                ++$i
            }
            $selection = read-host "What game would you like to add"
            $selection = $selection-1
            $path = $files[$selection].basename
            $Background = get-content "$path\Background.ps1"
            $Background.Split([Environment]::NewLine) | Out-Null
            $gameInfo = [System.Collections.ArrayList]@()
            $gameInfo.add($Background[2].trimstart("`$gameName = `"").trimend("`" # name of the game")) | Out-Null
            $gameInfo.add($Background[3].trimstart("`$steamAppID = `"").trimend("`" # you can find this on https://steamdb.info, it should be structured like this, `"NUMBER`"")) | Out-Null
            $gameInfo.add(".\$($gameInfo[0])\") | Out-Null
            echo "Is the following information correct?"
            echo "Game name: $($gameInfo[0])"
            echo "Steam App ID: $($gameInfo[1])"
            echo "Folder Location $($gameInfo[2])"
            $selection = read-host "[Y/n]"
            if ($selection -eq "n" -or $selection -eq "N" -or $selection -eq "no") {
                $gameInfo[0] = read-host "What is the name of the game"
                $gameInfo[1] = read-host "What is the steam app id"
                $gameInfo[2] = read-host "What is the folder location"
            }
            $gamesList.Add([PSCustomObject]@{"name"=$gameInfo[0];"steamID"=$gameInfo[1];"installer"=$gameInfo[2]})
            $config.games = $gamesList.ToArray()
            $Config | ConvertTo-Json -depth 32 | Format-Json | Set-Content .\BuildTool.json
        }

        if ($selection -eq 7) {
            $i=1
            foreach ($game in $Config.games) {
                echo "[$i] $($game.name)"
                ++$i
            }
            $selection = read-host "What game would you like to sync game specific information for"
            if ($config.games[$selection-1].installer -eq $null) {
                echo "Invalid game"
                timeout -1
                break
            }
            $path = $config.games[$selection-1].installer
            $filledIn = get-content "$($path)Background.ps1"
            $toFillIn = get-content "$($path)OfflineInstaller.ps1"
            $newfile = New-Object System.Collections.ArrayList
            $i=0
            while ($toFillIn[$i].TrimEnd("-") -ne "# Game specific end") {
                $newfile.Add($filledIn[$i]) | Out-Null
                ++$i
            }
            $i=0
            while ($toFillIn[$i].TrimEnd("-") -ne "# Game specific end") {
                ++$i
            }
            while ($i -lt $toFillIn.count) {
                $newfile.Add($toFillIn[$i]) | Out-Null
                ++$i
            }
            $newfile | Set-Content "$($path)OfflineInstaller.ps1"
            $toFillIn = get-content "$($path)OnlineInstaller.ps1"
            $newfile = New-Object System.Collections.ArrayList
            $i=0
            while ($toFillIn[$i].TrimEnd("-") -ne "# Game specific end") {
                $newfile.Add($filledIn[$i]) | Out-Null
                ++$i
            }
            $i=0
            while ($toFillIn[$i].TrimEnd("-") -ne "# Game specific end") {
                ++$i
            }
            while ($i -lt $toFillIn.count) {
                $newfile.Add($toFillIn[$i]) | Out-Null
                ++$i
            }
            $newfile | Set-Content "$($path)OnlineInstaller.ps1"
            $toFillIn = get-content "$($path)SteamCloudSync.ps1"
            $newfile = New-Object System.Collections.ArrayList
            $i=0
            while ($toFillIn[$i].TrimEnd("-") -ne "# Game specific end") {
                $newfile.Add($filledIn[$i]) | Out-Null
                ++$i
            }
            $i=0
            while ($toFillIn[$i].TrimEnd("-") -ne "# Game specific end") {
                ++$i
            }
            while ($i -lt $toFillIn.count) {
                $newfile.Add($toFillIn[$i]) | Out-Null
                ++$i
            }
            $newfile | Set-Content "$($path)SteamCloudSync.ps1"
            echo "All files for $($config.games[$selection-1].name) have had their game specific information synced"
            timeout -1
        }

        if ($(test-path "c:/program files (x86)/resource hacker/") -and $selection -eq 8) {
            winget uninstall AngusJohnson.ResourceHacker --silent
            timeout 3 /nobreak | Out-Null
            if (Test-Path "c:/program files (x86)/resource hacker/") {
                echo "Failed to uninstall Resource Hacker, you can uninstall manually from the add or remove programs menu in settings"
                timeout -1
            } else {
                timeout -1
            }
        }
        $Config | ConvertTo-Json -depth 32 | Format-Json | Set-Content .\BuildTool.json
        $Config = Get-Content .\BuildTool.json | ConvertFrom-Json
        del ".\done" -erroraction SilentlyContinue
        cls
    }
    cls
}
