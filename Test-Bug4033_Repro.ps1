# Test-Bug4033_Repro.ps1

. C:\Scripts\Utilities_DK.ps1

# USER DEFINED PARAMS
$nodes = "logotest9","logotest10","logotest11" # DONT include the FQDN or names wont match cluster node names!
$domain = "qatest.com"
$nodeIPs = "10.2.1.215","10.2.1.216","10.2.1.217"
$netAdapters = "Public","Private"
$mirrorVol = "E"

while( $True ) {

	Invoke-Command -ComputerName $nodes[2] -Credential $(getAdminCredentials) { Param($n0,$mV,$nip1) emcmd $n0 PAUSEMIRROR $mV $nip1 } -Args $nodes[0],$mirrorVol,$nodeIPs[1]
	
	Start-Sleep 8
	
	Invoke-Command -ComputerName $nodes[2] -Credential $(getAdminCredentials) { Param($n0,$mV) emcmd $n0 CONTINUEMIRROR $mV } -Args $nodes[0],$mirrorVol	
	
	Start-Sleep 10
	
	$volInfo = GetVolumeInfoUntilValid $nodes[0] $mirrorVol
	if( -Not $(waitOnMirrorState $volInfo) ) { Exit 1 } 
}

