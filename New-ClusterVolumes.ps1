# New-ClusterVolumes.ps1

$vols = @("B", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z")
$group = "NewRole"

for($i=0; $i -lt $vols.Count; $i++) {
	$vol = $vols[$i]

	& "$env:extmirrbase\emcmd" . registerclustervolume $vol

	$res = Add-ClusterResource -Name "DataKeeper Volume $vol" -ResourceType "DataKeeper Volume" -Group "$group"

	$res | Set-Clusterparameter "VolumeLetter" "$vol"
}