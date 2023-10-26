# .templates\generic
# Game specific start----------------------------------------------------------------------------------------------------------------------------
$gameName = "[INSERT GAME NAME]" # name of the game
$steamAppID = "[INSERT STEAM APP ID]" # you can find this on https://steamdb.info, it should be structured like this, "NUMBER"
$gameExecutableName = "[INSERT EXECUTABLE NAME]" # executable name should be structured, "GAME NAME.exe"
$gameFolderName = "[INSERT FOLDER NAME]" # install folder should be structured like this, "GAME FOLDER NAME" just give the folder name
$gameSaveFolder = "[INSERT SAVE LOCATION]" # the folder where saves are located, if the game does not store save files in a folder comment this out-
# -If the game does it should be structured like this "Full\Folder\Path". Make sure not to include user/computer specific information and use-
# -environment variables instead.
# If you do not know where save files are use option 5 in the build tool (open Build.ps1 and press the play button in the top right corner)
$gameSaveExtensions = "[INSERT SAVE FILE EXTENSIONS]" # the game save folder sometimes contains information other than just game saves, and some-
# -files should not be uploaded to Steam Cloud. If there is one extension format it like this ".[EXTENSION]". If there are more that one format it like this
# "[EXTENSION1]", "[EXTENSION2]", "[EXTENSION3]"
$gameRegistryEntries = "[INSERT REGISTRY LOCATION]" # the location where registry entries are located, if the game does not store save files in the registry-
# -comment this out by simply putting a "#" before the "$". If the game does it should be structured like this "HKCU\SOFTWARE\[COMPANY NAME]\[GAME NAME]"-
# -(this is where most games store entires).
# Game specific end------------------------------------------------------------------------------------------------------------------------------

$cloudName = "SteamCloudify for $gameName"
$databaseURL = "https://aldin101.github.io/SteamCloudify/$($gameName.Replace(' ', '%20'))/$($gameName.Replace(' ', '%20')).json"
$updateLink = "https://aldin101.github.io/SteamCloudify/$($gameName.Replace(' ', '%20'))/SteamCloudSync.exe"

$ProgressPreference = "SilentlyContinue"
$ErrorActionPreference = "SilentlyContinue"
$host.ui.RawUI.WindowTitle = "SteamCloudify Installer  |  Loading..."
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $false) {
    $fileLocation = Get-CimInstance Win32_Process -Filter "name = 'SteamCloudify Installer for $gameName.exe'" -ErrorAction SilentlyContinue
    if ($fileLocation -eq $null) {
        echo "Unable request admin, please manually run the program as administrator to continue"
        echo "Press any key to exit"
        timeout -1 |out-null
        exit
    }
    taskkill /f /im "SteamCloudify Installer for $gameName.exe" 2>$null | Out-Null
    $fileLocation1 = $fileLocation.CommandLine -replace '"', ""
    $clientVersion = $(Get-Item -Path "$fileLocation1").VersionInfo.FileVersion
    try {
        Start-Process "$filelocation1" -Verb RunAs
    } catch {
        echo "The SteamCloudify installer requires administrator privileges, please accept the admin prompt to continue"
        echo "Press any key to try again"
        timeout -1 | out-null
        try {
            Start-Process "$filelocation1" -Verb RunAs
        } catch {
            cls
            echo "The SteamCloudify installer cannot continue without administrator privileges"
            echo "Press any key to exit"
            timeout -1 | out-null
        }
    }
    exit
}

$fileLocation = Get-CimInstance Win32_Process -Filter "name = 'SteamCloudify Installer for $gameName.exe'" -ErrorAction SilentlyContinue
if ($fileLocation -eq $null) {
    $host.ui.RawUI.WindowTitle = "SteamCloudify Installer  |  Version: [ERROR]"
} else {
    $fileLocation1 = $fileLocation.CommandLine -replace '"', ""
    $clientVersion = $(Get-Item -Path "$fileLocation1").VersionInfo.FileVersion
    $host.ui.RawUI.WindowTitle = "SteamCloudify Installer  |  Version: $clientVersion"
}
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

