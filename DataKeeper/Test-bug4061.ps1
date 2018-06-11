cd $env:extmirrbase
$nodes = "cae-qa-v200","cae-qa-v201"
$ips = "10.200.8.200","10.200.8.201","10.200.8.202","10.200.8.203"
$vols = "E","F"
$badIP = "10.200.8.202"

Invoke-Expression -Command $PSScriptRoot\Remove-AllDataKeeperJobs.ps1

Write-Warning "the following should succeed"
New-DataKeeperJob vol.E test $nodes[0] $ips[0] $vols[0] $nodes[1] $ips[1] $vols[0] Async
Invoke-Expression -Command $PSScriptRoot\Remove-AllDataKeeperJobs.ps1
New-DataKeeperJob vol.F test $nodes[0] $ips[0] $vols[1] $nodes[1] $ips[1] $vols[1] async
Invoke-Expression -Command $PSScriptRoot\Remove-AllDataKeeperJobs.ps1
New-DataKeeperJob vol.E test $nodes[0] $ips[0] $vols[0] $nodes[1] $ips[1] $vols[0] "ASYNC"
Invoke-Expression -Command $PSScriptRoot\Remove-AllDataKeeperJobs.ps1
New-DataKeeperJob vol.E test $nodes[0] $ips[0] $vols[0] $nodes[1] $ips[1] $vols[0] Sync
Invoke-Expression -Command $PSScriptRoot\Remove-AllDataKeeperJobs.ps1
New-DataKeeperJob vol.E test $nodes[0] $ips[0] $vols[0] $nodes[1] $ips[1] $vols[0] sync
Invoke-Expression -Command $PSScriptRoot\Remove-AllDataKeeperJobs.ps1
New-DataKeeperJob vol.E test $nodes[0] $ips[0] $vols[0] $nodes[1] $ips[1] $vols[0] "SYNC"
Invoke-Expression -Command $PSScriptRoot\Remove-AllDataKeeperJobs.ps1
New-DataKeeperJob vol.F test $nodes[0] $ips[0] $vols[1] $nodes[1] $ips[1] $vols[1] Disk
Invoke-Expression -Command $PSScriptRoot\Remove-AllDataKeeperJobs.ps1
New-DataKeeperJob vol.E test $nodes[0] $ips[0] $vols[0] $nodes[1] $ips[1] $vols[0] disk
Invoke-Expression -Command $PSScriptRoot\Remove-AllDataKeeperJobs.ps1
New-DataKeeperJob vol.E test $nodes[0] $ips[0] $vols[0] $nodes[1] $ips[1] $vols[0] "Disk"
Invoke-Expression -Command $PSScriptRoot\Remove-AllDataKeeperJobs.ps1

Write-Warning "all of the following should fail"
New-DataKeeperJob vol.F test $nodes[0] $ips[0] $vols[1] cae-qa-v202 $vols[1] $ips[2] Async $nodes[0] $ips[0] $vols[1] cae-qa-v203 $vols[1] $ips[3] A cae-qa-v202 $vols[1] $ips[2] cae-qa-v203 $vols[1] $ips[3] A
New-DataKeeperJob vol.F test $nodes[0] $ips[0] $vols[1] cae-qa-v202 $vols[1] $ips[2] A $nodes[0] $ips[0] $vols[1] cae-qa-v203 $vols[1] $ips[3] Sync cae-qa-v202 $vols[1] $ips[2] cae-qa-v203 $vols[1] $ips[3] A
New-DataKeeperJob vol.F test $nodes[0] $ips[0] $vols[1] cae-qa-v202 $vols[1] $ips[2] A $nodes[0] $ips[0] $vols[1] cae-qa-v203 $vols[1] $ips[3] A cae-qa-v202 $vols[1] $ips[2] cae-qa-v203 $vols[1] $ips[3] Disk
New-DataKeeperJob vol.E test $nodes[0] $ips[0] $vols[0] $nodes[1] $ips[1] $vols[0] A
New-DataKeeperJob vol.E test $nodes[0] $ips[0] $vols[0] $nodes[1] $ips[1] $vols[0] a
New-DataKeeperJob vol.E test $nodes[0] $ips[0] $vols[0] $nodes[1] $ips[1] $vols[0] S
New-DataKeeperJob vol.E test $nodes[0] $ips[0] $vols[0] $nodes[1] $ips[1] $vols[0] s
New-DataKeeperJob vol.E test $nodes[0] $ips[0] $vols[0] $nodes[1] $ips[1] $vols[0] D
New-DataKeeperJob vol.E test $nodes[0] $ips[0] $vols[0] $nodes[1] $ips[1] $vols[0] d
New-DataKeeperJob vol.E test $nodes[0] $ips[0] $vols[0] $nodes[1] $ips[1] $vols[0] Arg
New-DataKeeperJob vol.E test $nodes[0] $ips[0] $vols[0] $nodes[1] $ips[1] $vols[0] spit
New-DataKeeperJob vol.E test $nodes[0] $ips[0] $vols[0] $nodes[1] $ips[1] $vols[0] doh
New-DataKeeperJob vol.E test $nodes[0] $ips[0] $vols[0] $nodes[1] $ips[1] $vols[0] pie
New-DataKeeperJob vol.E test $nodes[0] $ips[0] $vols[0] $nodes[1] $ips[1] $vols[0] $
New-DataKeeperJob vol.E test $nodes[0] $ips[0] $vols[0] $nodes[1] $ips[1] $vols[0] .
New-DataKeeperJob vol.E test $nodes[0] $ips[0] $vols[0] $nodes[1] $ips[1] $vols[0] " "
New-DataKeeperJob vol.E test $nodes[0] $ips[0] $vols[0] $nodes[1] $ips[1] $vols[0] ""
New-DataKeeperJob vol.E test $nodes[0] $ips[0] $vols[0] $nodes[1] $ips[1] $vols[0] ' '

cd $PSScriptRoot

