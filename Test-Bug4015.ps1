#########################################################################################################
# BUG 4015
# Setup: 1x1 Sync mirror added to "Available Storage" in WSFC.  
#########################################################################################################

. .\Utilities_DK.ps1

function TestBug4015() {
	Param(
		[Parameter(Mandatory=$False,Position=0)]
		[Int32]$timeout = 21600 # six hours = 21600
	)
	
	# USER DEFINED PARAMS
	$nodes = "logotest9","logotest10" # DONT include the FQDN or names wont match cluster node names!
	$domain = "qatest.com"
	$nodeIPs = "10.2.1.215","10.2.1.216"
	$netAdapters = "Public","Private","iSCSI"
	$mirrorVol = "E"
	
	#Get-ClusterGroup "Available Storage" | Move-ClusterGroup $nodes[1]
	
	# execute the other two scripts
	$proc2 = Start-Process cmd -Credential $(getAdminCredentials) -PassThru -Args "/C C:\Scripts\Test-Bug4015_Repro2.cmd"
	$proc1 = Start-Process cmd -Credential $(getAdminCredentials) -PassThru -Args "/C C:\Scripts\Test-Bug4015_Repro1.cmd"

	# run the other 2 scripts until timeout is depleted
	while( $timeout -gt 0 ) {
		Start-Sleep 1
		$timeout -= 1
	}

	# stop the other 2 scripts
	$proc1 | Stop-Process
	$proc2 | Stop-Process

	# return the mirror to service
	emcmd $nodes[1] LOCKVOLUME $mirrorVol
	emcmd $nodes[0] CONTINUEMIRROR $mirrorVol
	waitOnMirrorState $nodes[0] $mirrorVol

	# if the mirror goes back to mirror state, the test passed, otherwise it failed
	$volInfo = Get-DataKeeperVolumeInfo $nodes[0] $mirrorVol
	if( $volInfo.TargetList[0].mirrorState -like "Mirror" ) { Write-Host "Test-Bug4015 PASSED" }
	else { Write-Warning "Test-Bug4015 FAILED" }
}