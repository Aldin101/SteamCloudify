if ($database -eq $null) {
    echo "You cannot run scripts individually"
    pause
    exit
}
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

if ($clientVersion -ne "2.0.1") {
    echo "Please update to 2.0.0 or higher, this feature is unavailable on your version"
    echo "Press any key to exit"
    timeout -1 | Out-Null
    exit
}
if (test-path "$env:appdata\GTTODLevelLoader\CloudConfig.json") {
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $false) {
        "funnyword" | Set-Content "$env:appdata\GTTODLevelLoader\SteamCloud.set"
        $fileLocation = Get-CimInstance Win32_Process -Filter "name = 'GTTOD Save Editor.exe'" -ErrorAction SilentlyContinue
        if ($fileLocation -eq $null) {
            echo "Unable to restart automaticly, please manually run the program as administrator to disable"
            echo "Press any key to exit"
            timeout -1 |out-null
            exit
        }
        taskkill /f /im "GTTOD Save Editor.exe" 2>$null | Out-Null
        $fileLocation1 = $fileLocation.CommandLine -replace '"', ""
        try {
            Start-Process "$filelocation1" -Verb RunAs
        } catch {
            echo "You need to accept the admin prompt to continue"
            echo "Press any key to exit"
            timeout -1 | out-null
        }
        exit
    }
    Remove-Item "$env:appdata\GTTODLevelLoader\SteamCloud.set"
    $userIsUpgrade = Read-Host "Would you like to disable Steam Cloud [y/n]"
    if ($userIsUpgrade -ne "n" -and $userIsUpgrade -ne "N" -and $userIsUpgrade -ne "no") {
        echo "Disabling cloud sync on this computer..."
        $CloudConfig = Get-Content "$env:appdata\GTTODLevelLoader\CloudConfig.json" | ConvertFrom-Json
        cd $CloudConfig.gamepath
        Remove-Item ".\Get To The Orange Door Game_Data" -Recurse
        Remove-Item ".\Get To The Orange Door.exe"
        Rename-Item ".\Get To The Orange Door Game.exe" "Get To The Orange Door.exe"
        taskkill /f /im "GTTODSteamCloud.exe" 2>$null | Out-Null
        Remove-Item "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\GTTODSteamCloud.exe"
        Remove-Item "$env:appdata\GTTODLevelLoader\CloudConfig.json"
        echo "Finished, press any key to exit"
        timeout -1 | Out-Null
        exit
    } else {
        echo "Press any key to exit"
        timeout -1 | Out-Null
        exit
    }
}



"funnyword" | Set-Content "$env:appdata\GTTODLevelLoader\SteamCloud.set"
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $false) {
    echo "Welcome to Steam Cloud setup"
    echo "Here are some things to know:"
    echo "Your saves will only be synced with other computers that have this tool installed"
    echo "When you install on a second (or third, fourth and so on) computer the saves from that computer will be added, not" "deleted"
    echo "You can disable Steam Cloud on this computer from the same menu to enabled it from"
    echo "Sometimes an update for this tool is required, when it is you will receive an UAC prompt when starting the game"
    echo "Steam Deck (and other non-windows devices) are unsupported at this time"
    echo ""
    echo "This tool requires administrator permissions to continue, so press any key once you are done reading and then accept" "the admin prompt"
    timeout -1 | Out-Null
    $fileLocation = Get-CimInstance Win32_Process -Filter "name = 'GTTOD Save Editor.exe'" -ErrorAction SilentlyContinue
    if ($fileLocation -eq $null) {
        echo "Unable to restart automaticly, please manually run the program as administrator to continue"
        echo "Press any key to exit"
        timeout -1 |out-null
        exit
    }
    taskkill /f /im "GTTOD Save Editor.exe" 2>$null | Out-Null
    $fileLocation1 = $fileLocation.CommandLine -replace '"', ""
    try {
        Start-Process "$filelocation1" -Verb RunAs
    } catch {
        echo "You need to accept the admin prompt to continue"
        echo "Press any key to exit"
        timeout -1 | out-null
    }
    exit
}
Remove-Item "$env:appdata\GTTODLevelLoader\SteamCloud.set"
echo "Setting up Steam Cloud..."
$steamPath = (Get-ItemProperty -path 'HKCU:\SOFTWARE\Valve\Steam').steamPath
$ids = Get-ChildItem -Path "$steamPath\userdata\"
$found = $false
foreach ($id in $ids) {
    $gameids = Get-ChildItem -Path "$steamPath\userdata\$($id.basename)\config\librarycache\"
    foreach ($gameid in $gameids) {
        if ($gameid.Name -eq "541200.json") {
            $steamid = $id.Name
            $found = $true
            break
        }
    }
    if ($found) {
        break
    }
}
if ($steamid -eq $null) {
    echo "Unable to find your Steam ID"
    echo "Press any key to exit"
    timeout -1 | Out-Null
    exit
}
$i=0
if (test-path "$steamPath\steamapps\common\Get To The Orange Door\Get To The Orange Door.exe") {
    $gamepath = "$steamPath\steamapps\common\Get To The Orange Door\"
} else {
    explorer.exe "steam://launch/541200"
    while ($gamepath -eq $null -and $i -lt 5) {
        $gamepath = Get-CimInstance Win32_Process -Filter "name = 'Get To The Orange Door.exe'" -ErrorAction SilentlyContinue
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
    $gamepath = $gamepath.TrimEnd("Get To The Orange Door.exe")
    taskkill /f /im "Get To The Orange Door.exe" 2>$null | Out-Null
}

cd $gamepath
Rename-Item ".\Get To The Orange Door.exe" "Get To The Orange Door Game.exe"
Copy-Item ".\Get To The Orange Door_Data" ".\Get To The Orange Door Game_Data" -Recurse
mkdir "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\541200"
Invoke-WebRequest $database.cloudSync -OutFile ".\Get To The Orange Door.exe"
Invoke-WebRequest $database.gameUpdateChecker -OutFile "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\GTTODSteamCloud.exe"
$files = Get-ChildItem -Path "$env:appdata\..\locallow\layers deep\get to the orange door\" -include "*.od2" -Recurse
foreach ($file in $files) {
    if (Test-Path "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\541200\$($file.BaseName).od2.vdf") {
        Copy-Item $file "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\541200\$($file.BaseName)-$env:computername.od2.vdf"
    } else {
        Copy-Item $file "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\541200\$($file.BaseName).od2.vdf"
    }
}
$CloudConfig = @{}
$CloudConfig.Add("gamepath",$gamepath)
$CloudConfig.Add("steampath",$steamPath)
$CloudConfig.Add("steamID",$steamid)
$CloudConfig.Add("CloudSyncDownload", $database.cloudSync)
$CloudConfig | ConvertTo-Json -depth 32 | Format-Json | Set-Content "$env:appdata\GTTODLevelLoader\CloudConfig.json"
Start-Process "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\GTTODSteamCloud.exe"
cls
echo "Steam Cloud setup has compleated, remember to install on other computers to sync saves"
echo "Press any key to exit"
timeout -1 |Out-Null