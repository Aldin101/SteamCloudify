$database = Invoke-WebRequest "https://aldin101.github.io/Steam-Cloud/GameList.json" -UseBasicParsing
$database = $database.Content | ConvertFrom-Json
if ($database -eq $null) {
    echo "No internet connection, please connect to the ineternet and try again"
    echo "Press any key to exit"
    timeout -1 | Out-Null
    exit
}

echo "Welcome to Steam Cloud setup"
echo "Here are some things to know:"
echo "This tool is not inteded as a backup, it is only inteded to sync your saves between computers, please us other tools for" "backups such as GameSaveManager"
echo "Your saves will only be synced with other computers that have this tool installed"
echo "When you install on another computer you will have the choice to download your saves from the cloud or upload your saves" "to the cloud, once you choose to override saves on a computer or the cloud you will not be able to recover the" "overritten saves"
echo "You can disable Steam Cloud on this computer for any game by using this setup tool again"
echo "Steam Deck (and other non-windows devices) are unsupported at this time"
timeout -1
cls

$steamPath = (Get-ItemProperty -path 'HKCU:\SOFTWARE\Valve\Steam').steamPath
$ids = Get-ChildItem -Path "$steamPath\userdata\"
$found = $false
foreach ($id in $ids) {
    $gameids = Get-ChildItem -Path "$steamPath\userdata\$($id.basename)\config\librarycache\"
    foreach ($gameid in $gameids) {
        if (test-path "$steamPath\userdata\$($id.basename)\inventorymsgcache\") {
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
$i=1
$options = [System.Collections.ArrayList](@())
foreach ($game in $database.games) {
    if (test-path "$steamPath\steamapps\appmanifest_$($game.steamID).acf") {
        echo "[$i] $($game.name)"
        $options.add($game) | out-null
        ++$i
    }
}
echo "[$i] Not listed? Add one!"
$choice = Read-Host "What game would you like to enable Steam Cloud for?"

if ($choice -eq $i) {
    echo "Making support for a new game is easy! If the game runs a common game engine like Unity or Unreal" "there are ready to use templates already availble!"
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

echo "Steam Cloud for $($options[$choice-1].name) has been enabled! Remeber to install on other computers" "to sync your saves"