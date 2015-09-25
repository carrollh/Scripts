. .\Utilities_DK.ps1

function TestTemplate() {
	Param(
		[Parameter(Mandatory=$False)]
		[switch]$ComputerName = $verbose
	)

	#ReadDKConfig
	#GetDKConfig
	if($verbose) {
		CompareDKConfig $(ReadDKConfig) $(GetDKConfig) -Verbose
	}else {
		CompareDKConfig $(ReadDKConfig) $(GetDKConfig)
	}
}

# check that no jobs or mirrors exist on any DK system
function verifyPrerequisites() {
	
	# get all usable volumes from the service 
	$volumes = $(Get-DataKeeperServiceInfo).QualifyingVolumes
	$nodeList = New-Object System.Collections.Generic.List[System.String]
	$nodeList.Add("cae-qa-v55")
	$nodeList.Add("cae-qa-v56")
	$nodeList.Add("cae-qa-v53")
	
	$output = $True
	foreach( $node in $nodeList ) {
		$output = $(VerifyDKService $node $(GetAdminCredentials)) -and $output
	}
	if( $output -eq $False ) {
		Write-Host "Service not found on all nodes"
		return $False
	}
	
	#$list = New-Object 'system.collections.generic.list[Steeleye.Model.ModelObject]'
	$nodeJoblistDict = New-Object -TypeName "System.Collections.Generic.Dictionary[[string],[System.Collections.Generic.List[Steeleye.Model.ModelObject]]]" 
	foreach( $node in $nodeList ) {
		$nodeJoblistDict.Add($node,$(Get-DataKeeperJobList $node))
	}
	
	$failed = $False
	$nodeJoblistDict.Keys.GetEnumerator() | foreach-object {
		if( $nodeJoblistDict.$_ ) {
			Write-Warning ( "Prerequisites FAILED due to existing jobs on " + $_ )
			$failed = $True
		} 
	}	
	
	$nodeList | foreach-object {
		$mirrorList = FindDKMirrorsAllNodes $_
		foreach( $node in $mirrorList ) {
			if( $mirrorList.$node.Count -ne 0 ) {
				Write-Warning ( "Prerequisites FAILED due to existing mirror on " + $node )
				$failed = $True
			}
		} 
	}
	
	return -Not $failed
}

function assertTestResults() {
	Param(
		[Parameter(Mandatory=$True, Position=0)]
		[System.Object[]]$Test,
		
		[Parameter(Mandatory=$True, Position=1)]
		[bool]$Assertion,
		
		[Parameter(Mandatory=$True, Position=2)]
		[string]$TestName
	)
	
	if( $Test -like $Assertion ) {
		Write-Host $TestName " Passed"
	} else {
		Write-Warning ($TestName + " FAILED")
	}
}

#########################################################################################################
# BUG 3941
#########################################################################################################
function TestBug3941() {
	Param(
		[Parameter(Mandatory=$True)]
		[string]$Chap,
		
		[Parameter(Mandatory=$False)]
		[switch]$ComputerName = $verbose
	)

	#find the iscsi target on the system. ASSUMING ONLY ONE EXISTS
	$iVol = Get-IscsiTarget | where-object { $_.IsConnected -eq $true }
	
	if( -Not $iVol ) {
		Write-Warning "No iscsi volume detected"
		return $False
	}
	
	Write-Verbose("Disconnecting Iscsi volume...")
	Disconnect-IscsiTarget -NodeAddress $iVol.NodeAddress -Confirm:$False
	
	# wait 60 seconds to allow problems to propagate
	Start-Sleep 10
	
	# TODO: Actual testing goes here 
	
	if($verbose) {
		CompareDKConfig $(ReadDKConfig) $(GetDKConfig) -Verbose
	}else {
		CompareDKConfig $(ReadDKConfig) $(GetDKConfig)
	}
	
	
	Write-Verbose "Reconnecting iscsi volume..." # ONEWAYCHAP must be all caps
	Connect-IscsiTarget -AuthenticationType ONEWAYCHAP -ChapSecret $Chap -NodeAddress $iVol.NodeAddress

	return $True
}

#########################################################################################################
# BUG 3998
#########################################################################################################
function TestBug3998() {	
	Write-Verbose "Value of target 10.200.8.56's BitmapFileValid property: "
	GetTargetProperty 10.200.8.56 BitmapFileValid
}

# helper function for TestBug3998
function GetTargetProperty() {
	Param(
		[Parameter(Mandatory=$True, Position=0)]
		[string]$target,
		
		[Parameter(Mandatory=$True, Position=1)]
		[string]$property
	)
	$volumes = Get-ChildItem "hklm:\System\CurrentControlSet\Services\ExtMirr\Parameters\Volumes"
	$targetFolders = $volumes | foreach-object { Get-ChildItem "hklm:\$_" }
	$targets = $targetFolders | foreach-object { Get-ChildItem "hklm:\$_" }
	$targets
	$targetObject = $targets | where-object { ($_ | GetRemoteNameProperty) -eq $target }
	#$targetObject
	$properties = $targetObject | Get-ItemProperty
	
	return $properties.$property
}

# helper function for TestBug3998's GetTargetProperty helper function
function GetRemoteNameProperty() {
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
		[string]$target
	)
		
	return "hklm:\$target" | Get-ItemProperty | foreach-object { $_.RemoteName }
}

#########################################################################################################
# BUG 4008
#########################################################################################################
function TestBug4008() {
	Param(
		[Parameter(Mandatory=$False)]
		[string]$system = "."
	)
	Invoke-Command -ComputerName $system -Credential $(GetAdminCredentials) { $p=pwd; cd "$env:ExtMirrBase"; emcmd . getmirrorvolinfo f; cd $p.Path }
	
}