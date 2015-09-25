# GLOBAL VARIABLES

# file location for config data storage and retrieval
# this file is hidden if it exists
$path = $env:temp + "\dkconfig.json"

# END GLOBAL VARIABLES

# helper function used to write the admin's secure password to file for GetAdminCredentials
# Not used anywhere anymore
function WriteSecurePassword() {
	$password = "lk"
	$securePassword = ConvertTo-SecureString $password -AsPlainText -Force 
	$securePassword | ConvertFrom-SecureString | Set-Content ".\password" 
}

# Reads secure password from file and returns a PSCredential for the domain admin
# Used for Invoke-Command/winrm on the other DK nodes.
function getAdminCredentials() {
	$password = Get-Content ".\password" | ConvertTo-SecureString
	return New-Object System.Management.Automation.PSCredential "qatest\administrator",$password
}

# checks the status of ExtMirrSvc on a provided system
# if no system is provided it will run locally
function VerifyDKService() {
	Param(
		[Parameter(Mandatory=$False)]
		[string]$ComputerName = ".",
		
		[Parameter(Mandatory=$False)]
		[PSCredential]$Credential
	)

	try {
		Write-Verbose "Verifying DataKeeeper service..."
		$svc
		if($Credential) {
			$svc = Get-Service -ComputerName $computerName -Credential $Credential -Name "ExtMirrSvc" -ErrorAction "Stop"
		} else {
			$svc = Get-Service -ComputerName $computerName -Name "ExtMirrSvc" -ErrorAction "Stop"
		}
		
		if($svc) {
			if( $svc.Status -eq "Running" ) {
				Write-Verbose "DataKeeper service running"
				return $True
			} else {
				Write-Verbose "DataKeeper service not running"
				return $False
			}
			
		}
	} catch {
		if ( $error[0].Exception -match "Microsoft.PowerShell.Commands.ServiceCommandException") {
			Write-Warning("DataKeeper service not found on " + $ComputerName)
		}
	}
	return $False
}

# query ExtMirrSvc on a provided system for all known info
# if no system is provided it will run locally
function GetDKConfig() {	
	Param(
		[Parameter(Mandatory=$False)]
		[string]$ComputerName = "."
	)
	
	$mirrorProperties = @{Volume="E";Target="10.200.8.56";State="Mirroring"}
	$mirror = New-PSCustomObject -Property $mirrorProperties -DefaultProperties Volume,Target,State
	
	return $mirror
} 
	
# read from cfg file to set script variables
function ReadDKConfig() {
	# verify config file exists
	if( Test-Path $path ) {
		# un-json-ify the input from file
		$psobj = (Get-Content $path) -join "`n" | ConvertFrom-Json
		return $psobj
	} else {
		Write-Warning "No previous configuration data can be found."
		return $NUL
	}
}
	
# converts config data table to json data, then saves it in the config file
# fails if no config data is passed to it
function WriteDKConfig() {
	# TODO: create mandatory param that takes a config object as input
	# dummy config data
	$mirrorProperties = @{Volume="E";Target="10.200.8.56";State="Mirroring"}
	$mirrors = New-PSCustomObject -Property $mirrorProperties -DefaultProperties Volume,Target,State

	# json-ify our config data
	$json = $mirrors | ConvertTo-Json
	$json

	# write json-ified data to file
	$json | Out-File $path
}

# 
function CompareDKConfig() {
	Param(
		[Parameter(Mandatory=$True, Position=0)]
		[PSCustomObject]$oldcfg,
		
		[Parameter(Mandatory=$True, Position=1)]
		[PSCustomObject]$currentcfg
	)
	
	# because powershell is inane, using " around variables causes the -eq stupidity to extend to properties 
	if( "$oldcfg" -eq "$currentcfg" ) {
		Write-Verbose "Configurations identical"
	} else {
		Write-Warning ("Configurations differ " + $(Get-Date))
		$oldcfg	
		$currentcfg
	}
}

# Reports all active mirrors on the node being run on.
function FindDKMirrorsAllNodes() {
	Param(
		[Parameter(Mandatory=$False, Position=0)]
		[string]$Node = $env:ComputerName
	)
	
	$mirrorList = @{}
	findDKMirrorsOnNode $mirrorList $Node
	
	return $mirrorList
}

