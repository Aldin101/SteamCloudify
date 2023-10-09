$database = Invoke-WebRequest "https://aldin101.github.io/Steam-Cloud/GameList.json" -UseBasicParsing
$database = $database.Content | ConvertFrom-Json
if ($database -eq $null) {
    echo "No internet connection, please connect to the ineternet and try again"
    echo "Press any key to exit"
    timeout -1 | Out-Null
    exit
}

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
    if (test-path "$steamPath\userdata\$steamid\config\librarycache\$($game.steamID).json") {
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
    echo "Press any key to exit"
    timeout -1 | Out-Null
    exit
}