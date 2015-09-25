#########################################################################################################
# BUG 3998 B Side Script
#########################################################################################################
	
$netAdapters = "Public","Private","iSCSI"
$mirrorVol = "G"

# Down ALL networks on B (this node)
Get-NetAdapter $netAdapters[2] | Disable-NetAdapter -Confirm:$False
Get-NetAdapter $netAdapters[1] | Disable-NetAdapter -Confirm:$False
Get-NetAdapter $netAdapters[0] | Disable-NetAdapter -Confirm:$False

# Give the A side script time to finish
Start-Sleep 120

# Re-up all the networks on B
Get-NetAdapter $netAdapters[2] | Enable-NetAdapter -Confirm:$False
Get-NetAdapter $netAdapters[1] | Enable-NetAdapter -Confirm:$False
Get-NetAdapter $netAdapters[0] | Enable-NetAdapter -Confirm:$False


	