# Recursive function started by FindDKMirrorsAllNodes. Finds all active mirrors by 
# scanning through the TargetList of all qualifying volumes on the node.
function findDKMirrorsOnNode() {
	Param(
		[Parameter(Mandatory=$True, Position=0)]
		[Hashtable]$mirrorList,
		
		[Parameter(Mandatory=$True, Position=1)]
		[string]$node,
		
		[Parameter(Mandatory=$False, Position=2)]
		[System.Collections.Generic.List[string]]$visited
	)

	$mirrorList.($node.ToUpper()) = @{}
	
	if( -Not $visited ) {
		$visited = New-Object -TypeName System.Collections.Generic.List[string]
	}
	$visited.Add($node.ToUpper())
	
	$svc = Get-DataKeeperServiceInfo $node
	$volumes = $svc.QualifyingVolumes
	
	$volumes | foreach-object {
		if( -Not ($mirrorList.$node.Contains( $_.ToUpper() )) ) {
			$volInfo = Get-DataKeeperVolumeInfo $node $_
			if( $volInfo.MirrorRole -ne "None" ) {
				$mirrorList.$node.Add( $_.ToUpper(), $(New-Object -TypeName System.Collections.Generic.List[string]) )
				foreach( $target in $volInfo.TargetList ) {
					$hostname = resolveIPtoComputerName $target.targetSystem
					if( -Not ($visited.Contains( $hostname )) ){
						findDKMirrorsOnNode $mirrorList $hostname $visited
					}
				}
			}
		}
	}
}

function resolveIPtoComputerName() {
	Param(
		[Parameter(Mandatory=$True, Position=0)]
		[string]$IPAddress
	)
	try {
		$hostname = $([Net.DNS]::GetHostEntry( $IPAddress )).HostName 
	} catch {
		Write-Verbose "Exception Caught"
	}
	$dotIndex = $hostname.IndexOf(".")
	return $hostname.Substring(0,$dotIndex).ToUpper()
}

function deleteAllJobs() {
	$nodeList = New-Object System.Collections.Generic.List[System.String]
	$nodeList.Add("logotest9")
	$nodeList.Add("logotest10")
	$nodeList.Add("logotest11")
	$nodeList.Add("logotest12")
	$nodeJoblistDict = New-Object -TypeName "System.Collections.Generic.Dictionary[[string],[System.Collections.Generic.List[Steeleye.Model.ModelObject]]]" 
	foreach( $node in $nodeList ) {
		$nodeJoblistDict.Add($node,$(Get-DataKeeperJobList $node))
	}
	
	$removedList = New-Object -TypeName "System.Collections.Generic.List[string]"
	$nodeList | foreach-object {
		if( $nodeJobListDict.$_.Count -ne 0 ) {
			foreach( $job in $nodeJobListDict.$_ ) {
				if( -Not $removedList.Contains( $job.JobId )) {
					$removedList.Add( $job.JobId )
					Remove-DataKeeperJob $job.JobId $_ > $Null
				}
			}
		}
	}
}

function deleteAllMirrors() {
	$nodeList = New-Object System.Collections.Generic.List[System.String]
	$nodeList.Add("logotest9")
	$nodeList.Add("logotest10")
	$nodeList.Add("logotest11")
	$nodeList.Add("logotest12")
	
	$nodeMirrorListDict = New-Object -TypeName "System.Collections.Generic.Dictionary[[string],[System.Collections.Generic.Dictionary[[string],[DKPwrShell.Mirror]]]]]" 
	foreach( $node in $nodeList ) {
		$nodeMirrorListDict.Add($node,$(Get-DataKeeperConfiguration $node))
	}
	
	foreach($node in $nodeMirrorListDict) {
		foreach($key in $node.Keys.GetEnumerator()) {
			$nodeMirrorListDict.$key.Keys.GetEnumerator() | foreach-object {
				if( $nodeMirrorListDict.$key.$_.sRole -like "Source" ) {
					Remove-DataKeeperMirror $key $_ > $Null
				}
			}
		}
	}
}

function findAllMirrorSources() {
	$nodeList = New-Object System.Collections.Generic.List[System.String]
	$nodeList.Add("CAE-QA-V55")
	$nodeList.Add("CAE-QA-V56")
	$nodeList.Add("CAE-QA-V53")
	
	$nodeMirrorListDict = New-Object -TypeName "System.Collections.Generic.Dictionary[[string],[System.Collections.Generic.Dictionary[[string],[DKPwrShell.Mirror]]]]]" 
	foreach( $node in $nodeList ) {
		$nodeMirrorListDict.Add($node,$(Get-DataKeeperConfiguration $node))
	}
	
#	$output = New-Object -TypeName "System.Collections.Generic.Dictionary[[string],[System.Colections.Generic.List[string]]]"
	foreach($node in $nodeMirrorListDict) {
		foreach($key in $node.Keys.GetEnumerator()) {
			$nodeMirrorListDict.$key.Keys.GetEnumerator() | foreach-object {
				if( $nodeMirrorListDict.$key.$_.sRole -like "Source" ) {
					Write-Host $key $_
				}
			}
		}
	}
}

