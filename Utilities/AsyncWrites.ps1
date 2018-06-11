Param(
	[Parameter(Mandatory=$True,Position=0)]
	[string]$targetNode
)

. C:\Scripts\Utilities_DK.ps1

Invoke-Command -ComputerName $targetNode -Credential $(getAdminCredentials) { writefile.exe -t G:\test 50000k }
