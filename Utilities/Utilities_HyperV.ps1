# Helper functions for use in testing

function CheckIfAdmin() {
	# Get the ID and security principal of the current user account
	$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
	$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)

	# Get the security principal for the Administrator role
	$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator

	# Check to see if we are currently running "as Administrator"
	return ($myWindowsPrincipal.IsInRole($adminRole))
}

function FailVM() {
	Param(
		[Parameter(Mandatory=$True,Position=1)]
		[string]$ComputerName
	)

	Write-Verbose("Verifying prerequisites...")
	
	#fail if not running as administrator
	if( -Not (CheckIfAdmin) ) {
		Write-Warning "This cmdlet must be run as administrator."
		return $False
	}
	
	$vm = Get-VM $ComputerName
	
	# fail attempt if vm not running
	if( $vm.State -ne "Running" ) {
		Write-Warning ($ComputerName + " is not running.")
		return $False
	}
	
	Write-Verbose("Hard failing " + $ComputerName + "...")
	Stop-VM -VM $vm -TurnOff
	
	Write-Verbose("Verifying " + $ComputerName + " is offline...")
	while( $vm.State -ne "Off" ) {
		Start-Sleep 1
	}
	
	return $True
}

function StartVM() {
	Param(
		[Parameter(Mandatory=$True)]
		[string]$ComputerName,
		
		[Parameter(Mandatory=$False)]
		[switch]$CheckDK,
		
		[Parameter(Mandatory=$False)]
		[switch]$CheckLK
	)
	
	Write-Verbose("Verifying prerequisites...")
	
	#fail if not running as administrator
	if( -Not (CheckIfAdmin) ) {
		Write-Warning "This cmdlet must be run as administrator."
		return $False
	}
	
	$vm = Get-VM $ComputerName
	
	# fail attempt if vm isn't offline
	if( $vm.State -ne "Off" ) {
		Write-Warning ($ComputerName + " is not offline.")
		return $False
	}
	
	Write-Verbose("Starting " + $ComputerName + "...")
	Start-VM -VM $vm
	
	Write-Verbose("Verifying " + $ComputerName + " came back online...")
	while( $vm.State -ne "Running" ) {
		Start-Sleep 1
	}
	
	Write-Verbose("Verifying " + $ComputerName + " is responding...")
	while( -Not (Test-Connection $ComputerName -Quiet) ) {
		Write-Verbose("...")
		Start-Sleep 1
	}
	
	if( $CheckDK ) {
		VerifyDK $ComputerName
	}
	if( $CheckLK ){
		VerifyLK $ComputerName
	}

	return $True
}

function VerifyDK() {
	Param(
		[Parameter(Mandatory=$True)]
		[string]$ComputerName,
		
		[Parameter(Mandatory=$False)]
		[PSCredential]$Credential
	)
	try {
		$svc = Get-Service -ComputerName "2016-B1" -Credential $Credential -Name "ExtMirrSvc"
#		$svc = Invoke-Command -ComputerName $ComputerName -Credential $Credential { Get-Service "ExtMirrSvc" }
		Write-Verbose "Waiting on DataKeeper service to start..."
		while( $svc.Status -ne "Running" ) {
			Start-Sleep 5
			Write-Verbose "..."
		}
		
		return $True
	} catch {
		if ( $error[0].Exception -match "Microsoft.PowerShell.Commands.ServiceCommandException") {
			Write-Warning("DataKeeper service not found on " + $ComputerName)
		}
		else
		{
		}
		return $False
	}
	return $False
}

function VerifyLK() {
	Param(
		[Parameter(Mandatory=$True,Position=1)]
		[string]$ComputerName
	)
	
	
}

function FailAndUp() {
	Param(
		[Parameter(Mandatory=$True)]
		[string]$ComputerName,
		
		[Parameter(Mandatory=$False)]
		[switch]$CheckDK,
		
		[Parameter(Mandatory=$False)]
		[switch]$CheckLK
	)
	
	if( FailVM $ComputerName ) {
		if( StartVM $ComputerName -CheckDK $CheckDK -CheckLK $CheckLK ) {
			Write-Verbose ($ComputerName + " power cycled.")
		} else {
			Write-Warning ("Failed to bring " + $ComputerName + " online successfully.")
		}
	} else {
		Write-Warning ("Failed to turn off " + $ComputerName)
	}
}