echo "Welcome to SteamCloudify setup for $gameName"
timeout -1
cls
echo "Welcome to SteamCloudify setup for $gameName"
echo "Here is some important information:"
echo "Your saves will only be synced with other computers that have SteamCloudify installed"
echo "If Steam notices a save conflict it will tell you that your controller layouts are conflicting, this is actually your" "save data"
echo "If SteamCloudify notices a save conflict you will receive a message about it on launch."
echo "You can disable Steam Cloud for any game at any time by uninstalling SteamCloudify from the add or remove programs menu" "or using this installer"
echo "Steam Deck (and other non-windows devices) are unsupported at this time"
timeout -1
cls

$steamPath = (Get-ItemProperty -path 'HKCU:\SOFTWARE\Valve\Steam').steamPath
$ids = Get-ChildItem -Path "$steamPath\userdata\"
$steamid = [System.Collections.ArrayList](@())
foreach ($id in $ids) {
    if (test-path "$steamPath\userdata\$($id.basename)\inventorymsgcache\") {
        $steamid.add($id.basename) | Out-Null
    }
}

if ($steamid.count -eq 0) {
    echo "Unable to find your Steam ID"
    echo "Press any key to exit"
    timeout -1 | Out-Null
    exit
}

if ($steamid.count -gt 1) {
    foreach ($id in $steamid) {
        $lines = Get-Content "$steampath\userdata\$($id)\config\localconfig.vdf"
        $newLines = New-Object -TypeName 'System.Collections.Generic.List[string]' -ArgumentList $lines.Count
        $newLines.Add("{") | Out-Null
        foreach ($line in $lines) {
            $matchCollection = [regex]::Matches($line, '\s*(\".*?\")')
            if ($matchCollection.Count -eq 2) {
                $line = $line.Replace($matchCollection[0].Groups[1].Value, ("{0}:" -f $matchCollection[0].Groups[1].Value))
                $secondVal = $matchCollection[1].Groups[1].Value.Clone()
                [int64]$tryLongVal = 0
                if ([int64]::TryParse($secondVal.Replace('"', ''), [ref] $tryLongVal)) {
                    $secondVal = $secondVal.Replace('"', '')
                }
                $newLines.Add($line.Replace($matchCollection[1].Groups[1].Value, ("{0}," -f $secondVal))) | Out-Null
            } elseif ($matchCollection.Count -eq 1) {
                $newLines.Add($line.Replace($matchCollection[0].Groups[1].Value, ("{0}:" -f $matchCollection[0].Groups[1].Value))) | Out-Null
            } else {
                $newLines.Add($line) | Out-Null
            }
        }
        $newLines.Add("}") | Out-Null
        $joinedLine = $newLines -join "`n"
        $joinedLine = [regex]::Replace($joinedLine, '\}(\s*\n\s*\")', '},$1', "Multiline")
        $joinedLine = [regex]::Replace($joinedLine, '\"\,(\n\s*\})', '"$1', "Multiline")
        $startIndex = $joinedLine.IndexOf('"friends"') + 10
        $endIndex = $joinedLine.IndexOf('}', $startIndex) + 1
        $validJson = $joinedLine.Substring($startIndex, $endIndex - $startIndex)
        $validJson = "$validJson}}"
        $data = ConvertFrom-Json $validJson

        $steamAccountName = [System.Collections.ArrayList](@())
        $steamAccountName.add($data.PersonaName) | Out-Null
    }
    echo "Multiple Steam accounts found, please select the one you would like to use"
    $i=1
    foreach ($name in $steamAccountName) {
        echo "[$i] $name"
        ++$i
    }
    $choice = Read-Host "What Steam account would you like to use?"
    $steamid = $steamid[$choice-1]
    if ($steamid -eq $null) {
        echo "That is not a valid Steam account"
        echo "Press any key to exit"
        timeout -1 | Out-Null
        exit
    }
}