function RemoveDataKeeperResources(){
	Param(
		[Parameter(Mandatory=$False, Position=0)]
		[string]$Node = $env:ComputerName
	)
	
	$mirrorList = FindDKMirrorsAllNodes $Node
	$mirrorList.Keys | foreach-object {
		removeDKMirrorsOnNode $mirrorList $_
	}
	$mirrorList.Keys | foreach-object {
		$joblist = Get-DataKeeperJobList $_
		foreach( $job in $joblist ) {
			Remove-DataKeeperJob $job.JobId $_ 
		}
	}
	
	return $mirrorList
}

function removeDKMirrorsOnNode() {
	Param(
		[Parameter(Mandatory=$True, Position=0)]
		[Hashtable]$mirrorList,
		
		[Parameter(Mandatory=$True, Position=1)]
		[string]$node
	)

	$mirrorList.$node.GetEnumerator() | foreach-object {
		$volInfo = Get-DataKeeperVolumeInfo $node $_.Name
		if( $volInfo.MirrorRole -eq "Source" ) {
			Remove-DataKeeperMirror $node $_.Name
		}		
	}
}

function waitOnMirrorState() {
	Param(
		[Parameter(Mandatory=$True,Position=0)]
		[string]$node,
		
		[Parameter(Mandatory=$True,Position=0)]
		[string]$volume
	)

	$volInfo = Get-DataKeeperVolumeInfo $node $volume
	$sleepTime = 0
	while( -Not $volInfo.TargetList[0].mirrorState -like "Mirror" -And $sleepTime -lt 300 ) { 
		Start-Sleep 3
		$sleepTime += 3 
		$volInfo = Get-DataKeeperVolumeInfo $node $volume
	}
	if( $sleepTime -gt 299 ) {
		return $False
	}
	
	return $True
}

function waitOnClusterOnline() {
	$clusterGroup = Get-ClusterGroup "Available Storage"
	$sleepTime = 0
	while( -Not $clusterGroup.State -like "Online" -And $sleepTime -lt 300 ) {
		Start-Sleep 3
		$sleepTime += 3
	}
	if( $sleepTime -gt 299 ) {
		return $False
	}
	
	return $True
}

function waitOnPausedState() {
	Param(
		[Parameter(Mandatory=$True,Position=0)]
		[SteelEye.Model.DataReplication.VolumeInfo]$volInfo
	)
	
	$sleepTime = 0
	while( -Not $volInfo.TargetList[0].mirrorState -like "Paused" -And $sleepTime -lt 300 ) { 
		Start-Sleep 3
		$sleepTime += 3 
	}
	if( $sleepTime -gt 299 ) {
		return $False
	}
	
	return $True
}

function waitOnPausedTargets() {
	Param(
		[Parameter(Mandatory=$True,Position=0)]
		[SteelEye.Model.DataReplication.VolumeInfo]$volInfo
	)
	
	$sleepTime = 0
	while( (-Not $volInfo.TargetList[0].mirrorState -like "Paused" -Or -Not $volInfo.TargetList[1].mirrorState -like "Paused") -And $sleepTime -lt 300 ) { 
		Start-Sleep 3
		$sleepTime += 3 
	}
	if( $sleepTime -gt 299 ) {
		return $False
	}
	
	return $True
}

function GetVolumeInfoUntilValid() {
	Param(
		[Parameter(Mandatory=$True, Position=0)]
		[string]$node,
		
		[Parameter(Mandatory=$True, Position=1)]
		[string]$volume
	)
	
	$vi = $null
	$timeout = 300
	while( -Not $vi -And $timeout -gt 0 ) {
		dir ("\\"+$node+"\C$") > $NUL
		Start-Sleep 5
		$timeout -= 5
		$vi = Get-DataKeeperVolumeInfo $node $volume
	}
	if( $timeout -lt 0 ) { Write-Warning "Timed out trying to fetch vol info"; Exit }
	
	return $vi
}

function GetCounterUntilValid() {
	Param(
		[Parameter(Mandatory=$True, Position=0)]
		[string]$node,
		
		[Parameter(Mandatory=$True, Position=1)]
		[string]$counter
	)
	
	Write-Host "Getting" $counter "from" $node
	$s = $null
	$timeout = 300
	while( -Not $s -And $timeout -gt 0 ) {
		Start-Sleep 5
		$timeout -= 5
		Try {
		$s = Get-Counter -ComputerName $node -Counter $counter
		} Catch {}
	}
	if( $timeout -lt 0 ) { Write-Warning "Timed out trying to fetch" $counter; Exit }
	
	return $s
}
	
