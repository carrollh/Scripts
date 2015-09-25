Param(
	[Parameter(Mandatory=$True, Position=0)]
	[string]$target
)

. .\Utilities_DK.ps1

Invoke-Command -ComputerName $target -Credential $(getAdminCredentials) -FilePath .\Test-Bug3998_Bside.ps1
	