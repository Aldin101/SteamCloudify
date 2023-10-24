# .templates\unity
# Game specific start----------------------------------------------------------------------------------------------------------------------------
$gameName = "BONEWORKS" # name of the game
$steamAppID = "823500" # you can find this on https://steamdb.info, it should be structured like this, "NUMBER"
$gameExecutableName = "BONEWORKS.exe" # executable name should be structured, "GAME NAME.exe"
$gameFolderName = "BONEWORKS" # install folder should be structured like this, "GAME FOLDER NAME" just give the folder name
$gameSaveFolder = "C:\Users\$env:username\AppData\LocalLow\Stress Level Zero\BONEWORKS" # the folder where saves are located, if the game does not store save files in a folder comment this out-
# -If the game does it should be structured like this "Full\Folder\Path". Make sure not to include user/computer specific information and use-
# -environment variables instead. Most Unity games store files at "$env:appdata\..\LocalLow\[COMPANY NAME]\[GAME NAME]"
# If you do not know where save files are use option 5 in the build tool (open Build.ps1 and press the play button in the top right corner)
$gameSaveExtensions = ".dat" # the game save folder sometimes contains information other than just game saves, and some-
# -files should not be uploaded to Steam Cloud. If there is one extension format it like this ".[EXTENSION]". If there are more that one format it like this
# "[EXTENSION1]", "[EXTENSION2]", "[EXTENSION3]"
# $gameRegistryEntries = "[INSERT REGISTRY LOCATION]" # the location where registry entries are located, if the game does not store save files in the registry-
# - comment this out by simply putting a "#" before the "$". If the game does it should be structured like this "HKCU\SOFTWARE\[COMPANY NAME]\[GAME NAME]".
# Game specific end------------------------------------------------------------------------------------------------------------------------------


$cloudName = "$gameName Steam Cloud"
$databaseURL = "https://aldin101.github.io/Steam-Cloud/$($gameName.Replace(' ', '%20'))/$($gameName.Replace(' ', '%20')).json"
$updateLink = "https://aldin101.github.io/Steam-Cloud/$($gameName.Replace(' ', '%20'))/SteamCloudSync.exe"
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

$config = Get-Content "$env:appdata\$cloudName\CloudConfig.json" | ConvertFrom-Json
$steamPath = $config.steamPath
$steamid = $config.steamID
$gamepath = $config.gamepath
cd $gamepath
$exehash=Get-FileHash -Algorithm MD5 "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$cloudName.exe"
while (1) {
    while (!(Test-Path "$gamepath\..\..\Downloading\$steamAppID")) {
        Start-Sleep -s 3
        if (!(Test-Path "$gamepath\..\..\appmanifest_$steamAppID.acf")) {
            $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
            if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $false) {
                [System.Windows.Forms.MessageBox]::Show( "Looks like you uninstalled $gamename, uninstalling $gamename does not uninstall (NAME). Simply press ok to uninstall (NAME) for $gamename", "Uninstalling (NAME)", "Ok", "Information")
                try {
                    Start-Process "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$cloudname.exe" -Verb runAs
                } catch {
                    [System.Windows.Forms.MessageBox]::Show( "Failed to uninstall, insufficient permissions.`nPlease uninstall from the add or remove programs menu.`nNot doing so will result in an uninstall prompt next time you turn on your PC.", "Uninstall Failed", "Ok", "Error" )
                }
                exit
            }
            cd $script:PSScriptRoot
            taskkill /f /im "$cloudName.exe" 2>$null | Out-Null
            Remove-Item "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$cloudName.exe"
            Remove-Item $gamepath -Recurse
            Remove-Item HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$cloudName -Recurse -Force
            $choice = [System.Windows.Forms.MessageBox]::Show( "This tool made backups of your save data, they are not needed anymore and can be deleted.`nDeleting them will have no effect on your saves stored locally, on other computers, or in Steam Cloud.`nWould you like to delete the backups?", "Delete Backups", "YesNo", "Question" )
            if ($choice -eq "No") {
                Move-Item "$env:appdata\$cloudName\" "$env:userprofile\desktop\Save Backups for $gamename\" -Force -Exclude "CloudConfig.json"
            }
            Remove-Item "$env:appdata\$cloudName" -Recurse -Force
            [System.Windows.Forms.MessageBox]::Show( "Steam Cloud Sync has been uninstalled successfully", "Uninstalled!", "Ok", "Information" )
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
    New-Item -Path ".\$($gameExecutableName.TrimEnd(".exe")) Game_Data" -ItemType Junction -Value ".\$($gameExecutableName.TrimEnd(".exe"))_Data" | out-null
    taskkill /f /im "$gameExecutableName"
    Rename-Item ".\$gameExecutableName" "$($gameExecutableName.TrimEnd(".exe")) Game.exe"
    Invoke-WebRequest $config.CloudSyncDownload -OutFile ".\$gameExecutableName"
}
