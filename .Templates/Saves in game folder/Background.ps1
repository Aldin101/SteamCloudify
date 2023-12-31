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

$cloudName = "SteamCloudify for $gameName"
$databaseURL = "https://aldin101.github.io/SteamCloudify/$($gameName.Replace(' ', '%20'))/$($gameName.Replace(' ', '%20')).json"
$updateLink = "https://aldin101.github.io/SteamCloudify/$($gameName.Replace(' ', '%20'))/SteamCloudSync.exe"
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
[System.Windows.Forms.Application]::EnableVisualStyles()

$config = Get-Content "$env:appdata\$cloudName\CloudConfig.json" | ConvertFrom-Json
$steamPath = $config.steamPath
$steamid = $config.steamID
$gamepath = $config.gamepath
$gameSaveFolder | iex
$fail = $false
cd $gamepath
$exehash=Get-FileHash -Algorithm MD5 "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$cloudName.exe"
while (1) {
    while (!(Test-Path "$gamepath\..\..\Downloading\$steamAppID")) {
        Start-Sleep -s 3
        if (!(Test-Path "$gamepath\..\..\appmanifest_$steamAppID.acf")) {
            $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
            if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $false) {
                [System.Windows.Forms.MessageBox]::Show( "Looks like you uninstalled $gamename, uninstalling $gamename does not uninstall SteamCloudify. Simply press ok to uninstall SteamCloudify for $gamename", "Uninstall SteamCloudify", "Ok", "Information")
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
            Remove-Item "$gamepath\$($executableName.TrimEnd(".exe")) Game.exe"
            Remove-Item HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$cloudName -Recurse -Force
            $choice = [System.Windows.Forms.MessageBox]::Show( "This tool made backups of your save data, they are not needed anymore and can be deleted.`nDeleting them will have no effect on your saves stored locally, on other computers, or in Steam Cloud.`nWould you like to delete the backups?", "Delete Backups", "YesNo", "Question" )
            if ($choice -eq "No") {
                Move-Item "$env:appdata\$cloudName\" "$env:userprofile\desktop\Save Backups for $gamename\" -Force -Exclude "CloudConfig.json"
            }
            Remove-Item "$env:appdata\$cloudName" -Recurse -Force
            [System.Windows.Forms.MessageBox]::Show( "SteamCloudify uninstalled successfully!", "Uninstalled!", "Ok", "Information" )
            exit
        }
        try {
            $startup = Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder" -Name "SteamCloudify for $gameName.exe"
        } catch {
            $fail = $true
        }
        if ($($startup)."steamcloudify for $gamename.exe"[0] -ne 2 -and $($startup)."steamcloudify for $gamename.exe"[0] -ne 6 -and $fail -eq $false) {
            [System.Windows.Forms.MessageBox]::Show("SteamCloudify is not allowed to run at startup. This means that if $gamename updates or the game files are validated SteamCloudify will be unable to re-patch the game.`n`nThis will cause your save data to stop syncing and might even result in data loss.`n`n`Please re-enable SteamCloudify in Task Manger's startup tab or uninstall SteamCloudify. Until one of those actions have been completed you will be unable to launch $gamename", "SteamCloudify", "Ok", "Warning")
            $fail = $true
        }
        if ($(Get-FileHash -Algorithm MD5 "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$cloudname.exe").Hash -ne $exehash.Hash) {
            exit
        }
    }
    New-BurntToastNotification -text 'SteamCloudify', "Looks like $gamename is updating, SteamCloudify will automatically re-patch the game when this update finishes, please do not launch the game till re-patching finishes" -AppLogo hIsTheBestLetter -UniqueIdentifier "gameUpdate"
    while (Test-Path $gamepath\..\..\Downloading\$steamAppID) {
        Start-Sleep -s 1
    }
    New-BurntToastNotification -text 'SteamCloudify', "$gamename has finished updating, re-patching now..." -AppLogo hIsTheBestLetter -UniqueIdentifier "gameUpdate" -Silent
    Start-Sleep -s 3
    Remove-Item ".\$($gameExecutableName.TrimEnd(".exe")) Game.exe"
    taskkill /f /im "$gameExecutableName"
    Rename-Item ".\$gameExecutableName" "$($gameExecutableName.TrimEnd(".exe")) Game.exe"
    Invoke-WebRequest $config.CloudSyncDownload -OutFile ".\$gameExecutableName"
    New-BurntToastNotification -text 'SteamCloudify', "SteamCloudify has finished re-patching $gamename, have fun!" -AppLogo hIsTheBestLetter -UniqueIdentifier "gameUpdate"
}