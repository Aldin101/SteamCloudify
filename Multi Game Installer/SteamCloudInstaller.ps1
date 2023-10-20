
$ProgressPreference = "SilentlyContinue"
$ErrorActionPreference = "SilentlyContinue"
$host.ui.RawUI.WindowTitle = "Steam Cloud Installer  |  Loading..."
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $false) {
    $fileLocation = Get-CimInstance Win32_Process -Filter "name = 'Steam Cloud Installer.exe'" -ErrorAction SilentlyContinue
    if ($fileLocation -eq $null) {
        echo "Unable request admin, please manually run the program as administrator to continue"
        echo "Press any key to exit"
        timeout -1 |out-null
        exit
    }
    taskkill /f /im "Steam Cloud Installer.exe" 2>$null | Out-Null
    $fileLocation1 = $fileLocation.CommandLine -replace '"', ""
    try {
        Start-Process "$filelocation1" -Verb RunAs
    } catch {
        echo "The Steam Cloud installer requires administrator privileges, please accept the admin prompt to continue"
        echo "Press any key to try again"
        timeout -1 | out-null
        try {
            Start-Process "$filelocation1" -Verb RunAs
        } catch {
            cls
            echo "The Steam Cloud installer cannot continue without administrator privileges"
            echo "Press any key to exit"
            timeout -1 | out-null
        }
    }
    exit
}
$fileLocation = Get-CimInstance Win32_Process -Filter "name = 'Steam Cloud Installer.exe'" -ErrorAction SilentlyContinue
if ($fileLocation -eq $null) {
    $host.ui.RawUI.WindowTitle = "Steam Cloud Installer | Version: [ERROR]"
} else {
    $fileLocation1 = $fileLocation.CommandLine -replace '"', ""
    $clientVersion = $(Get-Item -Path "$fileLocation1").VersionInfo.FileVersion
    $host.ui.RawUI.WindowTitle = "Steam Cloud Installer | Version: $clientVersion"
}

$database = Invoke-WebRequest "https://aldin101.github.io/Steam-Cloud/GameList.json" -UseBasicParsing
$database = $database.Content | ConvertFrom-Json
if ($database -eq $null) {
    echo "No internet connection, please connect to the internet and try again"
    echo "Press any key to exit"
    timeout -1 | Out-Null
    exit
}

echo "Welcome to Steam Cloud setup"
timeout -1
cls
echo "Welcome to Steam Cloud setup"
echo "Here is some important information:"
echo "Your saves will only be synced with other computers that have this tool installed"
echo "You can disable Steam Cloud on this computer for any game at any time by using this setup tool again"
echo "Steam Deck (and other non-windows devices) are unsupported at this time"
timeout -1
cls

$steamPath = (Get-ItemProperty -path 'HKCU:\SOFTWARE\Valve\Steam').steamPath
$ids = Get-ChildItem -Path "$steamPath\userdata\"
$steamid = [System.Collections.ArrayList](@())
foreach ($id in $ids) {
    if (test-path "$steamPath\userdata\$($id.basename)\inventorymsgcache\") {
        $steamid.add($id.basename) | Out-Null
    }
}

if ($steamid.count -eq 0) {
    echo "Unable to find your Steam ID"
    echo "Press any key to exit"
    timeout -1 | Out-Null
    exit
}

if ($steamid.count -gt 1) {
    foreach ($id in $steamid) {
        $lines = Get-Content "$steampath\userdata\$($id)\config\localconfig.vdf"
        $newLines = New-Object -TypeName 'System.Collections.Generic.List[string]' -ArgumentList $lines.Count
        $newLines.Add("{") | Out-Null
        foreach ($line in $lines) {
            $matchCollection = [regex]::Matches($line, '\s*(\".*?\")')
            if ($matchCollection.Count -eq 2) {
                $line = $line.Replace($matchCollection[0].Groups[1].Value, ("{0}:" -f $matchCollection[0].Groups[1].Value))
                $secondVal = $matchCollection[1].Groups[1].Value.Clone()
                [int64]$tryLongVal = 0
                if ([int64]::TryParse($secondVal.Replace('"', ''), [ref] $tryLongVal)) {
                    $secondVal = $secondVal.Replace('"', '')
                }
                $newLines.Add($line.Replace($matchCollection[1].Groups[1].Value, ("{0}," -f $secondVal))) | Out-Null
            } elseif ($matchCollection.Count -eq 1) {
                $newLines.Add($line.Replace($matchCollection[0].Groups[1].Value, ("{0}:" -f $matchCollection[0].Groups[1].Value))) | Out-Null
            } else {
                $newLines.Add($line) | Out-Null
            }
        }
        $newLines.Add("}") | Out-Null
        $joinedLine = $newLines -join "`n"
        $joinedLine = [regex]::Replace($joinedLine, '\}(\s*\n\s*\")', '},$1', "Multiline")
        $joinedLine = [regex]::Replace($joinedLine, '\"\,(\n\s*\})', '"$1', "Multiline")
        $startIndex = $joinedLine.IndexOf('"friends"') + 10
        $endIndex = $joinedLine.IndexOf('"Offline"', $startIndex)-3
        $validJson = $joinedLine.Substring($startIndex, $endIndex - $startIndex)
        $validJson = "$validJson"
        $validJson = $validJson -replace ',(\s*[\]}])', '$1'
        $data = ConvertFrom-Json $validJson

        $steamAccountName = [System.Collections.ArrayList](@())
        $steamAccountName.add($data.PersonaName) | Out-Null
    }
    echo "Multiple Steam accounts found, please select the one you would like to use"
    $i=1
    foreach ($name in $steamAccountName) {
        echo "[$i] $name"
        ++$i
    }
    $choice = Read-Host "What Steam account would you like to use?"
    $steamid = $steamid[$choice-1]
    if ($steamid -eq $null) {
        echo "That is not a valid Steam account"
        echo "Press any key to exit"
        timeout -1 | Out-Null
        exit
    }
}

