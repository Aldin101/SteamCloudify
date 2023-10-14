# !templates\unity
# Game specific start----------------------------------------------------------------------------------------------------------------------------
$gameName = "[INSERT GAME NAME]" # name of the game
$steamAppID = "[INSERT STEAM APP ID]" # you can find this on https://steamdb.info, it should be structured like this, "NUMBER"
$gameExecutableName = "[INSERT EXECUTABLE NAME]" # executable name should be structured, "GAME NAME.exe"
$gameFolderName = "[INSERT FOLDER NAME]" # install folder should be structured like this, "GAME FOLDER NAME" just give the folder name
$gameSaveFolder = "[INSERT SAVE LOCATION]" # the folder where saves are located, if the game does not store save files in a folder comment this out-
# -If the game does it should be structured like this "FullFolderPath". Make sure not to include user/computer specific information and use-
# -enviorment varables instead. Most Unity games store files at "$env:appdata\..\LocalLow\[COMPANY NAME]\[GAME NAME]"
$gameSaveExtensions = "[INSERT SAVE FILE EXTENTIONS]" # the game save folder sometimes contains information other than just game saves, and some-
# -files should not be uploaded to Steam Cloud. If there is one extention format it like this ".[EXTENTION]". If there are more that one format it like this
# "[EXTENTION1]", "[EXTENTION2]", "[EXTENTION3]"
$gameRegistryEntries = "[INSERT REGISTRY LOCATION]" # the location where registry entries are located, if the game does not store save files in the registry-
# - comment this out. If the game does it should be structured like this "HKCU\SOFTWARE\[COMPANY NAME]\[GAME NAME]".
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