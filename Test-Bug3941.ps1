
function Test-Bug3941() {	
	$nodes = "logotest9.qatest.com","logotest10.qatest.com","logotest11.qatest.com","logotest12.qatest.com"
	$clusterGroup = Get-ClusterGroup "Available Storage"	
	$resources = $clusterGroup | Get-ClusterResource
	$volumes = $resources | Get-ClusterParameter | where-object { $_.Name -eq "VolumeLetter" }

	#find the iscsi target on the system. ASSUMING ONLY ONE EXISTS
	$iVol = Get-IscsiTarget | where-object { $_.IsConnected -eq $true }
	
	if( -Not $iVol ) {
		Write-Warning "No iscsi volume detected"
		return $False
	}
	
	Write-Verbose("Disconnecting Iscsi volume...")
	$disk = Get-IscsiSession | Get-Disk
	("select disk "+$disk.Number), "offline disk" | diskpart

	# wait 60 seconds to allow problems to propagate
	Start-Sleep 5
	
	Get-ClusterGroup "Available Storage" | Move-ClusterGroup $nodes[2]

	while( -Not $(Get-DataKeeperVolumeInfo $nodes[2] $volumes[0].Value).MirrorRole -like "Source" ) {
		Start-Sleep 1
	}

	Get-ClusterGroup "Available Storage" | Move-ClusterGroup $nodes[3]
		
	Write-Verbose "Reconnecting iscsi volume..." # ONEWAYCHAP must be all caps
	("select disk "+$disk.Number), "online disk" | diskpart
	
	return $True
}