#########################################################################################################
# BUG 4017
#########################################################################################################

. .\Utilities_DK.ps1
. .\TestDK.ps1

function Test-Bug4017() {	

	# USER DEFINED PARAMS
	$nodes = "logotest9.qatest.com","logotest10.qatest.com","logotest11.qatest.com" 
	$nodeIPs = "10.2.1.215","10.2.1.216","10.2.1.217"
	$netAdapters = "Public","Private"
	$mirrorVol = "G"
	
	emcmd $nodes[0] SETCONFIGURATION $mirrorVol 384 > $NUL
	emcmd $nodes[1] SETCONFIGURATION $mirrorVol 384 > $NUL
	
	New-DataKeeperJob "bug4017" "Async" $nodes[0] $nodeIPs[0] $mirrorVol $nodes[2] $nodeIPs[2] $mirrorVol "Async" > $Null
	New-DataKeeperMirror $nodeIPs[0] $mirrorVol $nodeIPs[2] $mirrorVol Async
	
	$joblist = Get-DataKeeperJobList $nodes[0]
	
	Add-DataKeeperJobPair $joblist[0].JobId $nodes[0] $nodeIPs[0] $mirrorVol $nodes[1] $nodeIPs[1] $mirrorVol "Disk" > $Null
	Add-DataKeeperJobPair $joblist[0].JobId $nodes[1] $nodeIPs[1] $mirrorVol $nodes[2] $nodeIPs[2] $mirrorVol "Async" > $Null
	
	emcmd $nodes[0] REGISTERCLUSTERVOLUME $mirrorVol > $NUL
	
	$volInfo = Get-DataKeeperVolumeInfo $nodes[0] $mirrorVol 
	if( -Not $(waitOnMirrorState $volInfo) ) { Write-Host $mirrorVol " on " $nodes[0] " FAILED to enter the mirror state"; return $False }
	if( -Not $(waitOnClusterOnline) ) { Write-Host "Cluster FAILED to online"; return $False }
	
	emcmd $nodes[0] PAUSEMIRROR $mirrorVol > $NUL
	$volInfo = Get-DataKeeperVolumeInfo $nodes[0] $mirrorVol 
	if( -Not $(waitOnPausedState $volInfo) ) { Write-Host $mirrorVol " on " $nodes[0] " FAILED to be created in the paused state"; return $False }
	
	# switchover to shared buddy
	Get-ClusterGroup "Available Storage" | Move-ClusterGroup $nodes[1] 
	if( -Not $(waitOnClusterOnline) ) { Write-Host "Cluster FAILED to online"; return $False }
	
	$volInfo = Get-DataKeeperVolumeInfo $nodes[1] $mirrorVol
	if( -Not $(waitOnPausedState $volInfo) ) { Write-Host $mirrorVol " on " $nodes[1] " FAILED to be created in the paused state"; return $False }
}