$lines = Get-Content "$steamPath\steamapps\libraryfolders.vdf"
$newLines = New-Object -TypeName 'System.Collections.Generic.List[string]' -ArgumentList $lines.Count
$newLines.Add("{") | Out-Null
foreach ($line in $lines) {
    $matchCollection = [regex]::Matches($line, '\s*(\".*?\")')
    if ($matchCollection.Count -eq 2) {
        $line = $line.Replace($matchCollection[0].Groups[1].Value, ("{0}:" -f $matchCollection[0].Groups[1].Value))
        $secondVal = $matchCollection[1].Groups[1].Value.Clone()
        [int64]$tryLongVal = 0
        if ([int64]::TryParse($secondVal.Replace('"', ''), [ref] $tryLongVal)) {
            $secondVal = $secondVal.Replace('"', '')
        }
        $newLines.Add($line.Replace($matchCollection[1].Groups[1].Value, ("{0}," -f $secondVal))) | Out-Null
    } elseif ($matchCollection.Count -eq 1) {
        $newLines.Add($line.Replace($matchCollection[0].Groups[1].Value, ("{0}:" -f $matchCollection[0].Groups[1].Value))) | Out-Null
    } else {
        $newLines.Add($line) | Out-Null
    }
}
$newLines.Add("}") | Out-Null
$joinedLine = $newLines -join "`n"
$joinedLine = [regex]::Replace($joinedLine, '\}(\s*\n\s*\")', '},$1', "Multiline")
$joinedLine = [regex]::Replace($joinedLine, '\"\,(\n\s*\})', '"$1', "Multiline")
$joinedLine = $joinedLine -replace ',(\s*[\]}])', '$1'
$libaryfolders = $joinedLine | ConvertFrom-Json

if (!(test-path "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\disclaimerGiven.vdf")) {
    echo "DISCLAIMER: I am not responsible for any lost or corrupted save files caused by the use of this tool"
    echo "This tool is not intended as a backup, it is only intended to sync your saves between computers, please us other tools" "for backups such as GameSaveManager"
    echo "This tool takes many preventive measures to prevent loss of save data:"
    echo "Weekly backups, every week a local copy of your save data is made, this backup is stored locally and up to four backups" "are kept at a time"
    echo "Never deletes files, when a file is deleted on another computer and that change is reflected in Steam Cloud it is moved" "to the recycle bin on all other computers."
    echo "Save Conflicts, when the save files on your computer are newer then the save files in Steam Cloud you are alerted and" "can choose what to keep."
    echo ""
    echo "As with any piece of software, this tool is not perfect. While I have never experenced any issues with this tool it is" "always possible that something will happen, in the extremely unlikely event that" "something does happen you can try to restore a backup"
    echo "More information on the steps taken to prevent loss of save data, how to restore backups, and past data loss" "incidents can be found here: TEMP URL"
    timeout -1
    "funnyword" | Out-File "$steamPath\steamapps\common\Steam Controller Configs\$steamid\config\disclaimerGiven.vdf"
}

cls
$options = [System.Collections.ArrayList](@())
foreach ($game in $database.games) {
    if (test-path "$steamPath\steamapps\appmanifest_$($game.steamID).acf" -and $game.isOnline -eq $true) {
        $options.add($game) | out-null
    }
}
if ($libaryfolders.LibraryFolders.1 -ne $null) {
    $i=1
    while ($libaryfolders.LibraryFolders.$i -ne $null) {
        $steamapps = "$($libaryfolders.LibraryFolders."$i".path)\steamapps"
        foreach ($game in $database.games) {
            if (test-path "$steamapps\appmanifest_$($game.steamID).acf" -and $game.isOnline -eq $true) {
                $options.add($game) | out-null
            }
        }
        ++$i
    }
}

$i=1
foreach($game in $options) {
    echo "[$i] $($game.name)"
    ++$i
}
echo "[$i] Not listed? Add it!"
$choice = Read-Host "What game would you like to enable Steam Cloud for?"

if ($choice -eq $i) {
    echo "Making support for a new game is easy! If the game runs a common game engine like Unity or Unreal" "there are ready to use templates already available!"
    echo "You can find instructions to do so here: TEMP URL"
    echo "Press any key to open the URL and exit"
    timeout -1 | Out-Null
    exit
}

if ([int]$choice -gt $i-1 -or [int]$choice -lt 1) {
    echo "That is not a valid game"
    echo "Press any key to exit"
    timeout -1 | Out-Null
    exit
}

[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($options[$choice-1].installer.Script)) | iex