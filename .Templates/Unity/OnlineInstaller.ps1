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
        if (test-path "$env:appdata\$cloudName\1\") {
            echo "This tool made backups of your save data, they are not needed anymore and can be deleted."
            echo "Deleting them will have no effect on your saves stored locally, stored on other computer or in Steam Cloud."
            $choice = Read-Host "Would you like to delete local save backups? [Y/n]"
            if ($choice -eq "n" -or $choice -eq "N" -or $choice -eq "no") {
                Move-Item "$env:appdata\$cloudName\" "$env:userprofile\desktop\Save Backups for $gamename\" -Recurse -Force -Exclude "CloudConfig.json"
            }
        }
        cls
        echo "Disabling cloud sync on this computer..."
        $CloudConfig = Get-Content "$env:appdata\$cloudName\CloudConfig.json" | ConvertFrom-Json
        cd $CloudConfig.gamepath
        Remove-Item ".\$($gameExecutableName.TrimEnd(".exe")) Game_Data" -Recurse
        Remove-Item ".\$gameExecutableName"
        Rename-Item ".\$($gameExecutableName.TrimEnd(".exe")) Game.exe" "$gameExecutableName"
        taskkill /f /im "$cloudName.exe" 2>$null | Out-Null
        Remove-Item "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$cloudName.exe"
        Remove-Item "$env:appdata\$cloudName\" -Force -Recurse
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
            echo "Setting up Steam Cloud..."
            break
        }
        if ($choice -eq 2) {
            echo "Setting up Steam Cloud..."
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
        echo "Setting up Steam Cloud..."
    }
} else {
    $choice = 1
}
mkdir "$env:appdata\$gamename Steam Cloud\" | out-null
Rename-Item ".\$gameExecutableName" "$($gameExecutableName.TrimEnd(".exe")) Game.exe"
Copy-Item ".\$($gameExecutableName.TrimEnd(".exe"))_Data" ".\$($gameExecutableName.TrimEnd(".exe")) Game_Data" -Recurse
mkdir "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID" | out-null
Invoke-WebRequest $database.updateLink -OutFile ".\$gameExecutableName" 
Invoke-WebRequest $database.gameUpdateChecker -OutFile "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$cloudName.exe"
if ($choice -eq 1) {
    if ($gameSaveFolder -ne $null) {
        Get-ChildItem $gameSaveFolder -recurse -Include ($gameSaveExtensions | ForEach-Object { "*$_" }) | `
        ForEach-Object {
            $targetFile = "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\$steamAppID\" + $_.FullName.SubString($gameSaveFolder.Length);
            New-Item -ItemType File -Path $targetFile -Force;
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
$CloudConfig.Add("CloudSyncDownload", $database.updateLink)
$CloudConfig | ConvertTo-Json -depth 32 | Format-Json | Set-Content "$env:appdata\$cloudName\CloudConfig.json"
New-Item -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$cloudName
New-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$cloudName -Name "DisplayIcon" -Value "$gamepath\$gameExecutableName" -PropertyType "String" -Force | Out-Null
New-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$cloudName -Name "DisplayName" -Value "$cloudName" -PropertyType "String" -Force | Out-Null
New-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$cloudName -Name "DisplayVersion" -Value $(Get-Item $gamepath\$gameExecutableName).VersionInfo.FileVersion -PropertyType "String" -Force | Out-Null
$sizeInBytes = (Get-ChildItem -Path $gamepath\$($gameExecutableName.TrimEnd('.exe'))_data -Recurse -File | Measure-Object -Property Length -Sum).Sum
$sizeInGB = [math]::Round($sizeInBytes / 1KB, 2)
$sizeInDWORD = [System.Convert]::ToUInt32($sizeInGB)
New-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$cloudName -Name "EstimatedSize" -Value $sizeInDWORD -PropertyType "DWORD" -Force | Out-Null
New-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$cloudName -Name "InstallDate" -Value $(Get-Date -Format "M/d/yyyy") -PropertyType "String" -Force | Out-Null
New-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$cloudName -Name "InstallLocation" -Value $gamePath -PropertyType "String" -Force | Out-Null
New-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$cloudName -Name "NoRepair" -Value 1 -PropertyType "DWORD" -Force | Out-Null
New-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$cloudName -Name "Publisher" -Value "Aldin101" -PropertyType "String" -Force | Out-Null
New-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$cloudName -Name "UninstallString" -Value "$gamePath\$gameExecutableName /C:`"powershell -executionPolicy bypass -windowstyle hidden -command set-content -value 1 $env:userprofile\uninstall.set; .\SteamCloudSync.ps1`"" -PropertyType "String" -Force | Out-Null
New-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$cloudName -Name "ModifyPath" -Value "$gamePath\$gameExecutableName /C:`"cmd /c powershell -executionPolicy bypass -command set-content -value 1 $env:userprofile\modify.set; .\SteamCloudSync.ps1`"" -PropertyType "String" -Force | Out-Null

Start-Process "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\$gameName Steam Cloud.exe"
cls
echo "Steam Cloud setup has completed, remember to install on other computers to sync saves"
echo "Press any key to exit"
timeout -1 |Out-Null