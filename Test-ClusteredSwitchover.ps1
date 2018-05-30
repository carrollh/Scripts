# Test-ClusteredSwitchover.ps1
# Edit these variables
$clustergroup = Get-Clustergroup "NewRole"
$othernode="CAE-QA-V201"
$thisnode="CAE-QA-V200"
$vols=@("B", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z")

# Leave these as-is
$script_start_time = Get-Date
$destnode=$thisnode
$loop=1
$online =  [Microsoft.FailoverClusters.PowerShell.ClusterGroupState]::Online

while(1) {
	$loop_start_time = Get-Date
	"Start loop $loop.  Move everything to $destnode."
	$clustergroup | Move-Clustergroup -node $destnode

	while($clustergroup.state -ne $online) {
		Start-Sleep Seconds 15
	}

	Get-Date
	"Resources are online.  Check for error 196 in Application log."

	$ev = Get-Eventlog "Application" -ComputerName $destnode -After $loop_start_time | where-object {$_.EventId -eq 196 -and $_.Source -eq "ExtMirrSvc"}

	if($ev -ne $null) {
		"Found event ID 196 after moving resources to node $destnode.  Check event log."
		$d=Get-Date
		"Started $loop_start_date, Now it is $d"
	}

	"Sleep 10 minutes"
	for($i=0; $i -lt 10; $i++) {
		Start-Sleep -Seconds 60
		for($v=0; $v -lt $vols.Count; $v++) {
			$vol = $vols[$v]

			WriteFile -r -t -n \\$destnode\$vol$\x 30 > $null 2> $null
		}
	}

	if($destnode -eq $othernode) {
		$destnode = $thisnode
	} else {
		$destnode = $othernode
	}

	$loop++
}
