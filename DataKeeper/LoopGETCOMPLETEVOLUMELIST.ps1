while($true) {
	$volList = & "$env:extmirrbase\emcmd" . getcompletevolumelist
	$volList
	if($LastExitCode -ne 0 -OR -NOT $?) { 
		"LASTEXITCODE = $LastExitCode"
		"? = $?"
		return     
    	}
}