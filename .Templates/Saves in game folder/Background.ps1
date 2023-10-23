# .templates\saves in game folder
# Game specific start----------------------------------------------------------------------------------------------------------------------------
$gameName = "[INSERT GAME NAME]" # name of the game
$steamAppID = "[INSERT STEAM APP ID]" # you can find this on https://steamdb.info, it should be structured like this, "NUMBER"
$gameExecutableName = "[INSERT EXECUTABLE NAME]" # executable name should be structured, "GAME NAME.exe"
$gameFolderName = "[INSERT FOLDER NAME]" # install folder should be structured like this, "GAME FOLDER NAME" just give the folder name
$gameSaveFolder = '$gameSaveFolder = "$gamepath\[INSERT SAVE LOCATION]"' # the folder where saves are located, if the game does not store save files- 
# -in a folder comment this out.
# If the game does it should be structured like this '$gameSaveFolder = "$gamepath\location\to\saves"'. This value uses the game executable location as a-
# -starting point, not the root of the folder so if the game executable is located in "C:\Program Files (x86)\Steam\steamapps\common\Game Name\Game.exe" and-
# -the save files are located in "C:\Program Files (x86)\Steam\steamapps\common\Game Name\Save Files" the value should be '$gameSaveFolder = "$gamepath\Save Files"'
# but if the game executable is located in "C:\Program Files (x86)\Steam\steamapps\common\Game Name\win10\binaries\Game.exe" and the save files are located in-
# "C:\Program Files (x86)\Steam\steamapps\common\Game Name\Save Files" the value should be '$gameSaveFolder = "$gamepath\..\..\Save Files"'
# the ".." means to go back one folder, so make sure that you are going back the correct amount of folders if the game exe is not stored in the root of the game-
# -folder. If you need help with this contact me on Discord by sending a friend request to aldin101
$gameSaveExtensions = "[INSERT SAVE FILE EXTENSIONS]" # the game save folder sometimes contains information other than just game saves, and some-
# -files should not be uploaded to Steam Cloud. If there is one extension format it like this ".[EXTENSION]". If there are more that one format it like this
# "[EXTENSION1]", "[EXTENSION2]", "[EXTENSION3]"
$gameRegistryEntries = "[INSERT REGISTRY LOCATION]" # the location where registry entries are located, if the game does not store save files in the registry-
# -comment this out by simply putting a "#" before the "$". If the game does it should be structured like this "HKCU\SOFTWARE\[COMPANY NAME]\[GAME NAME]"-
# -(this is where most games store entires).
# Game specific end------------------------------------------------------------------------------------------------------------------------------

$cloudName = "$gameName Steam Cloud"
$databaseURL = "https://aldin101.github.io/Steam-Cloud/$($gameName.Replace(' ', '%20'))/$($gameName.Replace(' ', '%20')).json"
$updateLink = "https://aldin101.github.io/Steam-Cloud/$($gameName.Replace(' ', '%20'))/SteamCloudSync.exe"
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

$config = Get-Content "$env:appdata\$cloudName\CloudConfig.json" | ConvertFrom-Json
$steamPath = $config.steamPath
$steamid = $config.steamID
$gamepath = $config.gamepath
$gameSaveFolder | iex
cd $gamepath
$exehash=Get-FileHash -Algorithm MD5 "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$cloudName.exe"
while (1) {
    while (!(Test-Path "$gamepath\..\..\Downloading\$steamAppID")) {
        Start-Sleep -s 3
        if (!(Test-Path "$gamepath\..\..\appmanifest_$steamAppID.acf")) {
            $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
            if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $false) {
                [System.Windows.Forms.MessageBox]::Show( "Looks like you uninstalled $gamename, uninstalling $gamename does not uninstall (NAME). Simply press ok to uninstall (NAME) for $gamename", "Uninstalling (NAME)", "Ok", "Information")
                Start-Process "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$cloudname.exe" -Verb runAs
                exit
            }
            taskkill /f /im "$cloudname.exe" 2>$null | Out-Null
            del "$env:appdata\$cloudname\CloudConfig.json"
            del "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$cloudname.exe"
            rmdir "$env:appdata\$cloudname\" -force
            del ".\$($gameExecutableName.TrimEnd('.exe')) Game.exe"
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
    Remove-Item ".\$($gameExecutableName.TrimEnd(".exe")) Game.exe"
    taskkill /f /im "$gameExecutableName"
    Rename-Item ".\$gameExecutableName" "$($gameExecutableName.TrimEnd(".exe")) Game.exe"
    Invoke-WebRequest $config.CloudSyncDownload -OutFile ".\$gameExecutableName"
}