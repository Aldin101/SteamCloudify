# .templates\unity
# Game specific start----------------------------------------------------------------------------------------------------------------------------
$gameName = "[INSERT GAME NAME]" # name of the game
$steamAppID = "[INSERT STEAM APP ID]" # you can find this on https://steamdb.info, it should be structured like this, "NUMBER"
$gameExecutableName = "[INSERT EXECUTABLE NAME]" # executable name should be structured, "GAME NAME.exe"
$gameFolderName = "[INSERT FOLDER NAME]" # install folder should be structured like this, "GAME FOLDER NAME" just give the folder name
$gameSaveFolder = "[INSERT SAVE LOCATION]" # the folder where saves are located, if the game does not store save files in a folder comment this out-
# -If the game does it should be structured like this "FullFolderPath". Make sure not to include user/computer specific information and use-
# -environment variables instead. Most Unity games store files at "$env:appdata\..\LocalLow\[COMPANY NAME]\[GAME NAME]"
$gameSaveExtensions = "[INSERT SAVE FILE EXTENSIONS]" # the game save folder sometimes contains information other than just game saves, and some-
# -files should not be uploaded to Steam Cloud. If there is one extension format it like this ".[EXTENSION]". If there are more that one format it like this
# "[EXTENSION1]", "[EXTENSION2]", "[EXTENSION3]"
$gameRegistryEntries = "[INSERT REGISTRY LOCATION]" # the location where registry entries are located, if the game does not store save files in the registry-
# - comment this out by simply putting a "#" before the "$". If the game does it should be structured like this "HKCU\SOFTWARE\[COMPANY NAME]\[GAME NAME]".
$databaseURL = "[DATABASE URL]"
# The URL where the installer database can be found so that this installer knows where to download the cloud sync util and background task
$updateLink = "[URL FOR GAME LAUNCH TASK]"
# The URL where the launch executable can be found so that this background task knows where to download the launch task from. This link is not used by this-
# installer as all the required files are bundled. This is used by the background task to download the launch task when the game updates.
# Game specific end------------------------------------------------------------------------------------------------------------------------------

$cloudName = "$gameName Steam Cloud"

$ProgressPreference = "SilentlyContinue"
$ErrorActionPreference = "SilentlyContinue"
$clientVersion = "1.0.0"
$host.ui.RawUI.WindowTitle = "Steam Cloud Installer  |  Version: $clientVersion"
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $false) {
    $fileLocation = Get-CimInstance Win32_Process -Filter "name = 'Steam Cloud Installer for $gameName.exe'" -ErrorAction SilentlyContinue
    if ($fileLocation -eq $null) {
        echo "Unable request admin, please manually run the program as administrator to continue"
        echo "Press any key to exit"
        timeout -1 |out-null
        exit
    }
    taskkill /f /im "Steam Cloud Installer for $gameName.exe" 2>$null | Out-Null
    $fileLocation1 = $fileLocation.CommandLine -replace '"', ""
    try {
        Start-Process "$filelocation1" -Verb RunAs
    } catch {
        echo "The Steam Cloud installer requires administator privileges, please accept the admin prompt to continue"
        echo "Press any key to try again"
        timeout -1 | out-null
        try {
            Start-Process "$filelocation1" -Verb RunAs
        } catch {
            cls
            echo "The Steam Cloud installer cannot continue without administator privileges"
            echo "Press any key to exit"
            timeout -1 | out-null
        }
    }
    exit
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

echo "Welcome to Steam Cloud setup"
echo "Here are some things to know:"
echo "This tool is not inteded as a backup, it is only inteded to sync your saves between computers, please us other tools for" "backups such as GameSaveManager"
echo "Your saves will only be synced with other computers that have this tool installed"
echo "When you install on another computer you will have the choice to download your saves from the cloud or upload your saves" "to the cloud, once you choose to override saves on a computer or the cloud you will not be able to recover the" "overritten saves"
echo "You can disable Steam Cloud on this computer for any game by using this setup tool again"
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
    $disableChoice = Read-Host "Steam Cloud is already enabled for this game. Would you like to disable Steam Cloud [y/n]"
    if ($disableChoice -ne "n" -and $disableChoice -ne "N" -and $disableChoice -ne "no") {
        echo "Disabling cloud sync on this computer..."
        $CloudConfig = Get-Content "$env:appdata\$cloudName\CloudConfig.json" | ConvertFrom-Json
        cd $CloudConfig.gamepath
        Remove-Item ".\$($gameExecutableName.TrimEnd(".exe")) Game_Data" -Recurse
        Remove-Item ".\$gameExecutableName"
        Rename-Item ".\$($gameExecutableName.TrimEnd(".exe")) Game.exe" "$gameExecutableName"
        taskkill /f /im "$cloudName.exe" 2>$null | Out-Null
        Remove-Item "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$cloudName.exe"
        Remove-Item "$env:appdata\$cloudName\CloudConfig.json"
        echo "Finished, press any key to exit"
        timeout -1 | Out-Null
        exit
    } else {
        echo "Press any key to exit"
        timeout -1 | Out-Null
        exit
    }
}

echo "Steam Cloud setup is ready to begin, press any key to continue with setup"
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

if (Test-Path "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\isConfigured.vdf") {
    while ($choice -eq $null) {
        echo "Steam Cloud has already been setup on another computer, and saves for that computer are already in Steam Cloud"
        echo "[1] Override your Steam Cloud saves with the ones on this computer"
        echo "[2] Override your saves on this computer with the ones in Steam Cloud"
        echo "[3] Cancel installation"
        $choice = Read-Host "What would you like to do"
        if ($choice -eq 1) {
            del "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\" -Recurse
            break
        }
        if ($choice -eq 2) {
            break
        }
        if ($choice -eq 3) {
            echo "Installation cancled"
            echo "Press any key to exit"
            timeout -1 | Out-Null
            exit
        }
        echo "That is not a valid option"
        timeout -1
        $choice = $null
        cls
        echo "Setting up Steam Cloud..."
    }
} else {
    $choice = 1
}
mkdir "$env:appdata\$gamename Steam Cloud\" | out-null
Rename-Item "$gamepath\$gameExecutableName" "$($gameExecutableName.TrimEnd(".exe")) Game.exe"
Copy-Item "$gamepath\$($gameExecutableName.TrimEnd(".exe"))_Data" "$gamepath\$($gameExecutableName.TrimEnd(".exe")) Game_Data" -Recurse
mkdir "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID"
Copy-Item ".\SteamCloudSync.exe" "$gamepath\$gameExecutableName" 
Copy-Item ".\SteamCloudBackground.exe" "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$cloudName.exe"
if ($choice -eq 1) {
    if ($gameSaveFolder -ne $null) {
        $files = Get-ChildItem -Path "$gameSaveFolder" -Include ($gameSaveExtensions | ForEach-Object { "*$_" }) -File -Recurse
        foreach ($file in $files) {
            mkdir "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\$($file.VersionInfo.FileName.TrimStart($gameSaveFolder).TrimEnd($file.name))"
            Copy-Item $file "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\$($file.VersionInfo.FileName.TrimStart($gameSaveFolder)).vdf"        }
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
$CloudConfig.Add("CloudSyncDownload", $updateLink)
$CloudConfig | ConvertTo-Json -depth 32 | Format-Json | Set-Content "$env:appdata\$cloudName\CloudConfig.json"
Start-Process "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$gameName Steam Cloud.exe"
cls
echo "Steam Cloud setup has completed, remember to install on other computers to sync saves"
echo "Press any key to exit"
timeout -1 |Out-Null