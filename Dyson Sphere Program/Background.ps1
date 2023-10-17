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

$config = Get-Content "$env:appdata\$cloudName\CloudConfig.json" | ConvertFrom-Json
$steamPath = $config.steamPath
$steamid = $config.steamID
$gamepath = $config.gamepath
cd $gamepath
$exehash=Get-FileHash -Algorithm MD5 "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$cloudName.exe"
while (1) {
    while (!(Test-Path $gamepath\..\..\Downloading\$steamAppID)) {
        Start-Sleep -s 3
        if (!(Test-Path $gamepath\..\..\appmanifest_$steamAppID.acf)) {
            $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
            if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $false) {
                Start-Process "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$cloudname.exe" -Verb runAs
                exit
            }
            taskkill /f /im "$cloudname.exe" 2>$null | Out-Null
            del "$env:appdata\$cloudname\CloudConfig.json"
            del "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$cloudname.exe"
            cd ..
            del "$gamepath\" -Recurse
            exit
        }
        if ($(Get-FileHash -Algorithm MD5 "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$cloudname.exe").Hash -ne $exehash.Hash) {
            exit
        }
    }
    while (Test-Path $gamepath\..\..\Downloading\$steamAppID) {
        Start-Sleep -s 1
    }
    Start-Sleep -s 3
    Remove-Item ".\$($gameExecutableName.TrimEnd(".exe")) Game_Data" -Recurse
    Remove-Item ".\$($gameExecutableName.TrimEnd(".exe")) Game.exe"
    taskkill /f /im "$gameExecutableName"
    Rename-Item ".\$gameExecutableName" "$($gameExecutableName.TrimEnd(".exe")) Game.exe"
    Invoke-WebRequest $config.CloudSyncDownload -OutFile ".\$gameExecutableName"
    Copy-Item ".\$($gameExecutableName.TrimEnd(".exe"))_Data" ".\$($gameExecutableName.TrimEnd(".exe")) Game_Data" -Recurse
}