if (test-path "$env:appdata\$cloudName\CloudConfig.json") {
    $disableChoice = Read-Host "SteamCloudify is already installed for this game. Would you like to uninstall SteamCloudify? [Y/n]"
    if ($disableChoice -ne "n" -and $disableChoice -ne "N" -and $disableChoice -ne "no") {
        if (test-path "$env:appdata\$cloudName\1\") {
            echo "SteamCloudify made backups of your save data, they are not needed anymore and can be deleted."
            echo "Deleting them will have no effect on your saves stored locally, on other computers, or in Steam Cloud."
            $choice = Read-Host "Would you like to delete local save backups? [Y/n]"
            if ($choice -eq "n" -or $choice -eq "N" -or $choice -eq "no") {
                Move-Item "$env:appdata\$cloudName\" "$env:userprofile\desktop\Save Backups for $gamename\" -Force -Exclude "CloudConfig.json"
            }
        }
        cls
        echo "Disabling cloud sync on this computer..."
        $CloudConfig = Get-Content "$env:appdata\$cloudName\CloudConfig.json" | ConvertFrom-Json
        cd $CloudConfig.gamepath
        Remove-Item ".\$gameExecutableName"
        Rename-Item ".\$($gameExecutableName.TrimEnd(".exe")) Game.exe" "$gameExecutableName"
        taskkill /f /im "$cloudName.exe" 2>$null | Out-Null
        Remove-Item "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$cloudName.exe"
        Remove-Item "$env:appdata\$cloudName\" -force -Recurse
        Remove-Item HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$cloudName -Recurse -Force
        echo "Finished, press any key to exit"
        timeout -1 | Out-Null
        exit
    } else {
        echo "Press any key to exit"
        timeout -1 | Out-Null
        exit
    }
}

if (Test-Path "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\isConfigured.vdf") {
    while ($choice -eq $null) {
        echo "SteamCloudify has already been installed on another computer, and saves for that computer are already in Steam Cloud"
        echo "[1] Override your Steam Cloud saves with the ones on this computer"
        echo "[2] Override your saves on this computer with the ones in Steam Cloud"
        echo "[3] Cancel installation"
        $choice = Read-Host "What would you like to do"
        if ($choice -eq 1) {
            del "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\" -Recurse
            cls
            break
        }
        if ($choice -eq 2) {
            cls
            break
        }
        if ($choice -eq 3) {
            echo "Installation canceled"
            echo "Press any key to exit"
            timeout -1 | Out-Null
            exit
        }
        echo "That is not a valid option"
        timeout -1
        $choice = $null
        cls
    }
} else {
    $choice = 1
}

echo "Setup is ready to begin, press any key to continue with setup"
timeout -1 | Out-Null
cls
echo "Setting up Steam Cloud..."
$steamPath = (Get-ItemProperty -path 'HKCU:\SOFTWARE\Valve\Steam').steamPath
$i=0
if (test-path "$steamPath\steamapps\common\$gameFolderName\") {
    $gamepath = "$steamPath\steamapps\common\$gameFolderName\"
} else {
    explorer.exe "steam://launch/$steamAppID"
    while ($gamepath -eq $null -and $i -lt 5) {
        $gamepath = Get-CimInstance Win32_Process -Filter "name = '$gameExecutableName'" -ErrorAction SilentlyContinue
        ++$i
        timeout.exe /t 1 /nobreak | Out-Null
    }
    if ($gamepath -eq $null) {
        echo "Unable to get game install location, please make sure that Steam is running and try again"
        echo "Press any key to exit"
        timeout -1 | Out-Null
        exit
    }
    $gamepath = $gamepath.CommandLine -replace '"', ""
    $gamepath = $gamepath.TrimEnd($gameExecutableName)
    taskkill /f /im $gameExecutableName 2>$null | Out-Null
}

