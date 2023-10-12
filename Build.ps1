param (
    [string]$1
)
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
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $false) {
        echo "[1] Build database"
        echo "[2] Build multi game installer"
        echo "[3] Build single game installer"
        echo "[4] Build Steam Cloud runtime and background executables"
        if (test-path "c:/program files (x86)/resource hacker/") {
            echo "[5] Uninstall Resource Hacker"
        }
        $selection = Read-Host "What would you like to do"
    } else {
        $selection = [int]$1
    }
    if ($selection -eq 1) {
        foreach ($games in $config.games) {
            $s = Get-Content ".\$($games.name)\OnlineInstaller.ps1" | Out-String
            $j = [PSCustomObject]@{
              "Script" =  [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($s))
            }
            $games.installer = $j
        }
        $Config | ConvertTo-Json -depth 32 | Format-Json | Set-Content ".\Multi Game Installer\GameList.json"
        $Config = Get-Content .\BuildTool.json | ConvertFrom-Json
    }

    if ($selection -eq 2 -or $selection -eq 3 -or $selection -eq 4 -and !(test-path "C:\Program Files (x86)\Resource Hacker\")) {
        echo "Resource Hacker is not installed, it is required to build executables."
        $choice = read-host "Would you like to install Resource Hacker [Y/n]"
        if ($choice -ne "n" -and $choice -ne "N" -and $choice -ne "no") {
            echo "Installing..."
            winget install AngusJohnson.ResourceHacker --source winget --force --silent
            if (!(test-path "C:\Program Files (x86)\Resource Hacker\")) {
                echo "Failed to install Resource Hacker, please check your internet connection and try again, or install manually from https://www.angusj.com/resourcehacker/"
                echo "Press any key to exit"
                timeout -1 | Out-Null
                exit
            }
        } else {
            echo "Resource Hacker is required to build executables, please install before continuing"
            echo "Press any key to exit"
            timeout -1 | Out-Null
            exit
        }
    }

    if ($selection -eq 2) {
        if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $false) {
            $versionString = read-host "What is the desired version number, you can have up to 4 numbers seperated by periods"
            $version = $versionString.Split(".")
            if ($version.count -gt 4) {
                echo "Invalid version number"
                echo "Press any key to exit"
                timeout -1
                exit
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
            $rc[12] = "        VALUE `"FileVersion`", `"$versionString`""
            $rc[17] = "        VALUE `"ProductVersion`", `"$versionString`""
            $rc | Set-Content ".\Multi Game Installer\VersionInfo.rc"
            try {
                Start-Process powershell.exe -Verb runAs -ArgumentList "`"$($MyInvocation.MyCommand.Path)`" 2"
            }
            catch {
                echo "You need to accept the admin prompt"
                timeout -1
            }
        }
        if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $true) {
            echo "Building..."
            $sed = Get-Content ".\Multi Game Installer\SteamCloudInstaller.sed"
            $sed.Split([Environment]::NewLine)
            $sed[26] = "TargetName=$(Get-Location)\Multi Game Installer\Steam Cloud Installer.exe"
            $sed[34] = "SourceFiles0=$(Get-Location)\Multi Game Installer"
            $sed | Set-Content "C:\SteamCloudInstaller.sed"
            Start-Process "iexpress.exe" "/Q /N C:\SteamCloudInstaller.sed"
            while ($(Get-Process "iexpress" -erroraction SilentlyContinue) -ne $null) {
                timeout 1 | out-null
            }
            del "C:\SteamCloudInstaller.sed"
            Start-Process "C:\Program Files (x86)\Resource Hacker\ResourceHacker.exe" "-open `"$($script:PSScriptRoot)\Multi Game Installer\VersionInfo.rc`" -save `"$($script:PSScriptRoot)\Multi Game Installer\VersionInfo.res`" -action compile"
            while ($(Get-Process "ResourceHacker" -erroraction SilentlyContinue) -ne $null) {
                timeout 1 | out-null
            }
            Start-Process "C:\Program Files (x86)\Resource Hacker\ResourceHacker.exe" "-open `"$($script:PSScriptRoot)\Multi Game Installer\Steam Cloud Installer.exe`" -save `"$($script:PSScriptRoot)\Multi Game Installer\Steam Cloud Installer.exe`" -action addoverwrite -res `"$($script:PSScriptRoot)\Multi Game Installer\Icon.ico`" -mask ICONGROUP,3000,1033"
            while ($(Get-Process "ResourceHacker" -erroraction SilentlyContinue) -ne $null) {
                timeout 1 | out-null
            }
            Start-Process "C:\Program Files (x86)\Resource Hacker\ResourceHacker.exe" "-open `"$($script:PSScriptRoot)\Multi Game Installer\Steam Cloud Installer.exe`" -save `"$($script:PSScriptRoot)\Multi Game Installer\Steam Cloud Installer.exe`" -action addoverwrite -res `"$($script:PSScriptRoot)\Multi Game Installer\VersionInfo.res`" -mask VERSIONINFO,1,1033"
            while ($(Get-Process "ResourceHacker" -erroraction SilentlyContinue) -ne $null) {
                timeout 1 | out-null
            }
            exit
        }
    }

    if ($selection -eq 3) {
        if (test-path "$env:appdata\GTTODLevelLoader\database.json") {
            del "$env:appdata\GTTODLevelLoader\database.json"
            echo "Local database disabled, to re-enable simply build the database again"
        } else {
            echo "You don't have a local databse to delete"
        }
        timeout -1
    }

    if ($selection -eq 4) {
        $sed = Get-Content .\GTTODLevelLoader.SED
        $sed.Split([Environment]::NewLine)
        $sed[36] = "TargetName=$(Get-Location)\GTTOD Save Editor.exe"
        $sed[44] = "SourceFiles0=$(Get-Location)\"
        $sed | Set-Content .\GTTODLevelLoader.SED
        $h=Get-Location
        cls
        try {
            Start-Process "iexpress.exe" "/Q /N $($h.Path)\GTTODLevelLoader.sed" -Verb runAs
        } catch {
            echo "You need to accept the admin prompt"
            timeout -1
        }
    }
    if ($selection -eq 9) {
        $sed = Get-Content ".\SteamCloud\SteamCloudSync.sed"
        $sed.Split([Environment]::NewLine)
        $sed[36] = "TargetName=$(Get-Location)\SteamCloud\SteamCloudSync.exe"
        $sed[44] = "SourceFiles0=$(Get-Location)\SteamCloud"
        $sed | Set-Content ".\SteamCloud\SteamCloudSync.sed"
        $h=Get-Location
        cls
        try {
            Start-Process "iexpress.exe" "/Q /N $($h.Path)\SteamCloud\SteamCloudSync.sed" -Verb runAs
        } catch {
            echo "You need to accept the admin prompt"
            timeout -1
        }
        $sed = Get-Content ".\SteamCloud\Background.sed"
        $sed.Split([Environment]::NewLine)
        $sed[36] = "TargetName=$(Get-Location)\SteamCloud\GTTODSteamCloud.exe"
        $sed[45] = "SourceFiles0=$(Get-Location)\SteamCloud"
        $sed | Set-Content ".\SteamCloud\Background.sed"
        $h=Get-Location
        cls
        try {
            Start-Process "iexpress.exe" "/Q /N $($h.Path)\SteamCloud\Background.sed" -Verb runAs
        } catch {
            echo "You need to accept the admin prompt"
            timeout -1
        }
    }
    if ($(test-path "c:/program files (x86)/resource hacker/") -and $selection -eq 5) {
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
    cls
}