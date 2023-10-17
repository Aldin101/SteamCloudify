# .templates\unity
# Game specific start----------------------------------------------------------------------------------------------------------------------------
$gameName = "Dyson Sphere Program" # name of the game
$steamAppID = "1366540" # you can find this on https://steamdb.info, it should be structured like this, "NUMBER"
$gameExecutableName = "DSPGAME.exe" # executable name should be structured, "GAME NAME.exe"
$gameFolderName = "Dyson Sphere Program" # install folder should be structured like this, "GAME FOLDER NAME" just give the folder name
$gameSaveFolder = "$env:userprofile\Documents\Dyson Sphere Program" # the folder where saves are located, if the game does not store save files in a folder comment this out-
# -If the game does it should be structured like this "FullFolderPath". Make sure not to include user/computer specific information and use-
# -environment variables instead. Most Unity games store files at "$env:appdata\..\LocalLow\[COMPANY NAME]\[GAME NAME]"
$gameSaveExtensions = ".dsv" # the game save folder sometimes contains information other than just game saves, and some-
# -files should not be uploaded to Steam Cloud. If there is one extension format it like this ".[EXTENSION]". If there are more that one format it like this
# "[EXTENSION1]", "[EXTENSION2]", "[EXTENSION3]"
# $gameRegistryEntries = "[INSERT REGISTRY LOCATION]" # the location where registry entries are located, if the game does not store save files in the registry-
# - comment this out by simply putting a "#" before the "$". If the game does it should be structured like this "HKCU\SOFTWARE\[COMPANY NAME]\[GAME NAME]".
$databaseURL = "https://aldin101.github.io/Steam-Cloud/Dyson%20Sphere%20Program/Dyson%20Sphere%20Program.json"
# The URL where the installer database can be found so that this installer knows where to download the cloud sync util and background task
$updateLink = "https://aldin101.github.io/Steam-Cloud/Dyson%20Sphere%20Program/SteamCloudSync.exe"
# The URL where the launch executable can be found so that this background task knows where to download the launch task from. This link is not used by this-
# installer as all the required files are bundled. This is used by the background task to download the launch task when the game updates.
# Game specific end------------------------------------------------------------------------------------------------------------------------------


$cloudName = "$gameName Steam Cloud"
$file = Invoke-WebRequest "$databaseURL" -UseBasicParsing
$database = $file.Content | ConvertFrom-Json
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

cd $gamepath
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
Rename-Item ".\$gameExecutableName" "$($gameExecutableName.TrimEnd(".exe")) Game.exe"
Copy-Item ".\$($gameExecutableName.TrimEnd(".exe"))_Data" ".\$($gameExecutableName.TrimEnd(".exe")) Game_Data" -Recurse
mkdir "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID"
Invoke-WebRequest $database.updateLink -OutFile ".\$gameExecutableName" 
Invoke-WebRequest $database.gameUpdateChecker -OutFile "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$cloudName.exe"
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
$CloudConfig.Add("CloudSyncDownload", $database.updateLink)
$CloudConfig | ConvertTo-Json -depth 32 | Format-Json | Set-Content "$env:appdata\$cloudName\CloudConfig.json"
Start-Process "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$gameName Steam Cloud.exe"
cls
echo "Steam Cloud setup has completed, remember to install on other computers to sync saves"
echo "Press any key to exit"
timeout -1 |Out-Null
