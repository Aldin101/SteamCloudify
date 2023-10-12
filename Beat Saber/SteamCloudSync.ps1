# Game specific start----------------------------------------------------------------------------------------------------------------------------
$gameName = "Beat Saber" # name of the game
$steamAppID = "620980" # you can find this on https://steamdb.info, it should be structured like this, "NUMBER"
$gameExecutableName = "Beat Saber.exe" # executable name should be structured, "GAME NAME.exe"
$gameFolderName = "Beat Saber" # install folder should be structured like this, "GAME FOLDER NAME" just give the folder name
$gameSaveFolder = "$env:appdata\..\Hyperbolic Magnetism\Beat Saber" # the folder where saves are located, if the game does not store save files in a folder comment this out-
# -If the game does it should be structured like this "FullFolderPath". Make sure not to include user/computer specific information and use-
# -enviorment varables instead. Most Unity games store files at "$env:appdata\..\LocalLow\[COMPANY NAME]\[GAME NAME]"
$gameSaveExtentions = ".dat" # the game save folder sometimes contains information other than just game saves, and some-
# -files should not be uploaded to Steam Cloud. If there is one extention format it like this ".[EXTENTION]". If there are more that one format it like this
# "[EXTENTION1]", "[EXTENTION2]", "[EXTENTION3]"
# $gameRegistryEntries = ".dat" # the location where registry entries are located, if the game does not store save files in the registry-
# - comment this out. If the game does it should be structured like this "HKCU\SOFTWARE\[COMPANY NAME]\[GAME NAME]".

$file = Invoke-WebRequest "https://aldin101.github.io/Steam-Cloud/Beat%20Saber/Beat%20Saber.json" -UseBasicParsing
# The URL where the installer database can be found so that this installer knows where to download the cloud sync util and background task

# Game specific end------------------------------------------------------------------------------------------------------------------------------

$cloudName = "$gameName Steam Cloud"
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
$clientVersion = "1.0.0"
$database = $file.Content | ConvertFrom-Json
$config = Get-Content "$env:appdata\$cloudName\CloudConfig.json" | ConvertFrom-Json
$steamPath = $config.steamPath
$steamid = $config.steamID
$gamepath = $config.gamepath
if ($database -ne $null) {
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
            [System.Windows.Forms.MessageBox]::Show( "An update for Steam Cloud Sync is available, this update is required to continue due to a major bug in your version.", "Update Available", "Ok", "Information" )
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
                [System.Windows.Forms.MessageBox]::Show( "An update for Steam Cloud Sync is available, this update is required to continue due to a major bug in your version.", "Update Available", "Ok", "Information" )
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
$cloudFiles = Get-ChildItem -Path "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\" -Include ($gameSaveExtentions | ForEach-Object { "*$_.vdf" }) -File -Recurse
$clientFiles = Get-ChildItem -Path "$gameSaveFolder" -Include ($gameSaveExtentions | ForEach-Object { "*$_" }) -File -Recurse
foreach ($file in $clientFiles) {
    if (!(Test-Path "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\$($file.BaseName).od2.vdf")) {
        $shell = new-object -comobject "Shell.Application"
        $item = $shell.Namespace(0).ParseName("$file")
        $item.InvokeVerb("delete")
    }
}
foreach ($file in $cloudFiles) {
    if ($(Get-Item -Path "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\$($file.Name)").LastWriteTimeUtc -lt $(Get-Item -Path "$gameSaveFolder\$($file.BaseName)").LastWriteTimeUtc) {
        $choice = [System.Windows.Forms.MessageBox]::Show( "Sync conflict: The version of $('"')$($($file.BaseName).TrimEnd(".od2"))$('"') on your computer is newer then the version on Steam Cloud. Would you like to override the version on your computer with the Steam Cloud version?", "Sync Conflict", "YesNo", "Warning" )
    } else {
        $choice = "Yes"
    }
    if ($choice -eq "Yes") {
        Copy-Item $file "$gameSaveFolder\$($file.BaseName)"
    }
}
if ($gameRegistryEntries -ne $null) {
    reg import "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\regEntries.reg"
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
$cloudFiles = Get-ChildItem -Path "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\"  -Include ($gameSaveExtentions | ForEach-Object { "*$_.vdf" }) -File -Recurse
foreach ($file in $cloudFiles) {
    Remove-Item $file
}
$clientFiles = Get-ChildItem -Path "$gameSaveFolder" -Include ($gameSaveExtentions | ForEach-Object { "*$_" }) -File -Recurse
if ($gameRegistryEntries -ne $null) {
    reg export $gameRegistryEntries "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\regEntries.reg"
}
foreach ($file in $clientFiles) {
    mkdir "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\$($file.VersionInfo.FileName.TrimStart($gameSaveFolder).TrimEnd($file.name))"
    Copy-Item $file "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\$($file.name).vdf"
}