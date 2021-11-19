# Get-FileDiffs.ps1

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False)]
    [string] $SourceNode = 'WSFCNODE1',

    [Parameter(Mandatory=$False)]
    [string] $TargetNode = 'WSFCNODE2',

    [Parameter(Mandatory=$False)]
    [string[]] $Volumes = @('F','G')
)

# guard rail
$hostname = &'hostname'
if($SourceNode -like $hostname) {
    Write-Warning "ABORTING - SourceNode matches hostname. Running the script like this could delete the source files. NOT DOING IT!"
    return 1
}
if($TargetNode -like $hostname) {
    Write-Warning "ABORTING - TargetNode matches hostname. Running the script like this could delete the source files. NOT DOING IT!"
    return 1
}

if(-Not (Test-Path -Path 'C:\temp')) {
    New-Item -ItemType Directory -Path 'C:\temp' | Out-Null
}

While($True) {
    $output = ''
    $corruptCount = 0
    foreach ($vol in $Volumes) {
        Write-Verbose "Checking mirror status on $vol..."
        &'emcmd' $TargetNode lockvolume $vol | Out-Null
        $mirrorstatus = &'emcmd' $SourceNode getmirrorvolinfo $vol
        $mirrorstatus = $mirrorstatus[($mirrorstatus.Length - 1)]

        if($mirrorstatus -ne "1") {
            Write-Verbose "Mirror for $vol NOT running, continuing mirror..."
            &'emcmd' $SourceNode continuemirror $vol | Out-Null
            Start-Sleep 2
            while($mirrorstatus -ne "1") {
                $mirrorstatus = &'emcmd' $SourceNode getmirrorvolinfo $vol
                Start-Sleep 2
                Write-Verbose $mirrorstatus
                $mirrorstatus = $mirrorstatus[($mirrorstatus.Length - 1)]
            }
        }
        Write-Verbose "Mirror for $vol running"
        
        $logfile = "C:\temp\logfile$($vol).txt"
        Write-Verbose "Copying files for volume $vol. Logs going to $logfile..."
        &'robocopy' "\\$SourceNode\$($vol)$" "$($vol):" /MIR /FFT /mt /R:20 /W:10 /Zb /NP /NDL /copyall "/log:$($logfile)" | Out-Null

        Write-Verbose "Pausing and unlocking mirrorvol $vol on $TargetNode ..."
        &'emcmd' $TargetNode unlockvolume $vol | Out-Null
        &'emcmd' $SourceNode pausemirror $vol | Out-Null
        Start-Sleep 2
        $mirrorstatus = "1"
        while($mirrorstatus -ne "4") {
            $mirrorstatus = &'emcmd' $SourceNode getmirrorvolinfo $vol
            Write-Verbose $mirrorstatus
            $mirrorstatus = $mirrorstatus[($mirrorstatus.Length - 1)]
            Start-Sleep 2
        }
        Write-Verbose "Mirror for $vol paused"

        if(Test-Path -Path $logfile){
            Write-Verbose "Parsing $logfile..."
            $files = [System.Collections.ArrayList]@()
            Get-Content $logfile | %{
                if($_.Contains("\\$($SourceNode)\$($vol)$")) {
                    $token = "$($vol):$($_.Substring($_.IndexOf('$')+1))";
                    if($token.Length -gt 3) {
                        $files.Add($token) | Out-Null
                    }
                }
            }
            Write-Verbose "Found $($files.Count) files for $vol"

            foreach ($file in $files) {
                Write-Verbose $file
                $hash1 = ''
                $hash2 = ''
                try {
                    if(Test-Path -Path "$file") {
                        $hash1 = (Get-FileHash -Algorithm md5 "$file").Hash; 
                    }
 
                    $smbfile = $file.Replace(':','$')
                    if(Test-Path -Path "\\$TargetNode\$($smbfile)") {
                        $hash2 = (Get-FileHash -Algorithm md5 "\\$TargetNode\$($smbfile)").Hash; 
                    }
                }
                catch {
                    $_
                }
                if($hash1 -ne $hash2) {
                    Write-Verbose "CORRUPTION: $file - $hash1 vs $hash2"
                    $output += "$file`n"
                    $corruptCount += 1
                }
            }
            
            Write-Verbose "Removing $logfile..."
            Remove-Item -Force $logfile
        }

        Write-Verbose "Continuing and locking mirrorvol $vol on $TargetNode ..."
        &'emcmd' $TargetNode lockvolume $vol | Out-Null
        &'emcmd' $SourceNode continuemirror $vol | Out-Null
        $mirrorstatus = "4"
        while($mirrorstatus -ne "1") {
            $mirrorstatus = &'emcmd' $SourceNode getmirrorvolinfo $vol
            Write-Verbose $mirrorstatus
            $mirrorstatus = $mirrorstatus[($mirrorstatus.Length - 1)]
            Start-Sleep 2
        }
        Write-Verbose "Mirror for $vol running"
    }

    Write-Verbose "Found $corruptCount corrupt files"
    $output > 'C:\temp\filediffs.txt'

    Start-Sleep -Seconds 900
}
