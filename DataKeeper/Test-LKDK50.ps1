Write-Warning "Run 'Get-Job | foreach { Stop-Job `$_ }' to stop the threads started by this script."
(1..10) | foreach {
	Start-Job -FilePath "$PSScriptRoot\Help-LKDK50.ps1"
	Start-Sleep 1
}

