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

$database = Get-Content .\database.json | ConvertFrom-Json
if (Test-Path .\BuildTool.json) {
    $Config = Get-Content .\BuildTool.json | ConvertFrom-Json
    cls
} else {
    $firstName = Read-Host "Please name your first branch"
    cls
    $mainMenuFile = Read-Host "Please enter the main menu filename for this branch"
    if (!(Test-Path ./$mainMenuFile)) {
        echo "That file does not exist"
        echo "Press any key to exit"
        timeout -1 | Out-Nu1ll
        exit
    }
    $fileOne = Read-Host "Please enter the file name for the first menu option"
    if (!(Test-Path ./$fileOne)) {
        echo "That file does not exist"
        echo "Press any key to exit"
        timeout -1 | Out-Null
        exit
    }
    $Config = @{}
    $Config.Add("Version","1.0.0") | Out-Null
    $branches = New-Object System.Collections.ArrayList
    $files = New-Object System.Collections.ArrayList
    $files.Add($mainMenuFile) | Out-Null
    $files.Add($fileOne) | Out-Null
    $branches.Add([PSCustomObject]@{"branchName"="$firstName"; "files"=$files}) | Out-Null
    $Config.Add("branches", $branches) | Out-Null
    $Config | ConvertTo-Json -depth 32 | Format-Json | Set-Content .\BuildTool.json
    $Config = Get-Content .\BuildTool.json | ConvertFrom-Json
    cls
}
while (1) {
    echo "[1] Build database"
    echo "[2] Edit database"
    echo "[3] Disable local database"
    echo "[4] Build GTTOD Save Editor executable"
    echo "[5] Build GTTOD Steam Cloud executables"
    $selection = Read-Host "What would you like to do"
    if ($selection -eq 1) {
        foreach ($branch in $database.branch) {
            $database.PSobject.Properties.Remove($branch)
        }
        $database.PSobject.Properties.Remove("branch")
        $branchList = New-Object System.Collections.ArrayList
        foreach ($branch in $Config.branches.branchName) {
            $branchList.Add($branch) | Out-Null
        }
        echo "Building scripts..."
        $database | Add-Member -MemberType NoteProperty -Name "branch" -Value $branchList
        foreach ($branch in $Config.branches) {
            $newBranch = New-Object System.Collections.ArrayList
            foreach ($file in $branch.files) {
                $s = Get-Content $file | Out-String
                $j = [PSCustomObject]@{
                    "Script" =  [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($s))
                }
                $newBranch.Add($j) | Out-Null
            }
            $database | Add-Member -MemberType NoteProperty -Name $branch.branchName -Value $newBranch
        }
        $database.serverVersion = "LOCAL DATABASE BUILT ON $(Get-Date -DisplayHint Time)"
        $database | ConvertTo-Json -depth 32 | Format-Json | Set-Content .\database.json
        $database | ConvertTo-Json -depth 32 | Format-Json | Set-Content "$env:APPDATA\GTTODLevelLoader\database.json"
    }

    if ($selection -eq 2) {
        $i=1
        cls
        foreach ($branch in $Config.branches.branchName) {
            echo "[$i] $branch"
            ++$i
        }
        echo "[$i] New branch"
        [int]$branchSelection = Read-Host "What branch would you like to edit"
        if ($branchSelection -eq $i) {
            cls
            $newName = Read-Host "What would you like to name this branch"
            cls
            $mainMenuFile = Read-Host "Please enter the main menu filename for this branch"
            if (!(Test-Path ./$mainMenuFile)) {
                echo "That file does not exist"
                echo "Press any key to exit"
                timeout -1 | Out-Null
                exit
            }
            cls
            $fileOne = Read-Host "Please enter the file name for the first menu option"
            if (!(Test-Path ./$fileOne)) {
                echo "That file does not exist"
                echo "Press any key to exit"
                timeout -1 | Out-Null
                exit
            }
            $branchList = [System.Collections.ArrayList]($Config.branches)
            $files = New-Object System.Collections.ArrayList
            $files.Add($mainMenuFile) | Out-Null
            $files.Add($fileOne) | Out-Null
            $branchList.Add([PSCustomObject]@{"branchName"="$newName"; "files"=$files}) | Out-Null
            $Config.branches = $branchList.ToArray()
        } else {
            cls
            echo "[1] Add file to branch"
            echo "[2] Remove file from branch"
            echo "[3] Adjust a file's index in branch"
            echo "[4] Delete branch"
            $settingsSelection = Read-Host "What would you like to do?"
            cls
            if ($settingsSelection -eq 1) {
                $filesToAdd = Read-Host "What file would you like to add to the branch"
                $filesToAdd = $filesToAdd -replace " ", ""
                $filesToAdd = $filesToAdd -split ","
                foreach($filename in $filesToAdd) {
                    if (!(Test-Path ./$filename)) {
                        echo "One of the files you entered does not exist"
                        echo "Press any key to exit"
                        timeout -1 | Out-Null
                        exit
                    }
                }
                $fileList = [System.Collections.ArrayList]($Config.branches[$branchSelection-1].files)
                foreach ($file in $filesToAdd) {
                    $fileList.Add($file) | Out-Null
                }
                $Config.branches[$branchSelection-1].files = $fileList.ToArray()
            }


            if ($settingsSelection -eq 2) {
                $i=1
                foreach($file in $Config.branches[$branchSelection-1].files){
                    echo "[$i] $file"
                    ++$i
                }
                $fileSelection = Read-Host "What file would you like to remove"

                if ($fileSelection -ne 1) {
                $fileList = [System.Collections.ArrayList]($Config.branches[$branchSelection-1].files)
                $fileList.Remove($fileList[$fileSelection-1])
                $Config.branches[$branchSelection-1].files = $fileList.ToArray()
                } else {
                    echo "You can't remove the main menu file from a branch"
                    timeout -1
                }
            }

            if ($settingsSelection -eq 3) {
                $fileList = [System.Collections.ArrayList]($Config.branches[$branchSelection-1].files)
                $i=1
                cls
                foreach($file in $Config.branches[$branchSelection-1].files){
                    echo "[$i] $file"
                    ++$i
                }
                $fileSelection = Read-Host "What file would you like to move"
                $fileList.Remove($fileList[$fileSelection-1])
                cls
                if ($fileSelection -ne 1) {
                    $i=1
                    foreach($file in $fileList){
                        echo "[$i] $file"
                        ++$i
                    }
                    $position = Read-Host "What file would you like to move $($Config.branches[$branchSelection-1].files[$fileSelection-1]) below"
                    $newFileList = New-Object System.Collections.ArrayList
                    $i=0
                    while ([int]$position -gt $i) {
                        $newFileList.Add($fileList[$i]) | Out-Null
                        ++$i
                    }
                    $newFileList.Add($Config.branches[$branchSelection-1].files[$fileSelection-1]) | Out-Null
                    $Config.branches[$branchSelection-1].PSobject.Properties.Remove("files")
                    while ($fileList.Count -gt $i) {
                        $newFileList.Add($fileList[$i]) | Out-Null
                        ++$i
                    }
                    $Config.branches[$branchSelection-1] | Add-Member -MemberType NoteProperty -Name "files" -Value $newFileList
                } else {
                    echo "You can't move the main menu file"
                    timeout -1
                }
            }
            if ($settingsSelection -eq 4) {
                $fileSelection = Read-Host "Are you sure you want to remove this branch [y/N]"
                if ($fileSelection -eq "y" -or $fileSelection -eq "Y" -or $fileSelection -eq "yes") {
                    if ($Config.branches.Count -ne 1) {
                    $fileList = [System.Collections.ArrayList]($Config.branches)
                    $fileList.Remove($Config.branches[$branchSelection-1])
                    $Config.branches = $fileList.ToArray()
                    } else {
                        echo "You need to have at least one branch"
                        timeout -1
                    }
                }
            }
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
        $sed[26] = "TargetName=$(Get-Location)\GTTOD Save Editor.exe"
        $sed[34] = "SourceFiles0=$(Get-Location)\"
        $sed | Set-Content .\GTTODLevelLoader.SED
        $h=Get-Location
        cls
        try {
            Start-Process "iexpress.exe" "/M /Q /N $($h.Path)\GTTODLevelLoader.sed" -Verb runAs
        } catch {
            echo "You need to accept the admin prompt"
            timeout -1
        }
    }
    if ($selection -eq 5) {
        $sed = Get-Content ".\SteamCloud\SteamCloudSync.sed"
        $sed.Split([Environment]::NewLine)
        $sed[26] = "TargetName=$(Get-Location)\SteamCloud\SteamCloudSync.exe"
        $sed[34] = "SourceFiles0=$(Get-Location)\SteamCloud"
        $sed | Set-Content ".\SteamCloud\SteamCloudSync.sed"
        $h=Get-Location
        cls
        try {
            Start-Process "iexpress.exe" "/M /Q /N $($h.Path)\SteamCloud\SteamCloudSync.sed" -Verb runAs
        } catch {
            echo "You need to accept the admin prompt"
            timeout -1
        }
        $sed = Get-Content ".\SteamCloud\Background.sed"
        $sed.Split([Environment]::NewLine)
        $sed[26] = "TargetName=$(Get-Location)\SteamCloud\GTTODSteamCloud.exe"
        $sed[34] = "SourceFiles0=$(Get-Location)\SteamCloud"
        $sed | Set-Content ".\SteamCloud\Background.sed"
        $h=Get-Location
        cls
        try {
            Start-Process "iexpress.exe" "/M /Q /N $($h.Path)\SteamCloud\Background.sed" -Verb runAs
        } catch {
            echo "You need to accept the admin prompt"
            timeout -1
        }
    }
    $Config | ConvertTo-Json -depth 32 | Format-Json | Set-Content .\BuildTool.json
    $Config = Get-Content .\BuildTool.json | ConvertFrom-Json
    cls
}