function SetClusterOwnersUntilValid() {
	Param(
		[Parameter(Mandatory=$True, Position=0)]
		[System.Array]$owners
	)
	
	Write-Host "Setting the cluster owner list to" $owners
	Get-ClusterGroup "Available Storage" | Set-ClusterOwnerNode -Owners $owners
	
	# keep checking every 3 seconds until cluster reports that the owner list is set correctly
	$isValid = $False
	while( -Not $isValid ) {
		$o = Get-ClusterGroup "Available Storage" | Get-ClusterOwnerNode 

		$isValid = $True
		for($i = 0; $i -lt $owners.Length; $i++) {
			if( -Not $o.OwnerNodes[$i] -like $owners[$i] ) { $isValid = $False }	
		}
		
		Start-Sleep 3
	}	
}

	
# helper function for TestBug3998
function GetTargetProperty() {
	Param(
		[Parameter(Mandatory=$True, Position=0)]
		[string]$node,
		
		[Parameter(Mandatory=$True, Position=1)]
		[string]$targetIP,
		
		[Parameter(Mandatory=$True, Position=2)]
		[string]$mirrorVol,
		
		[Parameter(Mandatory=$True, Position=3)]
		[string]$property
	)
	
	$wmiVol = Invoke-Command -ComputerName $node -Credential $(getAdminCredentials) { Param($vol) Get-WmiObject win32_volume | where { $_.Name -like ($vol + ":\") } } -Args $mirrorVol
	$len = $wmiVol.DeviceID.Length
	$sGUID = $wmiVol.DeviceID.Substring(10, $len-11)
	$key = "hklm:\System\CurrentControlSet\Services\ExtMirr\Parameters\Volumes\"+$sGUID
	$volume = Invoke-Command -ComputerName $node -Credential $(getAdminCredentials) { Param($k) Get-ChildItem $k } -Args $key 
	$targetKey = $volume | foreach-object { Invoke-Command -ComputerName $node -Credential $(getAdminCredentials) { Param($child) Get-ChildItem $child } -Args ("hklm:\"+$_) }
	$targetObject = $targetKey | where-object { ($_ | GetRemoteNameProperty) -eq $targetIP }
	$properties = Invoke-Command -ComputerName $node -Credential $(getAdminCredentials) { Param($to) $to | Get-ItemProperty } -Args $targetObject
	
	return $properties.$property
}

function SetTargetProperty() {
	Param(
		[Parameter(Mandatory=$True, Position=0)]
		[string]$node,
		
		[Parameter(Mandatory=$True, Position=1)]
		[string]$targetIP,
		
		[Parameter(Mandatory=$True, Position=2)]
		[string]$mirrorVol,
		
		[Parameter(Mandatory=$True, Position=3)]
		[string]$property,
		
		[Parameter(Mandatory=$True, Position=4)]
		[int]$value
	)
	
	$wmiVol = Invoke-Command -ComputerName $node -Credential $(getAdminCredentials) { Param($vol) Get-WmiObject win32_volume | where { $_.Name -like ($vol + ":\") } } -Args $mirrorVol
	$len = $wmiVol.DeviceID.Length
	$sGUID = $wmiVol.DeviceID.Substring(10, $len-11)
	$key = "hklm:\System\CurrentControlSet\Services\ExtMirr\Parameters\Volumes\"+$sGUID
	$volume = Invoke-Command -ComputerName $node -Credential $(getAdminCredentials) { Param($k) Get-ChildItem $k } -Args $key 
	$targetKey = $volume | foreach-object { Invoke-Command -ComputerName $node -Credential $(getAdminCredentials) { Param($child) Get-ChildItem $child } -Args ("hklm:\"+$_) }
	$targetObject = $targetKey | where-object { ($_ | GetRemoteNameProperty) -eq $targetIP }
	Invoke-Command -ComputerName $node -Credential $(getAdminCredentials) { Param($to,$p,$v) $to | Set-ItemProperty -Name $p -Value $v } -Args $targetObject,$property,$value
	
	$properties = Invoke-Command -ComputerName $node -Credential $(getAdminCredentials) { Param($to) $to | Get-ItemProperty } -Args $targetObject
	
	if( $properties.$property -like $value ) { return $True }
	
	return $False
}