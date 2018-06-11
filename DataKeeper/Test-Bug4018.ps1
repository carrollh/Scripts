#########################################################################################################
# BUG 4018
#########################################################################################################

. .\Utilities_DK.ps1

# USER DEFINED PARAMS
$nodes = "logotest9","logotest10","logotest11" 
$domain = "qatest.com"
$nodeIPs = "10.2.1.215","10.2.1.216","10.2.1.217"
$netAdapters = "Public","Private"
$mirrorVol = "E"

function TestBug4018() {
	# Down the rep network on C
	Invoke-Command -ComputerName $nodes[2] -Credential $(getAdminCredentials) { 
		Param($nA1) Get-NetAdapter $nA1 | Disable-NetAdapter -Confirm:$False 
	} -Args $netAdapters[1]
	
	# write data to the source on A to force A->C(Paused)
	writefile -t ($mirrorVol+":\bug4018") 1000k
	
	Write-Host "Waiting for A to get to A->C(Paused)"
	$volInfo = GetVolumeInfoUntilValid $nodes[0] $mirrorVol
	$mirrorC = $volInfo.TargetList | Where-Object { $_.targetSystem -like $nodeIPs[2] }
	while( -Not $mirrorC.MirrorState -like "Paused" ) {
		Start-Sleep 5
		$mirrorC = $volInfo.TargetList | Where-Object { $_.targetSystem -like $nodeIPs[2] }
	}
	
	# Switchover to B
	Invoke-Command -ComputerName $nodes[1] -Credential $(getAdminCredentials) {
		Param($mV) emcmd . SWITCHOVERVOLUME $mV
	} -Args $mirrorVol
	
	Write-Host "Waiting for B to get to B->C(Paused)"
	$volInfo = GetVolumeInfoUntilValid $nodes[1] $mirrorVol
	$mirrorC = $volInfo.TargetList | Where-Object { $_.targetSystem -like $nodeIPs[2] }
	while( -Not $mirrorC.MirrorState -like "Paused" ) {
		Start-Sleep 5
		$mirrorC = $volInfo.TargetList | Where-Object { $_.targetSystem -like $nodeIPs[2] }
	}
	
	Write-Host "Waiting for B to get to B->A(Mirror)"
	$volInfo = GetVolumeInfoUntilValid $nodes[1] $mirrorVol
	$mirrorC = $volInfo.TargetList | Where-Object { $_.targetSystem -like $nodeIPs[0] }
	while( -Not $mirrorC.MirrorState -like "Mirror" ) {
		Start-Sleep 5
		$mirrorC = $volInfo.TargetList | Where-Object { $_.targetSystem -like $nodeIPs[0] }
	}
	
	# Reconnect rep network on C
	Invoke-Command -ComputerName $nodes[2] -Credential $(getAdminCredentials) { 
		Param($nA1) Get-NetAdapter $nA1 | Enable-NetAdapter -Confirm:$False 
	} -Args $netAdapters[1]
	
	Write-Host "Waiting for B to get to B->C(Mirror)"
	$volInfo = GetVolumeInfoUntilValid $nodes[1] $mirrorVol
	$mirrorC = $volInfo.TargetList | Where-Object { $_.targetSystem -like $nodeIPs[2] }
	$timeout = 300
	while( -Not $mirrorC.MirrorState -like "Mirror" -And $timeout -gt 0 ) {
		Start-Sleep 5
		$timeout -= 5
		$mirrorC = $volInfo.TargetList | Where-Object { $_.targetSystem -like $nodeIPs[2] }
	}
	
	if( $timeout -gt 0 ) { Write-Host "Test-4018 PASSED" }
	else { Write-Warning "Test-4018 FAILED" }
}
