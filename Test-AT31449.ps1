# Test-AT31449.ps1
# Includes
. .\Utilities_DK.ps1
. .\TestDK.ps1

function Test-AT31449() {

	# PARAMS
	$nodes = "cae-qa-v55.qagroup.com","cae-qa-v56.qagroup.com","cae-qa-v53.qagroup.com"
	$nodeIPs = "10.200.8.55","10.200.8.56","10.200.8.53"
	
	$jobParams = "test","desc",($nodes[0]),($nodeIPs[0]),"E",($nodes[1]),($nodeIPs[1]),"E","Async"
	$mirParams = ($jobParams[3]),($jobParams[4]),($jobParams[6]),($jobParams[7]),($jobParams[8])
	$ep1Params = ($nodes[0]),($jobParams[3]),"E",($nodes[2]),($nodeIPs[2]),"E",($jobParams[8])
	$ep2Params = ($nodes[1]),($jobParams[6]),"E",($nodes[2]),($nodeIPs[2]),"E",($jobParams[8])
	
	# CREATE A JOB ###############################################################################
	New-DataKeeperJob $jobParams[0] $jobParams[1] $jobParams[2] $jobParams[3] $jobParams[4] $jobParams[5] $jobParams[6] $jobParams[7] $jobParams[8] > $Null

	# Verify Job exists and is the same on both nodes
	$sourceJobKey = Invoke-Command -ComputerName $nodes[0] -Credential $(getAdminCredentials) { Get-ChildItem "hklm:\System\CurrentControlSet\Services\ExtMirr\Parameters\Jobs" }
	$targetJobKey = Invoke-Command -ComputerName $nodes[1] -Credential $(getAdminCredentials) { Get-ChildItem "hklm:\System\CurrentControlSet\Services\ExtMirr\Parameters\Jobs" }

	if( "$sourceJobKey" -eq "$targetJobKey" ) {
		if( -Not $sourceJobKey.Name -eq $targetJobKey ) { 
			Write-Warning "Job creation FAILED" 
			return $False 
		} else {
			Write-Host "Job creation PASSED"
		}
	}

	$lastSlashIndex = $sourceJobKey.Name.LastIndexOf("\")
	$jobId = $sourceJobKey.Name.substring( $lastSlashIndex+1 )

	# CREATE A MIRROR ############################################################################
	New-DataKeeperMirror $mirParams[0] $mirParams[1] $mirParams[2] $mirParams[3] $mirParams[4] > $Null

	# wait for the mirror properties to propagate
	$sourceVol = New-Object -TypeName "SteelEye.Model.DataReplication.VolumeInfo"
	while( $sourceVol.TargetList -eq $Null ) {
		$sourceVol = get-datakeepervolumeinfo $nodes[0] $jobParams[4]
	}

	$targetVol = New-Object -TypeName "SteelEye.Model.DataReplication.VolumeInfo"
	while( $targetVol.TargetList -eq $Null ) {
		$targetVol = get-datakeepervolumeinfo $nodes[1] $jobParams[7]
	} 

	while( -Not $sourceVol.MirrorRole -like "Source" ) {
		Start-Sleep 1
	}
	while( -Not $targetVol.MirrorRole -like "Target" ) {
		Start-Sleep 1
	}

	# Verify Mirror was created
	$failure = $False

	if( $sourceVol ) {
		if( -Not $sourceVol.TargetList[0].targetSystem -like $nodes[1] ) { Write-Host "Failed checking Source's targetSystem."; $failure = $True }
		if( -Not $sourceVol.TargetList.TargetVolume -like $jobParams[7] ) { Write-Host "Failed checking Source's targetVolume."; $failure = $True }
		if( -Not $sourceVol.TargetList.MirrorType -like $jobParams[8] ) { Write-Host "Failed checking Source's targetMirrorType."; $failure = $True }
	} else {
		Write-Warning ("Source's MirrorRole not 'Source': " + $sourceVol.MirrorRole)
		$failure = $True
	}

	if( $targetVol ) {
		if( -Not $targetVol.TargetList.TargetSystem -like $nodes[0] ) { Write-Host "Failed checking Target's targetSystem."; $failure = $True }
		if( -Not $targetVol.TargetList.TargetVolume -like $jobParams[4] ) { Write-Host "Failed checking Target's targetVolume."; $failure = $True }
		if( -Not $targetVol.TargetList.MirrorType -like $jobParams[8] ) { Write-Host "Failed checking Target's targetMirrorType."; $failure = $True }
	} else {
		Write-Warning ("Target's MirrorRole not 'Target': " + $targetVol.MirrorRole)
		$failure = $True
	}

	if( $failure -eq $True ) {
		Write-Warning "Mirror creation FAILED"
		return $False
	} else {
		Write-Host "Mirror creation PASSED"
		$failure = $False
	}

	# Add first new endpoint from node1 to node3
	Add-DataKeeperJobPair $jobId $ep1Params[0] $ep1Params[1] $ep1Params[2] $ep1Params[3] $ep1Params[4] $ep1Params[5] $ep1Params[6] > $Null
	
	$validEPs = New-Object -TypeName "System.Collections.Generic.List[string]"
	$validEPs.Add(($nodes[0])+";"+($jobParams[4])+";"+($jobParams[3])+";"+($nodes[1])+";"+($jobParams[7])+";"+($jobParams[6])+";"+($jobParams[8][0]))
	$validEPs.Add(($ep1Params[0])+";"+($ep1Params[1])+";"+($ep1Params[2])+";"+($ep1Params[3])+";"+($ep1Params[4])+";"+($ep1Params[5])+";"+($ep1Params[6][0]))
	
	$foundEPs = New-Object -TypeName "System.Collections.Generic.List[System.Object]"
	$foundEPs.Add( $(Invoke-Command -ComputerName $nodes[0] -Credential $(getAdminCredentials) { Get-ChildItem "hklm:\System\CurrentControlSet\Services\ExtMirr\Parameters\Jobs" | Get-ItemProperty -Name Endpoints } ))
	$foundEPs.Add( $(Invoke-Command -ComputerName $nodes[1] -Credential $(getAdminCredentials) { Get-ChildItem "hklm:\System\CurrentControlSet\Services\ExtMirr\Parameters\Jobs" | Get-ItemProperty -Name Endpoints } ))
	$foundEPs.Add( $(Invoke-Command -ComputerName $ep1Params[3] -Credential $(getAdminCredentials) { Get-ChildItem "hklm:\System\CurrentControlSet\Services\ExtMirr\Parameters\Jobs" | Get-ItemProperty -Name Endpoints } ))
	
	# verify first endpoint
	if( $(verifyEndpointData $validEPs $foundEPs) ) {
		Write-Host "First Endpoint creation PASSED"
	} else {
		Write-Warning "Endpoint 1 verification FAILED"
		return $False
	}
	
	# Add second new endpoint form node2 to node3
	Add-DataKeeperJobPair $jobId $ep2Params[0] $ep2Params[1] $ep2Params[2] $ep2Params[3] $ep2Params[4] $ep2Params[5] $ep2Params[6] > $Null
	$validEPs.Add(($ep2Params[0])+";"+($ep2Params[1])+";"+($ep2Params[2])+";"+($ep2Params[3])+";"+($ep2Params[4])+";"+($ep2Params[5])+";"+($ep2Params[6][0]))
	
	$foundEPs = New-Object -TypeName "System.Collections.Generic.List[System.Object]"
	$foundEPs.Add( $(Invoke-Command -ComputerName $nodes[0] -Credential $(getAdminCredentials) { Get-ChildItem "hklm:\System\CurrentControlSet\Services\ExtMirr\Parameters\Jobs" | Get-ItemProperty -Name Endpoints } ))
	$foundEPs.Add( $(Invoke-Command -ComputerName $nodes[1] -Credential $(getAdminCredentials) { Get-ChildItem "hklm:\System\CurrentControlSet\Services\ExtMirr\Parameters\Jobs" | Get-ItemProperty -Name Endpoints } ))
	$foundEPs.Add( $(Invoke-Command -ComputerName $ep1Params[3] -Credential $(getAdminCredentials) { Get-ChildItem "hklm:\System\CurrentControlSet\Services\ExtMirr\Parameters\Jobs" | Get-ItemProperty -Name Endpoints } ))
	
	# verify second endpoint
	if( $(verifyEndpointData $validEPs $foundEPs) ) {
		Write-Host "Second Endpoint creation PASSED"
	} else {
		Write-Warning "Endpoint 2 verification FAILED"
		return $False
	}
	
	# verify no new mirrors were created with the new endpoints
	$e = Get-DataKeeperVolumeInfo $nodes[0] $jobParams[4]
	if( -Not $e.mirrorRole -like "Source" ) { Write-Host "Volume E on source (node1) not reporting Source role."; $failure = $True }
	
	$e = Get-DataKeeperVolumeInfo $nodes[1] $jobParams[7]
	if( -Not $e.mirrorRole -like "Target" ) { Write-Host "Volume E on target1 (node2) not reporting target role."; $failure = $True }
	
	$f = Get-DataKeeperVolumeInfo $ep1Params[0] $ep1Params[2]
	if( -Not $f.mirrorRole -like "None" ) { Write-Host "Volume F on source (node1) not reporting None role."; $failure = $True }

	$f = Get-DataKeeperVolumeInfo $ep1Params[3] $ep1Params[5]
	if( -Not $f.mirrorRole -like "None" ) { Write-Host "Volume F on target2 (node3) not reporting None role."; $failure = $True }
	
	$g = Get-DataKeeperVolumeInfo $ep2Params[0] $ep2Params[2]
	if( -Not $g.mirrorRole -like "None" ) { Write-Host "Volume G on source (node2) not reporting None role."; $failure = $True }

	$g = Get-DataKeeperVolumeInfo $ep2Params[3] $ep2Params[5]
	if( -Not $g.mirrorRole -like "None" ) { Write-Host "Volume G on target2 (node3) not reporting None role."; $failure = $True }
	
	if( $failure -eq $True ) { 
		Write-Warning "Excess mirrors found or mirror volume E in wrong state!"
		return $False
	} else {
		Write-Host "Extra Mirror check PASSED"
	}
	
	# remove the only mirror 
	Remove-DataKeeperMirror $nodes[0] $jobParams[4] > $Null
	
	# verify it is gone
	$e = Get-DataKeeperVolumeInfo $nodes[0] $jobParams[4]
	if( -Not $e.mirrorRole -like "None" ) { Write-Host "Volume E on source (node1) not reporting None role."; $failure = $True }
	
	$e = Get-DataKeeperVolumeInfo $nodes[1] $jobParams[7]
	if( -Not $e.mirrorRole -like "None" ) { Write-Host "Volume E on target1 (node2) not reporting None role."; $failure = $True }
	
	if( $failure -eq $True ) { 
		Write-Warning "Mirrors on Volume E in not successfully deleted!"
		return $False
	} else {
		Write-Host "Remove-Mirror check PASSED"
	}
	
	# remove the job
	Remove-DataKeeperJob $jobId $nodes[0] > $Null
	
	# verify no jobs exists
	$joblist = Get-DataKeeperJobList $nodes[0]
	if( -Not $jobslist.Count -eq 0 ) { Write-Warning "Extra jobs found on node 1!"; $failure = $True }
	
	$joblist = Get-DataKeeperJobList $nodes[1]
	if( -Not $jobslist.Count -eq 0 ) { Write-Warning "Extra jobs found on node 1!"; $failure = $True }

	$joblist = Get-DataKeeperJobList $ep1Params[3]
	if( -Not $jobslist.Count -eq 0 ) { Write-Warning "Extra jobs found on node 1!"; $failure = $True }

	if( $failure -eq $True ) { 
		Write-Warning "Job not successfully deleted!"
		return $False
	} else {
		Write-Host "Remove-Job check PASSED"
	}
}

function verifyEndpointData() {
	Param(
		[Parameter(Mandatory=$True, Position=0)]
		[System.Collections.Generic.List[string]]$validEPs,
		
		[Parameter(Mandatory=$True, Position=1)]
		[System.Collections.Generic.List[System.Object]]$foundEPs
	)
	$failure = $False
	
	# verify there are the correct number of foundEPs
	for($i = 0; $i -lt $foundEPs.Count; $i++) {
		if( -Not $validEPs.Count -eq $foundEPs[$i].Endpoints.Count ) {
			Write-Warning ("Found the wrong number of endpoints on the " + $i + "th node")
			$failure = $True
		}
	}
	
	if( $failure -eq $True ) {
		return -Not $failure
	}
	
	# step through the found EPs and compare them with the valid ones
	for($i = 0; $i -lt $foundEPs.Count; $i++) {
		for($j = 0; $j -lt $validEPs.Count; $j++) {
			if( -Not $validEPs[$j] -ieq $foundEPs[$i].Endpoints[$j] ) {
				$failure = $True
				Write-Warning ("EP " + $j + " is invalid on node " + $i)
			}
		}
	}
	
	return -Not $failure
}
