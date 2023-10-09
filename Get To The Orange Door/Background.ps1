$config = Get-Content "$env:appdata\GTTODLevelLoader\CloudConfig.json" | ConvertFrom-Json
$steamPath = $config.steamPath
$steamid = $config.steamID
$gamepath = $config.gamepath
cd $gamepath
$exehash=Get-FileHash -Algorithm MD5 "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\GTTODSteamCloud.exe"
while (1) {
    while (!(Test-Path $gamepath\..\..\Downloading\541200)) {
        Start-Sleep -s 3
        if (!(Test-Path $gamepath\..\..\appmanifest_541200.acf)) {
            $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
            if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $false) {
                Start-Process "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\GTTODSteamCloud.exe" -Verb runAs
                exit
            }
            taskkill /f /im "GTTODSteamCloud.exe" 2>$null | Out-Null
            del "$env:appdata\GTTODLevelLoader\CloudConfig.json"
            del "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\GTTODSteamCloud.exe"
            cd ..
            del "$gamepath\" -Recurse
            exit
        }
        if ($(Get-FileHash -Algorithm MD5 "$env:appdata\Microsoft\Windows\Start Menu\Programs\Startup\GTTODSteamCloud.exe").Hash -ne $exehash.Hash) {
            exit
        }
    }
    while (Test-Path $gamepath\..\..\Downloading\541200) {
        Start-Sleep -s 1
    }
    Start-Sleep -s 3
    Remove-Item ".\Get To The Orange Door Game_Data" -Recurse
    Remove-Item ".\Get To The Orange Door Game.exe"
    taskkill /f /im "Get To The Orange Door.exe"
    Rename-Item ".\Get To The Orange Door.exe" "Get To The Orange Door Game.exe"
    Invoke-WebRequest $config.CloudSyncDownload -OutFile ".\Get To The Orange Door.exe"
    Copy-Item ".\Get To The Orange Door_Data" ".\Get To The Orange Door Game_Data" -Recurse
}