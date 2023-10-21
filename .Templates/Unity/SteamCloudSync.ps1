# .templates\unity
# Game specific start----------------------------------------------------------------------------------------------------------------------------
$gameName = "[INSERT GAME NAME]" # name of the game
$steamAppID = "[INSERT STEAM APP ID]" # you can find this on https://steamdb.info, it should be structured like this, "NUMBER"
$gameExecutableName = "[INSERT EXECUTABLE NAME]" # executable name should be structured, "GAME NAME.exe"
$gameFolderName = "[INSERT FOLDER NAME]" # install folder should be structured like this, "GAME FOLDER NAME" just give the folder name
$gameSaveFolder = "[INSERT SAVE LOCATION]" # the folder where saves are located, if the game does not store save files in a folder comment this out-
# -If the game does it should be structured like this "Full\Folder\Path". Make sure not to include user/computer specific information and use-
# -environment variables instead. Most Unity games store files at "$env:appdata\..\LocalLow\[COMPANY NAME]\[GAME NAME]"
# If you do not know where save files are use option 5 in the build tool (open Build.ps1 and press the play button in the top right corner)
$gameSaveExtensions = "[INSERT SAVE FILE EXTENSIONS]" # the game save folder sometimes contains information other than just game saves, and some-
# -files should not be uploaded to Steam Cloud. If there is one extension format it like this ".[EXTENSION]". If there are more that one format it like this
# "[EXTENSION1]", "[EXTENSION2]", "[EXTENSION3]"
$gameRegistryEntries = "[INSERT REGISTRY LOCATION]" # the location where registry entries are located, if the game does not store save files in the registry-
# - comment this out by simply putting a "#" before the "$". If the game does it should be structured like this "HKCU\SOFTWARE\[COMPANY NAME]\[GAME NAME]".
# Game specific end------------------------------------------------------------------------------------------------------------------------------

$cloudName = "$gameName Steam Cloud"
$databaseURL = "https://aldin101.github.io/Steam-Cloud/$($gameName.Replace(' ', '%20'))/$($gameName.Replace(' ', '%20')).json"
$updateLink = "https://aldin101.github.io/Steam-Cloud/$($gameName.Replace(' ', '%20'))/SteamCloudSync.exe"
$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
$file = Invoke-WebRequest "$databaseURL" -UseBasicParsing
$database = $file.Content | ConvertFrom-Json
$config = Get-Content "$env:appdata\$cloudName\CloudConfig.json" | ConvertFrom-Json
$steamPath = $config.steamPath
$steamid = $config.steamID
$gamepath = $config.gamepath
$clientVersion = $(Get-Item -Path "$gamepath\$gameExecutableName").VersionInfo.FileVersion

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
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ((test-path "$env:userprofile\uninstall.set") -and $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $true) {
    taskkill /f /im "$cloudName.exe" 2>$null | Out-Null
    taskkill /f /im "$gameExecutableName" 2>$null | Out-Null
    Remove-Item "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$cloudName.exe"
    Remove-Item "$gamepath\$gameExecutableName"
    Rename-Item "$gamepath\$($gameExecutableName.TrimEnd(".exe")) Game.exe" "$gameExecutableName"
    Remove-Item "$gamepath\$($gameExecutableName.TrimEnd(".exe")) Game_Data" -force -recurse
    Remove-Item HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$cloudName -Recurse -Force
    $choice = [System.Windows.Forms.MessageBox]::Show( "This tool made backups of your save data, they are not needed anymore and can be deleted.`nDeleting them will have no effect on your saves stored locally, stored on other computer or in Steam Cloud.`nWould you like to delete the backups?", "Delete Backups", "YesNo", "Question" )
    if ($choice -eq "No") {
        Move-Item "$env:appdata\$cloudName\" "$env:userprofile\desktop\Save Backups for $gamename\" -Force -Exclude "CloudConfig.json"
    }
    Remove-Item "$env:appdata\$cloudName" -Recurse -Force
    Remove-Item "$env:userprofile\uninstall.set"
    [System.Windows.Forms.MessageBox]::Show( "Steam Cloud Sync has been uninstalled successfully", "Uninstalled!", "Ok", "Information" )
    exit
}

if (test-path "$env:userprofile\uninstall.set") {
    $choice = [System.Windows.Forms.MessageBox]::Show( "Would you like to uninstall Steam Cloud Sync?", "Uninstall", "YesNo", "Question" )
    if ($choice -eq "Yes") {
        try {
            Start-Process $gamepath\$gameExecutableName -Verb RunAs
        } catch {
            Remove-Item "$env:userprofile\uninstall.set"
            [System.Windows.Forms.MessageBox]::Show( "Failed to uninstall, insufficient permissions", "Uninstall Failed", "Ok", "Error" )
        } finally {
            exit
        }
    } else {
        exit
    }
}

