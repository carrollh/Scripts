#########################################################################################################
# BUG 3998
#########################################################################################################

. .\Utilities_DK.ps1

# USER DEFINED PARAMS
$nodes = "logotest9","logotest10","logotest11" # DONT include the FQDN or names wont match cluster node names!
$domain = "qatest.com"
$nodeIPs = "10.2.1.215","10.2.1.216","10.2.1.217"
$netAdapters = "Public","Private"
$mirrorVol = "G"

function TestBug3998() {	
	
	Write-Host "Verify that in your 2x1 setup the non-sharing node is source (i.e. in a A1, A2, B setup, have B -> A1), and that it is NOT an iscsi volume. Also, this script should be run from A1 (the target)."
	
	# Set the cluster to failover to A1
	SetClusterOwnersUntilValid $nodes[2],$nodes[0],$nodes[1]
	FailoverThenSwitchoverToPeer
	
	# switchover to B
	Get-ClusterGroup "Available Storage" | Move-ClusterGroup $nodes[2]
	
	Write-Host "Waiting for B to be the new owner node"
	$clusterGroup = Get-ClusterGroup "Available Storage"
	while( -Not $clusterGroup.OwnerNode.Name -like $nodes[2] ) {
		Start-Sleep 1
		$clusterGroup = Get-ClusterGroup "Available Storage"
	}
	
	Write-Host "Waiting on valid volume info from B"
	$volInfo = GetVolumeInfoUntilValid $nodes[2] $mirrorVol

	Write-Host "Waiting for G on B to get to Mirror State"
	if( -Not $(waitOnMirrorState $volInfo) ) { Write-Warning ($nodes[2] + " took longer than 5 minutes to get to Mirror State!"); return } 
	
	# set bandwidththrottle for target A2 to 11000
	SetTargetProperty $nodes[1] $nodeIPs[2] $mirrorVol BandwidthThrottle 11000
	emcmd $nodes[1] READREGISTRY $mirrorVol
	
	# verify the Write Queue on B -> A2 is zero
	$counter = "\SIOS Data Replication(" + $mirrorVol + ":\ (" + $nodeIPs[1] + "))\Queue Current Length"
	$sample = GetCounterUntilValid $nodes[2] $counter
	while( $sample.CounterSamples[0].CookedValue -gt 0 ) {
		$sample = GetCounterUntilValid $nodes[2] $counter
	}

	# write to G on node B	
	WriteAsync $nodes[2] 
	
	# verify the Write Queue on B is > 0
	$sample = GetCounterUntilValid $nodes[2] $counter
	while( -Not $sample.CounterSamples[0].CookedValue -gt 0) {
		$sample = GetCounterUntilValid $nodes[2] $counter
	} 

	# Set the cluster to failover to A2
	SetClusterOwnersUntilValid $nodes[2],$nodes[1],$nodes[0]
	FailoverThenSwitchoverToPeer
	
	if( $(CompareReplicationBitmapChecksums) ) {
		Write-Host "Test PASSED"
	} else {
		Write-Warning "Test FAILED"
	}
}

