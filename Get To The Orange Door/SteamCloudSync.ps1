[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
$clientVersion = "2.0.2"
$file = Invoke-WebRequest https://aldin101.github.io/GTTODLevelEdit/SteamCloudDatabase.json -UseBasicParsing
$database = $file.Content | ConvertFrom-Json
$config = Get-Content "$env:appdata\GTTODLevelLoader\CloudConfig.json" | ConvertFrom-Json
$steamPath = $config.steamPath
$steamid = $config.steamID
$gamepath = $config.gamepath
if ($database -ne $null) {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if ($(Test-Path "$env:appdata\GTTODLevelLoader\updateBackground.set") -and $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $true) {
        taskkill /f /im "GTTODSteamCloud.exe" 2>$null | Out-Null
        del "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\GTTODSteamCloud.exe"
        Invoke-WebRequest $database.gameUpdateChecker -OutFile "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\GTTODSteamCloud.exe"
        Start-Process "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\GTTODSteamCloud.exe"
        if (!(Test-Path "$env:appdata\GTTODLevelLoader\updateClient.set")) {
            [System.Windows.Forms.MessageBox]::Show( "Update has installed successfully", "Update Installed", "Ok", "Information" )
        }
        timeout 3
        explorer.exe "steam://launch/541200"
        exit
    }
    if ($(Get-Item -Path "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\GTTODSteamCloud.exe").VersionInfo.FileVersion -ne $database.latestUpdater) {
        $i=0
        $required = "true"
        while ($i -ne $database.allowedUpdater.Length) {
            if ($database.allowedUpdater[$i] -eq $(Get-Item -Path "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\GTTODSteamCloud.exe").VersionInfo.FileVersion) {
                $required = "false"
            }
            ++$i
        }
        if ($required -eq "false") {
            $choice = [System.Windows.Forms.MessageBox]::Show( "An update for GTTOD Steam Cloud is available, would you like to install this update?", "Update Available", "YesNo", "Question" )
        } else {
            [System.Windows.Forms.MessageBox]::Show( "An update for GTTOD Steam Cloud is available, this update is required to continue due to a major bug in your version.", "Update Available", "Ok", "Information" )
            $choice = "Yes"
        }
        if ($choice -eq "Yes") {
            "funnyword" | Set-Content "$env:appdata\GTTODLevelLoader\updateBackground.set"
            if ($database.latestClient -ne $clientVersion) {
                "funnyword" | Set-Content "$env:appdata\GTTODLevelLoader\updateClient.set"
            }
            try {
                Start-Process "$gamepath\Get To The Orange Door.exe" -Verb RunAs
            } catch {
                [System.Windows.Forms.MessageBox]::Show( "Update failed to installed, insufficient permissions", "Update Failed", "Ok", "Error" )
                del "$env:appdata\GTTODLevelLoader\updateBackground.set"
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
        if (test-path "$env:appdata\GTTODLevelLoader\updateClient.set") {
            $choice = "Yes"
            del "$env:appdata\GTTODLevelLoader\updateClient.set"
        } else {
            if ($required -eq "false") {
                $choice = [System.Windows.Forms.MessageBox]::Show( "An update for GTTOD Steam Cloud is available, would you like to install this update?", "Update Available", "YesNo", "Question" )
            } else {
                [System.Windows.Forms.MessageBox]::Show( "An update for GTTOD Steam Cloud is available, this update is required to continue due to a major bug in your version.", "Update Available", "Ok", "Information" )
                $choice = "Yes"
            }
        }
        if ($choice -eq "Yes") {
            taskkill /f /im "Get To The Orange Door.exe" 2>$null | Out-Null
            del "$gamepath\Get To The Orange Door.exe"
            Invoke-WebRequest $database.updateLink -OutFile "$gamepath\Get To The Orange Door.exe"
            [System.Windows.Forms.MessageBox]::Show( "Update has installed successfully", "Update Installed", "Ok", "Information" )
            timeout 5
            explorer.exe "steam://launch/541200"
            exit
        }
    }
}
del "$env:appdata\GTTODLevelLoader\updateClient.set"
del "$env:appdata\GTTODLevelLoader\updateBackground.set"
cd $gamepath
$cloudFiles = Get-ChildItem -Path "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\541200\" -include "*.od2.vdf" -Recurse
$clientFiles = Get-ChildItem -Path "$env:appdata\..\locallow\layers deep\get to the orange door\" -include "*.od2" -Recurse
foreach ($file in $clientFiles) {
    if (!(Test-Path "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\541200\$($file.BaseName).od2.vdf")) {
        $shell = new-object -comobject "Shell.Application"
        $item = $shell.Namespace(0).ParseName("$file")
        $item.InvokeVerb("delete")
    }
}
foreach ($file in $cloudFiles) {
    if ($(Get-Item -Path "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\541200\$($file.Name)").LastWriteTimeUtc -lt $(Get-Item -Path "$env:appdata\..\locallow\layers deep\get to the orange door\$($file.BaseName)").LastWriteTimeUtc) {
        $choice = [System.Windows.Forms.MessageBox]::Show( "Sync conflict: The version of $('"')$($($file.BaseName).TrimEnd(".od2"))$('"') on your computer is newer then the version on Steam Cloud. Would you like to override the version on your computer with the Steam Cloud version?", "Sync Conflict", "YesNo", "Warning" )
    } else {
        $choice = "Yes"
    }
    if ($choice -eq "Yes") {
        Copy-Item $file "$env:appdata\..\locallow\layers deep\get to the orange door\$($file.BaseName)"
    }
}
Start-Process '.\Get To The Orange Door Game.exe'
timeout 5
$i=0
while ($(Get-Process "Get To The Orange Door Game") -ne $null -or $i -ne 0 -and $i -ne 3) {
    timeout 1
    if ($(Get-Process "Get To The Orange Door Game") -eq $null) {
        ++$i
    } else {
        $i=0
    }
}
$cloudFiles = Get-ChildItem -Path "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\541200\" -include "*.od2.vdf" -Recurse
foreach ($file in $cloudFiles) {
    Remove-Item $file
}
$clientFiles = Get-ChildItem -Path "$env:appdata\..\locallow\layers deep\get to the orange door\" -include "*.od2" -Recurse
foreach ($file in $clientFiles) {
    Copy-Item $file "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\541200\$($file.BaseName).od2.vdf"
}