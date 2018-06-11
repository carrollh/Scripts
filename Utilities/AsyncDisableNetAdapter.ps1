Param(
	[Parameter(Mandatory=$True,Position=0)]
	[string]$targetNode,
	
	[Parameter(Mandatory=$True,Position=0)]
	[string]$netAdapter
)

. C:\Scripts\Utilities_DK.ps1

Invoke-Command -ComputerName $targetNode -Credential $(getAdminCredentials) -Script { param($adapter) Get-NetAdapter $adapter | Disable-NetAdapter -Confirm:$False } -Args $netAdapter