if (Test-Path "$env:userprofile\Modify.set") {
    Remove-Item "$env:userprofile\Modify.set"
    $host.RawUI.WindowTitle = "$cloudname Backup Utility"
    cls
    echo "Welcome to the Steam Cloud Sync backup manager"
    echo "This tool allows you to manage your backups for $gamename"
    echo "This Steam Cloud Sync makes local backups of your save games weekly, just incase something goes wrong."
    $choice = Read-Host "Would you like to restore a backup? [Y/n]"
    if ($choice -eq "n" -or $choice -eq "N" -or $choice -eq "no") {
        echo "Press any key to exit"
        timeout -1 | Out-Null
        exit
    }
    cls
    if ((test-path $env:appdata\$cloudName\1) -or (test-path $env:appdata\$cloudName\1.reg)) {
        if (!(test-path $env:appdata\$cloudName\1)) {
            echo "[1] Backup from $((Get-Item -Path $env:appdata\$cloudName\1.reg).LastWriteTime)"
        } else {
            echo "[1] Backup from $((Get-Item -Path $env:appdata\$cloudName\1).LastWriteTime)"
        }
    }
    if ((test-path $env:appdata\$cloudName\2) -or (test-path $env:appdata\$cloudName\2.reg)) {
        if (!(test-path $env:appdata\$cloudName\2)) {
            echo "[2] Backup from $((Get-Item -Path $env:appdata\$cloudName\2.reg).LastWriteTime)"
        } else {
            echo "[2] Backup from $((Get-Item -Path $env:appdata\$cloudName\2).LastWriteTime)"
        }
    }
    if ((test-path $env:appdata\$cloudName\3) -or (test-path $env:appdata\$cloudName\3.reg)) {
        if (!(test-path $env:appdata\$cloudName\3)) {
            echo "[3] Backup from $((Get-Item -Path $env:appdata\$cloudName\3.reg).LastWriteTime)"
        } else {
            echo "[3] Backup from $((Get-Item -Path $env:appdata\$cloudName\3).LastWriteTime)"
        }
    }
    if ((test-path $env:appdata\$cloudName\4) -or (test-path $env:appdata\$cloudName\4.reg)) {
        if (!(test-path $env:appdata\$cloudName\4)) {
            echo "[4] Backup from $((Get-Item -Path $env:appdata\$cloudName\4.reg).LastWriteTime)"
        } else {
            echo "[4] Backup from $((Get-Item -Path $env:appdata\$cloudName\4).LastWriteTime)"
        }
    }
    $choice = Read-Host "What backup would you like to revert to?"
    if (!(Test-Path $env:appdata\$cloudName\$choice) -and !(Test-Path $env:appdata\$cloudName\$choice.reg)) {
        echo "Invalid choice"
        echo "Press any key to exit"
        timeout -1 | Out-Null
        exit
    }
    if ($gameSaveFolder -ne $null) {
        remove-item "$gameSaveFolder" -Recurse -Force
        copy-item "$env:appdata\$cloudName\$choice\" "$gameSaveFolder" -Recurse -Force
        Get-ChildItem "$env:appdata\$cloudName\$choice\" -recurse -Include ($gameSaveExtensions | ForEach-Object { "*$_" }) | `
        ForEach-Object {
            $targetFile = "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\" + $_.FullName.SubString("$env:appdata\$cloudName\$choice\".Length);
            New-Item -ItemType File -Path $targetFile -Force;
            Copy-Item $_.FullName -destination $targetFile
        }
    }
    if ($gameRegistryEntries -ne $null) {
        reg import "$env:appdata\$cloudName\$choice.reg"
        reg export $gameRegistryEntries "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\regEntries.reg"
    }
    $cloudFiles = Get-ChildItem -Path "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\"  -Include ($gameSaveExtensions | ForEach-Object { "*$_" }) -File -Recurse
    foreach ($file in $cloudFiles) {
        Rename-Item $file "$($file.Name).vdf"
    }
    cls
    echo "Backup restored successfully!"
    echo "Press any key to exit"
    timeout -1 | Out-Null
    exit
}


