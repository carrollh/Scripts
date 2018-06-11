#########################################################################################################
# BUG 4005
# This script results in an unusable system state due to verifier mucking with things. Reboot is 
# required on both source and especially target.
#########################################################################################################

. .\Utilities_DK.ps1

# USER DEFINED PARAMS
$nodes = "logotest9","logotest10"
$domain = "qatest.com"
$nodeIPs = "10.2.1.215","10.2.1.216"
$netAdapters = "Public","Private"
$mirrorVol = "E"

function TestBug4005() {
	emcmd . PAUSEMIRROR $mirrorVol
	emcmd $nodes[1] UNLOCKVOLUME $mirrorVol
	
	$testResults = TestTarget
	
	$testResults = $testResults -And $(TestSource)
	
	# RESTORE
	#RestoreVolumeSizes
	
	# display test outcome
	if( $testResults -eq $True ) { Write-Host "Test-Bug4005 PASSED" }
	else { Write-Warning "Test-Bug4005 FAILED" }
}

function TestTarget() {
	Write-Host "get the original volume size on the target"
	$remoteVol = Get-WmiObject -ComputerName nodes[1] -Credential $(getAdminCredentials) win32_volume | where-object { $_.Name -like ($mirrorVol+":\") }
	$oldRemoteVolSize = $remoteVol.Capacity
	
	# setup verifier on the target
	Invoke-Command -ComputerName $nodes[1] -Credential $(getAdminCredentials) { verifier /volatile /flags 4 /adddriver ExtMirr.sys } 
	Invoke-Command -ComputerName $nodes[1] -Credential $(getAdminCredentials) { verifier /volatile /faults 10000 EmBm }

	Write-Host "shrink the volume on the target"
	Invoke-Command -ComputerName $nodes[1] -Credential $(getAdminCredentials) -FilePath .\Test-Bug4005_BsideShrink.ps1

	# get the new target volume size
	$remoteVol = Get-WmiObject -ComputerName $nodes[1] -Credential $(getAdminCredentials) win32_volume | where-object { $_.Name -like ($mirrorVol+":\") }
	$newRemoteVolSize = $remoteVol.Capacity
	
	$testPassed = $True
	Write-Host "verify the new target volume size is accurate"
	if( $newRemoteVolSize -eq ($oldRemoteVolSize - 1024*1024) ) { Write-Host "Volume shrunk as expected" }
	else {
		$testPassed = $False
		Write-Host "Old:" $oldRemoteVolSize
		Write-Host "New:" $newRemoteVolSize
	}
		
	# reconfigure verifier on target node
	Invoke-Command -ComputerName $nodes[1] -Credential $(getAdminCredentials) { verifier /volatile /flags 0 } 
	Invoke-Command -ComputerName $nodes[1] -Credential $(getAdminCredentials) { verifier /volatile /faults 0 EmBm }
	
	return $testPassed
}

function TestSource() {
	Write-Host "get the original volume size on the source"
	$localVol = Get-WmiObject -ComputerName $nodes[0] -Credential $(getAdminCredentials) win32_volume | where-object { $_.Name -like ($mirrorVol+":\") }
	$oldLocalVolSize = $localVol.Capacity

	Write-Host "repeat on the source (this node)"
	verifier /volatile /flags 4 /adddriver ExtMirr.sys
	verifier /volatile /faults 10000 EmBm
	
	Write-Host "shrink the volume on the source"
	Invoke-Command -ComputerName $nodes[0] -Credential $(getAdminCredentials) -FilePath .\Test-Bug4005_BsideShrink.ps1

	Write-Host "get the new source volume size"
	$localVol = Get-WmiObject -ComputerName $nodes[0] win32_volume | where-object { $_.Name -like ($mirrorVol+":\") }
	$newLocalVolSize = $localVol.Capacity
	
	# verify the new source volume size is accurate
	$testPassed = $True
	if( $newLocalVolSize -eq ($oldLocalVolSize - 1024*1024) ) { Write-Host "Volume shrunk as expected" }
	else {
		$testPassed = $False
		Write-Host "Old:" $oldLocalVolSize
		Write-Host "New:" $newLocalVolSize
	}
	
	# reconfigure verifier on the source node
	verifier /volatile /flags 0
	verifier /volatile /faults 0 EmBm
	
	Write-Host "make sure DK returns to mirroring"
	emcmd $nodes[0] CONTINUEMIRROR $mirrorVol

	Write-Host "Waiting for A to get to A->B(Mirror)"
	$volInfo = GetVolumeInfoUntilValid $nodes[0] $mirrorVol
	$mirrorB = $volInfo.TargetList | Where-Object { $_.targetSystem -like $nodeIPs[1] }
	while( -Not $mirrorB.MirrorState -like "Mirror" ) {
		Start-Sleep 5
		$mirrorB = $volInfo.TargetList | Where-Object { $_.targetSystem -like $nodeIPs[1] }
	}
	
	return $testPassed
}

function RestoreVolumeSizes() {
	emcmd $nodes[0] PAUSEMIRROR $mirrorVol
	emcmd $nodes[1] UNLOCKVOLUME $mirrorVol
	
	# extend target volume to original size
	Invoke-Command -ComputerName $nodes[1] -Credential $(getAdminCredentials) -FilePath .\Test-Bug4005_BsideExtend.ps1

	# get the new target volume size
	$remoteVol = Get-WmiObject -ComputerName $nodes[1] -Credential $(getAdminCredentials) win32_volume | where-object { $_.Name -like ($mirrorVol+":\") }
	$newRemoteVolSize = $remoteVol.Capacity
	
	# verify the new target volume size is accurate
	if( $newRemoteVolSize -eq ($oldRemoteVolSize + 1024*1024) ) { Write-Host "Volume extended as expected" }
	else {
		Write-Host "Old:" $oldRemoteVolSize
		Write-Host "New:" $newRemoteVolSize
	}
	
	# extend source volume to original size
	Invoke-Command -ComputerName $nodes[0] -FilePath .\Test-Bug4005_BsideExtend.ps1	
	
	# get the new source volume size
	$localVol = Get-WmiObject -ComputerName $nodes[0] win32_volume | where-object { $_.Name -like ($mirrorVol+":\") }
	$newLocalVolSize = $localVol.Capacity
	
	# verify the new source volume size is accurate
	if( $newLocalVolSize -eq ($oldLocalVolSize + 1024*1024) ) { Write-Host "Volume shrunk as expected" }
	else {
		Write-Host "Old:" $oldLocalVolSize
		Write-Host "New:" $newLocalVolSize
	}
	
	# make sure DK returns to mirroring
	emcmd $nodes[0] CONTINUEMIRROR $mirrorVol

	Write-Host "Waiting for A to get to A->B(Mirror)"
	$volInfo = GetVolumeInfoUntilValid $nodes[0] $mirrorVol
	$mirrorB = $volInfo.TargetList | Where-Object { $_.targetSystem -like $nodeIPs[1] }
	while( -Not $mirrorB.MirrorState -like "Mirror" ) {
		Start-Sleep 5
		$mirrorB = $volInfo.TargetList | Where-Object { $_.targetSystem -like $nodeIPs[1] }
	}
}