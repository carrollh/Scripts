#########################################################################################################
# BUG 4033
#########################################################################################################

. .\Utilities_DK.ps1

# USER DEFINED PARAMS
$nodes = "logotest9","logotest10","logotest11" # DONT include the FQDN or names wont match cluster node names!
$domain = "qatest.com"
$nodeIPs = "10.2.1.215","10.2.1.216","10.2.1.217"
$netAdapters = "Public","Private"
$mirrorVol = "E"

function TestBug4033() {
	$reproProc = Repro
	Activity 1
	if( $reproProc.ExitCode -eq 1 ) { Write-Warning "Test-4033 FAILED"}
	else { 
		Write-Host "Test-4033 PASSED" 
		$reproProc | Stop-Process
	}
}

function Activity() {
	Param(
		[Parameter(Mandatory=$False,Position=0)]
		[Int32]$timeout = 3600
	)
	
	while( $timeout -gt 0 ) {
		(1..5) | foreach-object {
			writefile -r -s ($mirrorVol+":\bug4033_"+$_) 5
			Start-Sleep 4
		}
		
		Start-Sleep 10
		dir ($mirrorVol+":") > ($mirrorVol+":\files.out")
		
		$timeout -= 30
	}
	
	# TODO: Write-Host true or false	
}

function Repro() {
	return Start-Process PowerShell -PassThru -ArgumentList .\Test-Bug4033_Repro.ps1 
}

# run the script
TestBug4033