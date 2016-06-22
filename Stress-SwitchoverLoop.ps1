# Test-SwitchoverClusteredLoop.ps1
# A recommended method of running this would be
# > Stress-SwitchoverLoop.ps1 | Tee-Object Stress-SwitchoverLoop.log

# Find all cluster nodes and the cluster group. We're assuming 
# that only a single cluster exists, and it contains all nodes.
Param(
	[Parameter(Mandatory=$False)]
	[System.Array]$nodeArray,
	
	[Parameter(Mandatory=$False)]
	[System.Array]$clusterGroup
)

if($nodeArray -eq $null) {
	$nodeArray = Get-ClusterNode
}
if($clusterGroup -eq $null) {
	$clusterGroup = Get-ClusterGroup "Available Storage"
}

Write-Host "switching over $clusterGroup"

if($clusterGroup -eq $null) {
	Write-Warning "Cluster not found!"
	Exit
}

$resources = $clusterGroup | Get-ClusterResource
$volumes = $resources | Get-ClusterParameter | where-object { $_.Name -eq "VolumeLetter" }

$counter = 0;
# Helper function for switchover loop. Just tests to make sure
# DataKeeper volumes are seeing the appropriate states. Writes
# out data to allow following it. 
function Test-DKVolumeStates {
	$areTargetsMirroring = $true

	#write to each source volume to trigger a pause if possible
	foreach( $volume in $volumes ) {	
		$path = $volume.Value + ":\SwitchoverClusteredLoop.log"
		$message = ("Test " + $counter + ": " + $(Get-Date))
		Invoke-Command -ComputerName $clusterGroup.OwnerNode.Name { {$message} | Out-File -FilePath {$path} }
	}

	# wait to make sure things propagate
	Start-Sleep -s 90

	# check all the target states seen on all volumes on all nodes
	foreach ( $clusterNode in $nodeArray ) {
		Write-Host $clusterNode
	
		# loop over all the volumes to make sure they are still mirroring
		foreach( $volume in $volumes ) {
			$dkVolumeInfo = ""

			# get info that this node sees for this volume
			$volInfo = Get-DataKeeperVolumeInfo $clusterNode.Name $volume.Value
			
			# fail the test if any target isn't mirroring
			foreach( $target in $volInfo.TargetList ) {
				$areTargetsMirroring = $areTargetsMirroring -and ($target.mirrorState -eq "Mirror")
			}
			
			#just the verbose output gets sent to file below in the main body
			$dkVolumeInfo += $($stdout = Get-DataKeeperVolumeInfo $target.TargetSystem $volume.Value -Verbose) 4>&1

			Write-Host $dkVolumeInfo
		}
	}
	
	Write-Host "`n"
	return $areTargetsMirroring
}

# Continuously loop over the nodes switching ownership to the 
# next one in the nodeArray. This should allow this to work for
# clusters of any size without needing an addtional script.
while($true) {
	foreach ( $node in $nodeArray ) {
		if( $clusterGroup.OwnerNode -ne $node ) {
			$clusterGroup | Move-ClusterGroup -Node $node
			$counter += 1
			Write-Host "Test " $counter "New OwnerNode: " $clusterGroup.OwnerNode.Name
	
			if( $clusterGroup.State -eq "Online" ) {
				if( Test-DKVolumeStates ) { 
					Add-Content Test-SwitchoverClusteredLoop.log ("TEST PASSED: " + $dkVolumeInfo)
					$dkVolumeInfo = ""
				} else {
					Add-Content Test-SwitchoverClusteredLoop.log ("TEST FAILED: " + $dkVolumeInfo)
					Exit
				}
			} else {
				Add-Content Test-SwitchoverClusteredLoop.log ("TEST FAILED: Cluster Failed to Online" )
				Exit
			}
		}
	}
}