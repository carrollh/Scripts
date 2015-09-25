# Bug 4025

. .\Utilities_DK.ps1
. .\TestDK.ps1
. .\Write-File.ps1

function Test-Bug4025() {	
	# USER DEFINED PARAMS
	$nodes = "logotest9","logotest10"
	$domain = ".qatest.com"
	$nodeIPs = "10.2.1.215","10.2.1.216"
	$mirrorVol = "A","B"
	
# 	use the following command to allow you to mount a volume as A. It must be dismounted 
# 	first which is what the below does.
# 	mountvol A: /D 
	
	New-DataKeeperJob bug4025 async ($nodes[0]+$domain) $nodeIps[0] $mirrorVol[0] ($nodes[1]+$domain) $nodeIps[1] $mirrorVol[1] Async
	New-DataKeeperMirror $nodeIPs[0] $mirrorVol[0] $nodeIPs[1] $mirrorVol[1] Async
	#emcmd $nodes[0] SETCONFIGURATION $mirrorVol[0] 128
	#emcmd $nodes[0] REGISTERCLUSTERVOLUME $mirrorVol[0]
	
	$volInfo = Get-DataKeeperVolumeInfo $nodes[0] $mirrorVol[0]
	if( -Not $(waitOnMirrorState $volInfo) ) { Write-Host $mirrorVol[0] " on " $nodes[0] " FAILED to enter the mirror state"; return $False }
	#if( -Not $(waitOnClusterOnline) ) { Write-Host "Cluster FAILED to online"; return $False }
	
	Invoke-Command -ComputerName $nodes[1] -Credential $(getAdminCredentials) { emcmd . SWITCHOVERVOLUME B }
	#Get-ClusterGroup "Available Storage" | Move-ClusterGroup $nodes[1] 
	#if( -Not $(waitOnClusterOnline) ) { Write-Host "Cluster FAILED to online"; return $False }
	if( -Not $(waitOnMirrorState $volInfo) ) { Write-Host $mirrorVol[1] " on " $nodes[1] " FAILED to enter the mirror state"; return $False }
	
	$path = ($mirrorVol[1].ToString() + ":\")
	#Write-File -Size 10MB -Folder $path -FilenamePrefix Bug4025
	
	if( -Not $(waitOnMirrorState $volInfo) ) { Write-Host $mirrorVol[1] " on " $nodes[1] " FAILED to enter the mirror state"; return $False }
	
	return $True
}