function CompareReplicationBitmapChecksums() {
	$clusterGroup = Get-ClusterGroup "Available Storage"
	emcmd $clusterGroup.OwnerNode.Name PAUSEMIRROR $mirrorVol
	
	Write-Host "Waiting on valid volume info from B"
	$volInfo = GetVolumeInfoUntilValid $nodes[2] $mirrorVol
	
	waitOnPausedState $volInfo
	
	emcmd $nodes[2] UNLOCKVOLUME $mirrorVol
	$d = $null
	while( -Not $d ) {
		$d = dir ("\\"+$nodes[2]+"\"+$mirrorVol+"$")
	}
	
	Write-Host "Waiting on valid volume info from A1"
	$volInfo = GetVolumeInfoUntilValid $nodes[0] $mirrorVol
	
	emcmd $nodes[0] UNLOCKVOLUME $mirrorVol
	$d = $null
	while( -Not $d ) {
		$d = dir ($mirrorVol+":")
	}
	
	$cmd = $mirrorVol + ":\ReplicationBitmaps\" + $nodeIPs[2]
	$md5 = $null
	$md5 = md5sums.exe -e $cmd
	while( -Not $md5[8] ) {
		$md5 = md5sums.exe -e $cmd
	}	
	$len = $md5[8].Length
	$md5_A1 = $md5[8].Substring($len - 32)
	$md5_A1
	
	$md5 = $null
	$md5 = Invoke-Command -ComputerName $nodes[2] -Credential $(getAdminCredentials) { Param($command) md5sums.exe -e $command } -Args $cmd
	while( -Not $md5[8] ) {
		$md5 = Invoke-Command -ComputerName $nodes[2] -Credential $(getAdminCredentials) { Param($command) md5sums.exe -e $command } -Args $cmd
	}
	$len = $md5[8].Length
	$md5_B = $md5[8].Substring($len - 32)
	$md5_B
	
	if( $md5_A1 -like $md5_B ) { return $True }
	
	return $False 
}

function FailoverThenSwitchoverToPeer() {
	Write-Host "Downing B's network and failing over"
	# fire off the script on B
	CallBsideScriptAsync $nodes[2] 
	
	Write-Host "Waiting on new cluster owner node"
	# wait for a few seconds to see that the cluster is no longer owned by node B
	$clusterGroup = Get-ClusterGroup "Available Storage"
	while( $clusterGroup.OwnerNode.Name -like $nodes[2] ) {
		Start-Sleep 1
		$clusterGroup = Get-ClusterGroup "Available Storage"
	}
	
	Write-Host "Waiting on Failover to " $clusterGroup.OwnerNode.Name " to complete"
	if( -Not $(waitOnClusterOnline) ) { Write-Warning Write-Warning "Cluster took longer than 5 minutes to online"; return }
	
	Write-Host "Verifying G is Resync Pending to B"
	# since B is disconnected, need to verify by looking at current OwnerNode's TargetList 
	$clusterGroup = Get-ClusterGroup "Available Storage"
	$volInfo = GetVolumeInfoUntilValid $clusterGroup.OwnerNode.Name $mirrorVol
	if( -Not $volInfo.TargetList[0].mirrorState -like "ResyncPending" ) { Write-Warning ($nodes[2] + " is not in Resync Pending State!"); return }
	
	# the second time this runs, it fails for some reason. Waiting seems to fix it.
	Start-Sleep 300
	
	# switchover to other shared peer based off which one is current OwnerNode
	$secondMoveNode = ""
	$secondMoveNodeIP = ""
	
	Write-Host "Switching over to shared peer (NOT " $clusterGroup.OwnerNode.Name")"
	if( $clusterGroup.OwnerNode.Name -like $nodes[0] ) {
		$clusterGroup | Move-ClusterGroup $nodes[1]
		$secondMoveNode = $nodes[1]
		$secondMoveNodeIP = $nodeIPs[1]
	} else {
		$clusterGroup | Move-ClusterGroup $nodes[0]
		$secondMoveNode = $nodes[0]
		$secondMoveNodeIP = $nodeIPs[0]
	}
	
	# verify G is Resync Pending on B
	# since B is disconnected, need to verify by looking at current OwnerNode's TargetList 
	Write-Host "Waiting on new owner node"
	$clusterGroup = Get-ClusterGroup "Available Storage"
	while( $cluster.OwnerNode.Name -like $nodes[2] ) {
		Start-Sleep 1
		$clusterGroup = Get-ClusterGroup "Available Storage"
	}
	
	Write-Host "Waiting on valid volume info from new owner node"
	$volInfo = GetVolumeInfoUntilValid $clusterGroup.OwnerNode.Name $mirrorVol
	
	Write-Host "Verifying resync pending"
	if( -Not $volInfo.TargetList[0].mirrorState -like "ResyncPending" ) { Write-Warning ($nodes[2] + " is not in Resync Pending State!"); return }
	
	Write-Host "waiting on B to reconnect..."
	while( -Not $(Test-Connection $nodes[2] -Quiet) ) {
		Start-Sleep 5
	}
		
	Write-Host "Waiting on B to rejoin the cluster..."
	$node = Get-ClusterNode $nodes[2]
	while( -Not $node.State -like "Up" ) {
		State-Sleep 1
		$node = Get-ClusterNode $nodes[2]
	}
	
	Write-Host "Waiting on the cluster to come Online"
	if( -Not $(waitOnClusterOnline) ) { Write-Warning Write-Warning "Cluster took longer than 5 minutes to online"; return }
	
	Write-Host "Waiting on valid volume info from B"
	$volInfo = GetVolumeInfoUntilValid $nodes[2] $mirrorVol

	Write-Host "Waiting for G on B to get to Mirror State"
	if( -Not $(waitOnMirrorState $volInfo) ) { Write-Warning ($nodes[2] + " took longer than 5 minutes to get to Mirror State!"); return } 
	
	Write-Host "Waiting for the cluster parameter for node B has reached a value of 1"
	$nodeState = $(get-clusterresource "DataKeeper Volume G" | Get-ClusterParameter "TargetState_LOGOTEST11").Value
	while( $nodeState -ne 1 ) {
		Start-Sleep 5
		$nodeState = $(get-clusterresource "DataKeeper Volume G" | Get-ClusterParameter "TargetState_LOGOTEST11").Value
	}

	# for good measure
	Start-Sleep 5
}

function CallBsideScriptAsync() {
	Param(
		[Parameter(Mandatory=$True, Position=0)]
		[string]$node
	)

	Start-Process PowerShell -NoNewWindow -ArgumentList .\Test-Bug3998_CallBside.ps1,$node
}


function WriteAsync() {
	Param(
		[Parameter(Mandatory=$True, Position=0)]
		[string]$node
	)
	Start-Process PowerShell -ArgumentList .\AsyncWrites.ps1,$node
}

# helper function for TestBug3998's GetTargetProperty helper function
function GetRemoteNameProperty() {
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
		[string]$target
	)
		
	return Invoke-Command -ComputerName $node -Credential $(getAdminCredentials) { Param($key) $key | Get-ItemProperty | foreach-object { $_.RemoteName } } -Args "hklm:\$target"
}

# run the test
TestBug3998

