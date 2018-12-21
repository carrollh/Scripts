$nodes = "cae-qa-v200", "cae-qa-v201", "cae-qa-v202", "cae-qa-v203"
$nodes | foreach {
    $jobinfo = & "$env:extmirrbase\emcmd" $_ getjobinfo
    if($jobinfo.Length -ne 0) { 
        $s = $jobinfo[0].split();
        $jobs = New-Object System.Collections.Generic.List[System.String];
        $jobs.Add($s[$s.length-1]);
    
        for ($i = 1; $i -lt $jobinfo.length; $i += 1) {
            if ($jobinfo[$i] -like "ID*") {
                $s = $jobinfo[$i].split();
                $jobs.Add($s[$s.length-1]);
            }
        }

        for ($k = 0; $k -lt $jobs.Count; $k++) {
            write-host "deleting $jobs from $_"
            & "$env:extmirrbase\emcmd" $_ deletejob $jobs[$k]
        }
    }
}