if ($database -ne $null) {
    if ($database.isOnline -eq $false) {
        [System.Windows.Forms.MessageBox]::Show( "Steam Cloud Sync is has been deactivated $($database.offlineReason) Your saves will not sync with the cloud in the meantime. This issue is being worked on.", "Cloud Sync Disabled", "Ok", "Warning" )
        Start-Process ".\$($gameExecutableName.TrimEnd(".exe")) Game.exe"
        timeout 5
        $i=0
        while ($(Get-Process "$($gameExecutableName.TrimEnd(".exe")) Game") -ne $null -or $i -ne 0 -and $i -ne 3) {
            timeout 1
            if ($(Get-Process "$($gameExecutableName.TrimEnd(".exe")) Game") -eq $null) {
                ++$i
            } else {
                $i=0
            }
        }
        [System.Windows.Forms.MessageBox]::Show( "Please remember that Steam Cloud Sync has been deactivated, your saves will not sync with the cloud. This issue is being worked on.")
        exit
    }
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if ($(Test-Path "$env:appdata\$cloudName\updateBackground.set") -and $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $true) {
        taskkill /f /im "$cloudName.exe" 2>$null | Out-Null
        del "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$cloudName.exe"
        Invoke-WebRequest $database.gameUpdateChecker -OutFile "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$cloudName.exe"
        Start-Process "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$cloudName.exe"
        if (!(Test-Path "$env:appdata\$cloudName\updateClient.set")) {
            [System.Windows.Forms.MessageBox]::Show( "Update has installed successfully", "Update Installed", "Ok", "Information" )
        }
        timeout 3
        explorer.exe "steam://launch/$steamAppID"
        exit
    }
    if ($(Get-Item -Path "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$cloudName.exe").VersionInfo.FileVersion -ne $database.latestUpdater) {
        $i=0
        $required = "true"
        while ($i -ne $database.allowedUpdater.Length) {
            if ($database.allowedUpdater[$i] -eq $(Get-Item -Path "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$cloudName.exe").VersionInfo.FileVersion) {
                $required = "false"
            }
            ++$i
        }
        if ($required -eq "false") {
            $choice = [System.Windows.Forms.MessageBox]::Show( "An update for Steam Cloud Sync is available, would you like to install this update?", "Update Available", "YesNo", "Question" )
        } else {
            [System.Windows.Forms.MessageBox]::Show( "An update for Steam Cloud Sync is available, this update is required $($database.disallowReason)", "Update Required", "Ok", "Warning" )
            $choice = "Yes"
        }
        if ($choice -eq "Yes") {
            "funnyword" | Set-Content "$env:appdata\$cloudName\updateBackground.set"
            if ($database.latestClient -ne $clientVersion) {
                "funnyword" | Set-Content "$env:appdata\$cloudName\updateClient.set"
            }
            try {
                Start-Process "$gamepath\$gameExecutableName" -Verb RunAs
            } catch {
                [System.Windows.Forms.MessageBox]::Show( "Update failed to installed, insufficient permissions", "Update Failed", "Ok", "Error" )
                del "$env:appdata\$cloudName\updateBackground.set"
                exit
            }
            exit
        }
    }
    if ($database.latestClient -ne $clientVersion) {
        $i=0
        $required = "true"
        while ($i -ne $database.allowedClient.Length) {
            if ($database.allowedClient[$i] -eq $clientVersion) {
                $required = "false"
            }
            ++$i
        }
        if (test-path "$env:appdata\$cloudName\updateClient.set") {
            $choice = "Yes"
            del "$env:appdata\$cloudName\updateClient.set"
        } else {
            if ($required -eq "false") {
                $choice = [System.Windows.Forms.MessageBox]::Show( "An update for Steam Cloud Sync is available, would you like to install this update?", "Update Available", "YesNo", "Question" )
            } else {
                [System.Windows.Forms.MessageBox]::Show( "An update for Steam Cloud Sync is available, this update is required $($database.disallowReason)", "Update Required", "Ok", "Warning" )
                $choice = "Yes"
            }
        }
        if ($choice -eq "Yes") {
            taskkill /f /im "$gameExecutableName" 2>$null | Out-Null
            del "$gamepath\$gameExecutableName"
            Invoke-WebRequest $database.updateLink -OutFile "$gamepath\$gameExecutableName"
            [System.Windows.Forms.MessageBox]::Show( "Update has installed successfully", "Update Installed", "Ok", "Information" )
            timeout 5
            explorer.exe "steam://launch/$steamAppID"
            exit
        }
    }
}
del "$env:appdata\$cloudName\updateClient.set"
del "$env:appdata\$cloudName\updateBackground.set"
cd $gamepath

