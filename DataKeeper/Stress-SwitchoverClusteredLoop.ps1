# Stress-SwitchoverClusteredLoop.ps1
# A recommended method of running this would be
# > .\Stress-SwitchoverClusteredLoop.ps1 | Tee-Object Stress-SwitchoverClusteredLoop.log

Param(
	[Parameter(Mandatory=$False)]
	[string[]] $NodeArray = @("cae-qa-v204","cae-qa-v205"),
	
	[Parameter(Mandatory=$False)]
	[string] $ClusterGroup = "volE",

	[Parameter(Mandatory=$False)]
	[Int32] $LoopCount = 100
)


# Find all cluster nodes and the cluster group. We're assuming 
# that only a single cluster exists, and it contains all nodes.

if($NodeArray -eq $null) {
	$NodeArray = Get-ClusterNode
}
if($ClusterGroup -eq $null) {
	$ClusterGroup = Get-ClusterGroup "Available Storage"
}

Write-Host "switching over $ClusterGroup"

if($ClusterGroup -eq $null) {
	Write-Warning "Cluster not found!"
	Exit
}


$resources = Get-ClusterGroup $ClusterGroup | Get-ClusterResource
$volumes = $resources | foreach { $_ | Get-ClusterParameter | where-object { $_.Name -eq "VolumeLetter" } }

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
		Invoke-Command -ComputerName (Get-ClusterGroup $ClusterGroup).OwnerNode.Name { Param($m,$p) $m | Out-File -FilePath $p } -ArgumentList $message,$path
	}

	# wait to make sure things propagate
	Start-Sleep -s 1

	# check all the target states seen on all volumes on all nodes
	foreach ( $clusterNode in $NodeArray ) {
		Write-Host $clusterNode
	
		# loop over all the volumes to make sure they are still mirroring
		foreach( $volume in $volumes ) {
			$dkVolumeInfo = ""

			# get info that this node sees for this volume
			$volInfo = Get-DataKeeperVolumeInfo -Node $clusterNode -Volume $volume.Value
			
			# fail the test if any target isn't mirroring
			foreach( $target in $volInfo.TargetList ) {
				$areTargetsMirroring = $areTargetsMirroring -and ($target.mirrorState -eq "Mirror")
                #just the verbose output gets sent to file below in the main body
                $dkVolumeInfo += $($stdout = Get-DataKeeperVolumeInfo $target.TargetSystem $volume.Value -Verbose) 4>&1
            }
			$volInfo

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
	foreach ( $node in $NodeArray ) {
		if( (Get-ClusterGroup $ClusterGroup).OwnerNode -ne $node ) {
			Move-ClusterGroup -Name $ClusterGroup -Node $node 
			Start-Sleep 10
			$counter += 1
			Write-Host "Test " $counter "New OwnerNode: " (Get-ClusterGroup $ClusterGroup).OwnerNode.Name
	
			if( (Get-ClusterGroup $ClusterGroup).State -eq "Online" ) {
				Write-Host Online
				if( Test-DKVolumeStates ) { 
					Add-Content Test-SwitchoverClusteredLoop.log ("TEST PASSED: " + $dkVolumeInfo)
					$dkVolumeInfo = ""
				} else {
					Write-Host "TEST FAILED: $dkVolumeInfo"
					Add-Content Test-SwitchoverClusteredLoop.log ("TEST FAILED: " + $dkVolumeInfo)
					Exit
				}
			} else {
				Write-Host "TEST FAILED: Cluster Failed to Online"
				Add-Content Test-SwitchoverClusteredLoop.log ("TEST FAILED: Cluster Failed to Online" )
				Exit
			}
		}
	}
}