# RUN ON SOURCE NODE

$allgood = $true
$hosts = "cae-qa-v200","cae-qa-v201","cae-qa-v202"
$vol = "E"

if(-NOT (Test-Path -Path ($PSScriptRoot + "\MD5s.txt"))) {
    Out-File -FilePath ($PSScriptRoot + "\MD5s.txt")
}

$files = Get-ChildItem -Path ($vol+":\")
$files | foreach {
    for ($i = 1; $i -lt $hosts.Count; $i++) {
        & $env:extmirrbase\emcmd.exe $hosts[$i] unlockvolume $vol >$NULL
    }
    Write-Host $_.FullName

    $jobs = New-Object System.Collections.ArrayList 
    $md5s = New-Object System.Collections.ArrayList 
    foreach ($h in $hosts) {
        $job = Start-Job -ScriptBlock { param($n,$v,$h) Get-FileHash -Path \\$h\$v$\$n -Algorithm MD5 } -ArgumentList $_.Name,$vol,$h 
        $jobs.Add($job) >$NULL
    }

    foreach ($job in $jobs) {
        $md5 = $job | Wait-Job | Receive-Job 
        $md5s.Add($md5) >$NULL
    }

    $sourcemd5 = $md5s[0]
    for ($k = 1; $k -lt $md5s.Count; $k++) {

        if( $sourcemd5.hash -eq $md5s[$k].hash ) {
	        $message = $sourcemd5.hash + " equals " + $md5s[$k].hash + "`n"
            Write-Host $message
	        Add-Content ($PSScriptRoot + "\MD5s.txt") "$_`t$message"
        } else {
	        $message = $sourcemd5.hash + " NOT EQUAL TO " + $md5s[$k].hash + "`n"
            Write-Warning $message 
	        Add-Content ($PSScriptRoot + "\MD5s.txt") "$_`tFAIL: $message"
            $allgood = $false
        }
    }
}

$allgood
