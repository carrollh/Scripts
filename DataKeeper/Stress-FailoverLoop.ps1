# Test-FailoverLoop.ps1
# A recommended method of running this would be
# > Test-FailoverLoop.ps1 | Tee-Object Test-FailoverLoop.log

# Find all cluster nodes and the cluster group. We're assuming 
# that only a single cluster exists, and it contains all nodes.
$nodeArray = Get-ClusterNode 
$clusterGroup = Get-ClusterGroup "Available Storage"

if($clusterGroup -eq $null) {
	Write-Warning "Cluster not found!"
	Exit
}

$resources = $clusterGroup | Get-ClusterResource
$volumes = $resources | Get-ClusterParameter | where-object { $_.Name -eq "VolumeLetter" }

function prolongedTestDkVolumesInMirroringState() {
	Param(
		[Parameter(Mandatory=$True, Position=0)]
		[int]$duration,
			
		[Parameter(Mandatory=$True, Position=1)]
		[string]$message
	)
	$areTargetsMirroring = $False
	$timeout = 0
	$inc = $duration / 60
	while( ($areTargetsMirroring -ne $True) -and ($timeout -lt $duration) ) {
		$areTargetsMirroring = $True
		[System.Int32]$min = $timeout/60+1
		
		Write-Progress -Activity ($min.ToString() + "/" + $inc.ToString() + " : " + $message) -PercentComplete ($timeout%60/$duration*100)
		Start-Sleep -Seconds 5
		$timeout += 5
		
		# check all the target states seen on all volumes on all nodes
		foreach ( $clusterNode in $nodeArray ) {
		
			# loop over all the volumes to make sure they are still mirroring
			foreach( $volume in $volumes ) {

				# get info that this node sees for this volume
				$volInfo = Get-DataKeeperVolumeInfo $clusterNode.Name $volume.Value
				
				# fail the test if any target isn't mirroring
				foreach( $target in $volInfo.TargetList ) {
					$areTargetsMirroring = $areTargetsMirroring -and ($target.mirrorState -eq "Mirror")
				}
			}
		}
	}

	if( $duration -lt $timeout ) {
		("DataKeeper failed to resync within " + $duration + " seconds.")
		$areTargetsMirroring = $False
	}
	
	return $areTargetsMirroring
}


$counter = 0;
# Helper function for failover loop. Just tests to make sure
# DataKeeper volumes are seeing the appropriate states. Writes
# out data to allow following it. 
function Test-DKVolumeStates() {
	
	# wait to make sure the cluster is fully online and DK volumes have finished 
	# resyncing before trying to write to them
	prolongedTestDkVolumesInMirroringState 300 "Giving DataKeeper time to finish resyncing mirrors..."
	
	#write to each source volume to trigger a pause if possible
	foreach( $volume in $volumes ) {	
		$path = $volume.Value + ":\FailLoop5.log"
		$message = ("Test " + $counter + ": " + $(Get-Date))
		Invoke-Command -ComputerName $clusterGroup.OwnerNode.Name { {$message} | Out-File -FilePath {$path} }
	}

	# wait to make sure things propagate
	$areTargetsMirroring = prolongedTestDkVolumesInMirroringState 300 "Waiting for writes to finish and DataKeeper to finish resync operations..."
		
	Write-Host "Test " $counter " New OwnerNode: " $clusterGroup.OwnerNode.Name
	# check all the target states seen on all volumes on all nodes
	foreach ( $clusterNode in $nodeArray ) {
		Write-Host $clusterNode
		
		# loop over all the volumes to make sure they are still mirroring
		foreach( $volume in $volumes ) {
			$dkVolumeInfo = " "

			# get info that this node sees for this volume
			$volInfo = Get-DataKeeperVolumeInfo $clusterNode.Name $volume.Value
			
			# fail the test if any target isn't mirroring
			foreach( $target in $volInfo.TargetList ) {
				$dkVolumeInfo += $($stdout = Get-DataKeeperVolumeInfo $clusterNode.Name $volume.Value -Verbose) 4>&1
				$dkVolumeInfo += " "
			}
			
			Write-Host $dkVolumeInfo
		}
	}

	Write-Host "`n"
	return $areTargetsMirroring
}

# helper function used to write the admin's secure password to file for GetAdminCredentials
# Not used anywhere anymore
function WriteSecurePassword() {
	$password = "*******"
	$securePassword = ConvertTo-SecureString $password -AsPlainText -Force 
	$securePassword | ConvertFrom-SecureString | Set-Content ".\password" 
}

# Reads secure password from file and returns a PSCredential for the domain admin
# Used for Invoke-Command/winrm on the other DK nodes.
function GetAdminCredentials() {
	$password = Get-Content ".\password" | ConvertTo-SecureString
	return New-Object System.Management.Automation.PSCredential "qagroup\administrator",$password
}

# Continuously loops over the nodes in nodeArray failing the network connections on
# the owner node, and immediately bringing them back. It then waits to make sure
# the new owner node is online and fails over by down-uping its network adatpers.
# This should cause a failover repeatedly, but it may only failover between 2 of the
# nodes over and over depending on setup.
while($true) {
	foreach ( $node in $nodeArray ) {
		if( $clusterGroup.OwnerNode -eq $node ) {
			# down-up the network on the source/owner node
			# This will appear to hang because the connection is lost and needs to be 
			# reestablished. PowerShell will do this automatically.
			Invoke-Command -ComputerName $node.Name -Credential $(GetAdminCredentials) { netsh interface set interface name="LAN1 - Public" admin=disabled;netsh interface set interface name="LAN3 - Private" admin=disabled;netsh interface set interface name="LAN1 - Public" admin=enabled;netsh interface set interface name="LAN3 - Private" admin=enabled }
						
			# wait for cluster to report online
			$sleepTime = 0
			while( ($clusterGroup.State -ne "Online") ){#}-and ($sleepTime -lt 300) ) {
				Start-Sleep 3
				$sleepTime += 3
			}
			if( $sleepTime -gt 299 ) {
				Write-Warning "Cluster took longer than 5 minutes to online"
				#Exit
			}
			$counter += 1
			$clusterGroup = Get-ClusterGroup "Available Storage"
			
			# Verify mirror states and either fail or let us loop again
			if( $clusterGroup.State -eq "Online" ) {
				if( Test-DKVolumeStates ) { 
					#Add-Content Test-FailoverLoop.log ("TEST PASSED: " + $dkVolumeInfo)
					$dkVolumeInfo = ""
				} else {
					#Add-Content Test-FailoverLoop.log ("TEST FAILED: " + $dkVolumeInfo)
					Write-Warning "TEST FAILED: " $dkVolumeInfo
					Exit
				}
			} else {
				#Add-Content Test-FailoverLoop.log ("TEST FAILED: Cluster Failed to Online" )
				Write-Warning "TEST FAILED: Cluster Failed to Online"
				Exit
			}
		}
	}
}