if ((Get-Date).ToUniversalTime().Subtract((Get-Date "1/1/1970")).TotalSeconds - 604800 -gt $($Config.lastBackup)) {
    if ($gameSaveFolder -ne $null) {
        Remove-Item "$env:appdata\$cloudName\4" -Recurse -Force
        Rename-Item "$env:appdata\$cloudName\3" "$env:appdata\$cloudName\4"
        Rename-Item "$env:appdata\$cloudName\2" "$env:appdata\$cloudName\3"
        Rename-Item "$env:appdata\$cloudName\1" "$env:appdata\$cloudName\2"
        Copy-Item "$gameSaveFolder" "$env:appdata\$cloudName\1\" -Recurse -Force
    }
    if ($gameRegistryEntries -ne $null) {
        Remove-Item "$env:appdata\$cloudName\4.reg"
        Rename-Item "$env:appdata\$cloudName\3.reg" "$env:appdata\$cloudName\4.reg"
        Rename-Item "$env:appdata\$cloudName\2.reg" "$env:appdata\$cloudName\3.reg"
        Rename-Item "$env:appdata\$cloudName\1.reg" "$env:appdata\$cloudName\2.reg"
        reg export $gameRegistryEntries "$env:appdata\$cloudName\1.reg"
    }
    $config.lastBackup = (Get-Date).ToUniversalTime().Subtract((Get-Date "1/1/1970")).TotalSeconds
    $config | ConvertTo-Json | Format-Json | Set-Content "$env:appdata\$cloudName\CloudConfig.json"
}
$choice = "Yes"
foreach ($file in $cloudFiles) {
    if ($(Get-Item -Path "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\$($file.Name)").LastWriteTimeUtc -lt $(Get-Item -Path "$gameSaveFolder\$($file.BaseName)").LastWriteTimeUtc) {
        $choice = [System.Windows.Forms.MessageBox]::Show( "Sync conflict: The save files on your computer is newer then the files on Steam Cloud. Would you like to override the save files on your computer with the Steam Cloud files?", "Sync Conflict", "YesNo", "Warning" )
    }
}
$cloudFiles = Get-ChildItem -Path "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\" -Include ($gameSaveExtensions | ForEach-Object { "*$_.vdf" }) -File -Recurse
if ($choice -eq "Yes") {
    if ($gameSaveFolder -ne $null) {
        $clientFiles = Get-ChildItem -Path "$gameSaveFolder" -Include ($gameSaveExtensions | ForEach-Object { "*$_" }) -File -Recurse
        foreach ($file in $clientFiles) {
            Remove-Item "$file"
        }
        Get-ChildItem "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\" -recurse -Include ($gameSaveExtensions | ForEach-Object { "*$_.vdf" }) | `
        ForEach-Object {
            $targetFile = "$gameSaveFolder\" + $_.FullName.SubString("$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\".Length);
            New-Item -ItemType File -Path $targetFile -Force;
            Copy-Item $_.FullName -destination $targetFile
        }
        $clientFiles = Get-ChildItem -Path "$gameSaveFolder" -Include ($gameSaveExtensions | ForEach-Object { "*$_.vdf" }) -File -Recurse
        foreach ($file in $clientFiles) {
            Rename-Item $file $file.basename
        }
    }
    if ($gameRegistryEntries -ne $null) {
        reg import "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\regEntries.reg"
    }
}
Start-Process ".\$($gameExecutableName.TrimEnd(".exe")) Game.exe"
timeout 5
$i=0
while ($(Get-Process "$($gameExecutableName.TrimEnd(".exe")) Game") -ne $null -or $i -ne 0 -and $i -ne 3) {
    timeout 1
    if ($(Get-Process "$($gameExecutableName.TrimEnd(".exe")) Game") -eq $null) {
        ++$i
    } else {
        $i=0
    }
}
$cloudFiles = Get-ChildItem -Path "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\"  -Include ($gameSaveExtensions | ForEach-Object { "*$_" }) -File -Recurse
foreach ($file in $cloudFiles) {
    Remove-Item $file
}
$clientFiles = Get-ChildItem -Path "$gameSaveFolder" -Include ($gameSaveExtensions | ForEach-Object { "*$_" }) -File -Recurse
if ($gameRegistryEntries -ne $null) {
    reg export $gameRegistryEntries "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\regEntries.reg"
}
if ($gameSaveFolder -ne $null) {
    $cloudFiles = Get-ChildItem -Path "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\"  -Include ($gameSaveExtensions | ForEach-Object { "*$_.vdf" }) -File -Recurse
    Get-ChildItem $gameSaveFolder -recurse -Include ($gameSaveExtensions | ForEach-Object { "*$_" }) | `
    ForEach-Object {
        $targetFile = "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\" + $_.FullName.SubString($gameSaveFolder.Length);
        New-Item -ItemType File -Path $targetFile -Force;
        Copy-Item $_.FullName -destination $targetFile
    }
    foreach ($file in $cloudFiles) {
        Remove-Item $file
    }
    $cloudFiles = Get-ChildItem -Path "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\"  -Include ($gameSaveExtensions | ForEach-Object { "*$_" }) -File -Recurse
    foreach ($file in $cloudFiles) {
        Rename-Item $file "$($file.Name).vdf"
    }
}
