# Get-FileDiffs.ps1

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False)]
    [string] $Node1 = 'WSFCNODE1',

    [string] $Node2 = 'WSFCNODE2',

    [string[]] $Volumes = @('F','G')
)

if(-Not (Test-Path -Path 'C:\temp')) {
    New-Item -ItemType Directory -Path 'C:\temp' | Out-Null
}

While($True) {
    $output = ''

    foreach ($vol in $Volumes) {
        Write-Verbose "Checking mirror status on $vol..."
        &'emcmd' $Node2 lockvolume $vol | Out-Null
        $mirrorstatus = &'emcmd' $Node1 getmirrorvolinfo $vol
        $mirrorstatus = $mirrorstatus[($mirrorstatus.Length - 1)]

        if($mirrorstatus -ne "1") {
            Write-Verbose "Mirror for $vol NOT running, continuing mirror..."
            &'emcmd' $Node1 continuemirror $vol | Out-Null
            Start-Sleep 2
            while($mirrorstatus -ne "1") {
                $mirrorstatus = &'emcmd' $Node1 getmirrorvolinfo $vol
                Start-Sleep 2
                Write-Verbose $mirrorstatus
                $mirrorstatus = $mirrorstatus[($mirrorstatus.Length - 1)]
            }
        }
        Write-Verbose "Mirror for $vol running"
        
        $logfile = "C:\temp\logfile$($vol).txt"
        Write-Verbose "Copying files for volume $vol. Logs going to $logfile..."
        &'robocopy' "\\$Node1\$($vol)$" "$($vol):" /MIR /FFT /mt /R:20 /W:10 /Zb /NP /NDL /copyall "/log:$($logfile)" | Out-Null

        Write-Verbose "Pausing and unlocking mirrorvol $vol on $Node2 ..."
        &'emcmd' $Node2 unlockvolume $vol | Out-Null
        &'emcmd' $Node1 pausemirror $vol | Out-Null
        Start-Sleep 2
        $mirrorstatus = "1"
        while($mirrorstatus -ne "4") {
            $mirrorstatus = &'emcmd' $Node1 getmirrorvolinfo $vol
            Write-Verbose $mirrorstatus
            $mirrorstatus = $mirrorstatus[($mirrorstatus.Length - 1)]
            Start-Sleep 2
        }
        Write-Verbose "Mirror for $vol paused"

        if(Test-Path -Path $logfile){
            Write-Verbose "Parsing $logfile..."
            $files = [System.Collections.ArrayList]@()
            Get-Content $logfile | %{
                if($_.Contains("\\$($Node1)\$($vol)$")) {
                    $token = "$($vol):$($_.Substring($_.IndexOf('$')+1))";
                    if($token.Length -gt 3) {
                        $files.Add($token) | Out-Null
                    }
                }
            }
            Write-Verbose "Found $($files.Count) files for $vol"

            try {
                foreach ($file in $files) {
                    Write-Verbose $file
                    $hash1 = Get-FileHash -Algorithm md5 "$file"; 
                    $hash2 = Get-FileHash -Algorithm md5 "\\$Node2\$($file)"; 
                    if($hash1 -ne $hash2) {
                        Write-Verbose "CORRUPTION: $file - $hash1 vs $hash2"
                        $output += "$file`n"
                    }
                }
            }
            catch {
                $_
            }
            
            Write-Verbose "Removing $logfile..."
            Remove-Item -Force $logfile
        }

        Write-Verbose "Continuing and locking mirrorvol $vol on $Node2 ..."
        &'emcmd' $Node2 lockvolume $vol | Out-Null
        &'emcmd' $Node1 continuemirror $vol | Out-Null
        $mirrorstatus = "4"
        while($mirrorstatus -ne "1") {
            $mirrorstatus = &'emcmd' $Node1 getmirrorvolinfo $vol
            Write-Verbose $mirrorstatus
            $mirrorstatus = $mirrorstatus[($mirrorstatus.Length - 1)]
            Start-Sleep 2
        }
        Write-Verbose "Mirror for $vol running"
    }

    Write-Verbose "Found $($output.Length) corrupt files"
    $output > 'C:\temp\filediffs.txt'

    Start-Sleep -Seconds 900
}