mkdir "$env:appdata\$cloudname\" | out-null
Rename-Item "$gamepath\$gameExecutableName" "$($gameExecutableName.TrimEnd(".exe")) Game.exe"
if ($gameSaveFolder -ne $null) {
    Copy-Item "$gameSaveFolder" "$env:appdata\$cloudName\1\" -Recurse -Force | Out-Null
}
if ($gameRegistryEntries -ne $null) {
    reg export $gameRegistryEntries "$env:appdata\$cloudName\1.reg"
}
mkdir "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID" | out-null
Copy-Item ".\SteamCloudSync.exe" "$gamepath\$gameExecutableName" 
Copy-Item ".\SteamCloudBackground.exe" "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$cloudName.exe"
if ($choice -eq 1) {
    if ($gameSaveFolder -ne $null) {
        Get-ChildItem $gameSaveFolder -recurse -Include ($gameSaveExtensions | ForEach-Object { "*$_" }) | `
        ForEach-Object {
            $targetFile = "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\" + $_.FullName.SubString($gameSaveFolder.Length)
            New-Item -ItemType File -Path $targetFile -Force | Out-Null
            Copy-Item $_.FullName -destination $targetFile
        }
        $cloudFiles = Get-ChildItem -Path "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\"  -Include ($gameSaveExtensions | ForEach-Object { "*$_" }) -File -Recurse
        foreach ($file in $cloudFiles) {
            Rename-Item $file "$($file.Name).vdf"
        }
    }
    if ($gameRegistryEntries -ne $null) {
        reg export $gameRegistryEntries "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\regEntries.reg"
    }
    "isConfigured" | Set-Content "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\isConfigured.vdf"
}
$CloudConfig = @{}
$CloudConfig.Add("gamepath",$gamepath)
$CloudConfig.Add("steampath",$steamPath)
$CloudConfig.Add("steamID",$steamid)
$CloudConfig.Add("lastBackup",(Get-Date).ToUniversalTime().Subtract((Get-Date "1/1/1970")).TotalSeconds)
$CloudConfig.Add("CloudSyncDownload", $updateLink)
$CloudConfig | ConvertTo-Json -depth 32 | Format-Json | Set-Content "$env:appdata\$cloudName\CloudConfig.json"
Install-Module -Name BurntToast -Confirm:$false -Force
New-Item -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$cloudName | Out-Null
New-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$cloudName -Name "DisplayIcon" -Value "$gamepath\$gameExecutableName" -PropertyType "String" -Force | Out-Null
New-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$cloudName -Name "DisplayName" -Value "$cloudName" -PropertyType "String" -Force | Out-Null
New-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$cloudName -Name "DisplayVersion" -Value $(Get-Item $gamepath\$gameExecutableName).VersionInfo.FileVersion -PropertyType "String" -Force | Out-Null
New-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$cloudName -Name "EstimatedSize" -Value 754 -PropertyType "DWORD" -Force | Out-Null
New-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$cloudName -Name "InstallDate" -Value $(Get-Date -Format "M/d/yyyy") -PropertyType "String" -Force | Out-Null
New-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$cloudName -Name "InstallLocation" -Value $gamePath -PropertyType "String" -Force | Out-Null
New-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$cloudName -Name "NoRepair" -Value 1 -PropertyType "DWORD" -Force | Out-Null
New-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$cloudName -Name "Publisher" -Value "Aldin101" -PropertyType "String" -Force | Out-Null
New-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$cloudName -Name "UninstallString" -Value "$gamePath\$gameExecutableName /C:`"powershell -executionPolicy bypass -windowstyle hidden -command set-content -value 1 $env:userprofile\uninstall.set; .\SteamCloudSync.ps1`"" -PropertyType "String" -Force | Out-Null
New-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$cloudName -Name "ModifyPath" -Value "$gamePath\$gameExecutableName /C:`"cmd /c powershell -executionPolicy bypass -command set-content -value 1 $env:userprofile\modify.set; .\SteamCloudSync.ps1`"" -PropertyType "String" -Force | Out-Null
Start-Process "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$cloudname.exe"
cls
echo "SteamCloudify setup has completed, remember to install on other computers to sync saves"
echo "Press any key to exit"
timeout -1 |Out-Null