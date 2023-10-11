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
cd $script:PSScriptRoot
$Config = Get-Content .\BuildTool.json | ConvertFrom-Json
while (1) {
    echo "[1] Build database"
    echo "[2] Build multi game installer"
    echo "[3] Build single game installer"
    echo "[4] Build Steam Cloud Runtime executable"
    echo "[5] Build Steam Cloud executable"
    $selection = Read-Host "What would you like to do"
    if ($selection -eq 1) {
        foreach ($games in $config.games) {
            $s = Get-Content ".\$($games.name)\OnlineInstaller.ps1" | Out-String
            $j = [PSCustomObject]@{
              "Script" =  [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($s))
            }
            $games.installer = $j
        }
        $Config | ConvertTo-Json -depth 32 | Format-Json | Set-Content ".\Multi Game Installer\GameList.json"
        $Config = Get-Content .\BuildTool.json | ConvertFrom-Json
    }

    if ($selection -eq 2) {
        $sed = Get-Content ".\Multi Game Installer\SteamCloudInstaller.sed"
        $sed.Split([Environment]::NewLine)
        $sed[36] = "TargetName=$(Get-Location)\Multi Game Installer\SteamCloudInstaller.exe"
        $sed[44] = "SourceFiles0=$(Get-Location)\Multi Game Installer"
        $sed | Set-Content "C:\SteamCloudInstaller.sed"
        $h=Get-Location
        cls
        try {
            Start-Process "iexpress.exe" "C:\SteamCloudInstaller.sed" -Verb runAs
        } catch {
            echo "You need to accept the admin prompt"
            timeout -1
        }
    }

    if ($selection -eq 3) {
        if (test-path "$env:appdata\GTTODLevelLoader\database.json") {
            del "$env:appdata\GTTODLevelLoader\database.json"
            echo "Local database disabled, to re-enable simply build the database again"
        } else {
            echo "You don't have a local databse to delete"
        }
        timeout -1
    }

    if ($selection -eq 4) {
        $sed = Get-Content .\GTTODLevelLoader.SED
        $sed.Split([Environment]::NewLine)
        $sed[36] = "TargetName=$(Get-Location)\GTTOD Save Editor.exe"
        $sed[44] = "SourceFiles0=$(Get-Location)\"
        $sed | Set-Content .\GTTODLevelLoader.SED
        $h=Get-Location
        cls
        try {
            Start-Process "iexpress.exe" "/Q /N $($h.Path)\GTTODLevelLoader.sed" -Verb runAs
        } catch {
            echo "You need to accept the admin prompt"
            timeout -1
        }
    }
    if ($selection -eq 5) {
        $sed = Get-Content ".\SteamCloud\SteamCloudSync.sed"
        $sed.Split([Environment]::NewLine)
        $sed[36] = "TargetName=$(Get-Location)\SteamCloud\SteamCloudSync.exe"
        $sed[44] = "SourceFiles0=$(Get-Location)\SteamCloud"
        $sed | Set-Content ".\SteamCloud\SteamCloudSync.sed"
        $h=Get-Location
        cls
        try {
            Start-Process "iexpress.exe" "/Q /N $($h.Path)\SteamCloud\SteamCloudSync.sed" -Verb runAs
        } catch {
            echo "You need to accept the admin prompt"
            timeout -1
        }
        $sed = Get-Content ".\SteamCloud\Background.sed"
        $sed.Split([Environment]::NewLine)
        $sed[36] = "TargetName=$(Get-Location)\SteamCloud\GTTODSteamCloud.exe"
        $sed[45] = "SourceFiles0=$(Get-Location)\SteamCloud"
        $sed | Set-Content ".\SteamCloud\Background.sed"
        $h=Get-Location
        cls
        try {
            Start-Process "iexpress.exe" "/Q /N $($h.Path)\SteamCloud\Background.sed" -Verb runAs
        } catch {
            echo "You need to accept the admin prompt"
            timeout -1
        }
    }
    $Config | ConvertTo-Json -depth 32 | Format-Json | Set-Content .\BuildTool.json
    $Config = Get-Content .\BuildTool.json | ConvertFrom-Json
    cls
}