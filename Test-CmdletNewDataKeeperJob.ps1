# Test-CmdletNewDataKeeperJob 

#includes
. .\Utilities_DK.ps1
. .\TestDK.ps1

function verifyTest() {
	Param(
		[Parameter(Mandatory=$True, Position=0)]
		[string]$JobName,
			
		[Parameter(Mandatory=$True, Position=1)]
		[string]$JobDescription,
		
		[Parameter(Mandatory=$True, Position=2)]
		[string]$Node1Name,
		
		[Parameter(Mandatory=$True, Position=3)]
		[string]$Node1IP,
		
		[Parameter(Mandatory=$True, Position=4)]
		[string]$Node1Volume,
		
		[Parameter(Mandatory=$True, Position=5)]
		[string]$Node2Name,
		
		[Parameter(Mandatory=$True, Position=6)]
		[string]$Node2IP,
		
		[Parameter(Mandatory=$True, Position=8)]
		[string]$Node2Volume,
		
		[Parameter(Mandatory=$True, Position=9)]
		[string]$SyncType
	)
	
	# get all usable volumes from the service 
	$volumes = $(Get-DataKeeperServiceInfo).QualifyingVolumes
	$nodeList = New-Object System.Collections.Generic.List[System.String]
	$nodeList.Add("CAE-QA-V55")
	$nodeList.Add("CAE-QA-V56")
	$nodeList.Add("CAE-QA-V53")
	
	# check the service is up on all nodes
	$output = $True
	foreach( $node in $nodeList ) {
		$output = $(VerifyDKService $node $(GetAdminCredentials)) -and $output
	}
	if( $output -eq $False ) {
		Write-Host "Service not found on all nodes"
		return $False
	}
		
	# create a dictionary containing all jobs keyed on nodename
	$nodeJoblistDict = New-Object -TypeName "System.Collections.Generic.Dictionary[[string],[System.Collections.Generic.List[Steeleye.Model.ModelObject]]]" 
	foreach( $node in $nodeList ) {
		$nodeJoblistDict.Add($node,$(Get-DataKeeperJobList $node))
	}
	
	# verify the first node's job was created as per the params
	$job = $nodeJobListDict.$Node1Name
	if( -Not $job.Name -like $JobName ) { $failure = $True }
	if( -Not $job.Description -like $JobDescription ) { $failure = $True }
	$job.Volumes | foreach-object {
		if( -Not $_.Endpoints.leftServerName -like $Node1Name ) { $failure = $True ;Write-Warning "1"}
		if( -Not $_.Endpoints.leftServerAddress -like $Node1IP ) { $failure = $True ;Write-Warning "2"}
		if( -Not $_.Endpoints.leftVolumePath -like $Node1Volume ) { $failure = $True ;Write-Warning "3"}
		if( $_.Endpoints.leftRemoteAddress ) { $failure = $True ;Write-Warning "4"}
		if( $_.Endpoints.leftRemoteVolume ) { $failure = $True ;Write-Warning "5"}
		if( -Not $_.Endpoints.leftMirrorRole -like "None" ) { $failure = $True ;Write-Warning "6"}
		if( -Not $_.Endpoints.leftMirrorState -like "None" ) { $failure = $True ;Write-Warning "7"}
		if( $_.Endpoints.leftVolumeLabel ) { $failure = $True ;Write-Warning ""}
		if( -Not $_.Endpoints.leftVolumeIsUnderHAProtection -like "False" ) { $failure = $True ;Write-Warning "8"}
		if( $_.Endpoints.leftSnapShotLocation ) { $failure = $True ;Write-Warning "9"}

		if( -Not $_.Endpoints.rightServerName -like $Node2Name ) { $failure = $True ;Write-Warning "10"}
		if( -Not $_.Endpoints.rightServerAddress -like $Node2IP ) { $failure = $True ;Write-Warning "11"}
		if( -Not $_.Endpoints.rightVolumePath -like $Node2Volume ) { $failure = $True ;Write-Warning "12"}
		if( $_.Endpoints.rightRemoteAddress ) { $failure = $True ;Write-Warning "13"}
		if( $_.Endpoints.rightRemoteVolume ) { $failure = $True ;Write-Warning "14"}
		if( -Not $_.Endpoints.rightMirrorRole -like "None" ) { $failure = $True ;Write-Warning "15"}
		if( -Not $_.Endpoints.rightMirrorState -like "None" ) { $failure = $True ;Write-Warning "16"}
		if( $_.Endpoints.rightVolumeLabel ) { $failure = $True ;Write-Warning "17"}
		if( -Not $_.Endpoints.rightVolumeIsUnderHAProtection -like "False" ) { $failure = $True ;Write-Warning "18"}
		if( $_.Endpoints.rightSnapShotLocation ) { $failure = $True ;Write-Warning "19"}
		
		if( -Not $_.Endpoints.syncType -like $SyncType.Substring(0,1) ) { $failure = $True ;Write-Warning "20"}
	}	
	if( $failure -eq $True ) {
		Write-Verbose "Test FAILED due to job info on source not matching params!"
		return $False
	} 

	# verify the target node's job data matches the source's
	$failure = $False
	$job2 = $nodeJobListDict.$Node2Name
	if( "$job" -eq "$job2" ) {
		$job | foreach-object {
			if( $job.$_ -ne $job2.$_ ) { $failure = $True }
		}
	} 

	if( $failure -eq $True ) {
		Write-Verbose "Test FAILED due to job info for Node1 not matching info found on Node2!"
		return $False
	} 
	
	# verify any other nodes in the nodeList do not contain any jobs
	$failure = $False
	$nodeList | foreach-object {
		if( -Not $_ -like $Node1Name -And -Not $_ -like $Node2Name ) {
			if( $nodeJobListDict.$_.Count -ne 0 ) { $failure = $True }
		}
	}
	
	if( $failure -eq $True ) {
		Write-Verbose "Test FAILED due to job info on unrelated node!"
		return $False
	}
	
	return $True
}

function WriteDKJobStatus() {
	Param(
		[Parameter(Mandatory=$True, Position=1)]
		[string]$path,
		
		[Parameter(Mandatory=$True, Position=2, ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
		[System.Collections.Generic.List[Steeleye.Model.ModelObject]]$joblist
	)
	
	$json = $joblist | ConvertTo-Json
		$json | Out-File $path
}

function ReadDKJobStatus() {
	Param(
		[Parameter(Mandatory=$True, Position=1)]
		[string]$path
	)
	
	# verify config file exists
	if( Test-Path $path ) {
		# un-json-ify the input from file
		$data = (Get-Content $path) -join "`n" | ConvertFrom-Json
		return $data
	} 
	
	Write-Warning "No previous configuration data can be found."
	return $NUL
}	


function TestDKJobList() {
Param(
		[Parameter(Mandatory=$True, Position=0)]
		[string]$path
	)
	$current = Get-DataKeeperJobList . | WriteDKJobStatus .\temp.json | ReadDKJobStatus .\temp.json
	$previous = ReadDKJobStatus $path
	
	$output = $true
	
	if("$current" -eq "$previous") {
		$current | Get-Member | where-object { $_.MemberType -eq "NoteProperty" } | foreach {
			if($current.($_.Name) -ne $previous.($_.Name)) {
				Write-Host $current.($_.Name) $previous.($_.Name) "`n"
				$output = $False
			} 
		}		
	}
	
	return $output
}

function testNoJobsNoMirrorsExist() {
	Param(
		[Parameter(Mandatory=$True, Position=0)]
		[string]$JobName,
			
		[Parameter(Mandatory=$True, Position=1)]
		[string]$JobDescription,
		
		[Parameter(Mandatory=$True, Position=2)]
		[string]$Node1Name,
		
		[Parameter(Mandatory=$True, Position=3)]
		[string]$Node1IP,
		
		[Parameter(Mandatory=$True, Position=4)]
		[string]$Node1Volume,
		
		[Parameter(Mandatory=$True, Position=5)]
		[string]$Node2Name,
		
		[Parameter(Mandatory=$True, Position=6)]
		[string]$Node2IP,
		
		[Parameter(Mandatory=$True, Position=8)]
		[string]$Node2Volume,
		
		[Parameter(Mandatory=$True, Position=9)]
		[string]$SyncType
	)
	
	$failure = $False
	if( $(verifyPrerequisites) -eq $False ) {
		Write-Warning ($JobName + " prerequsites failed. Delete all DK jobs and mirrors, then re-try. Aborting.")
		$failure = $True
	} 
	try {
		New-DataKeeperJob $JobName $JobDescription $Node1Name $Node1IP $Node1Volume $Node2Name $Node2IP $Node2Volume $SyncType > $Null
	} catch {
		Write-Verbose "Exception caught"
		$failure = $True
	}
	if( $(verifyTest $JobName $JobDescription $Node1Name $Node1IP $Node1Volume $Node2Name $Node2IP $Node2Volume $SyncType) -eq $False ) {
		Write-Verbose ($JobName + " post-test verification failed!")
		$failure = $True
	}
		
	deleteAllJobs
	deleteAllMirrors
	
	return -Not $failure
}

function testJobExists() {
	Param(
		[Parameter(Mandatory=$True, Position=0)]
		[string]$JobName,
			
		[Parameter(Mandatory=$True, Position=1)]
		[string]$JobDescription,
		
		[Parameter(Mandatory=$True, Position=2)]
		[string]$Node1Name,
		
		[Parameter(Mandatory=$True, Position=3)]
		[string]$Node1IP,
		
		[Parameter(Mandatory=$True, Position=4)]
		[string]$Node1Volume,
		
		[Parameter(Mandatory=$True, Position=5)]
		[string]$Node2Name,
		
		[Parameter(Mandatory=$True, Position=6)]
		[string]$Node2IP,
		
		[Parameter(Mandatory=$True, Position=8)]
		[string]$Node2Volume,
		
		[Parameter(Mandatory=$True, Position=9)]
		[string]$SyncType
	)
	
	$failure = $False
	if( $(verifyPrerequisites) -eq $False ) {
		Write-Warning ($JobName + " prerequsites failed. Delete all DK jobs and mirrors, then re-try. Aborting.")
		$failure = $True
	} 
	
	try {
		New-DataKeeperJob $JobName $JobDescription $Node1Name $Node1IP $Node2Volume $Node2Name $Node2IP $Node2Volume $SyncType > $Null
		New-DataKeeperJob $JobName $JobDescription $Node1Name $Node1IP $Node1Volume $Node2Name $Node2IP $Node2Volume $SyncType > $Null
	} catch {
		Write-Verbose "Exception caught"
		$failure = $True
	}
	if( $(verifyTest $JobName $JobDescription $Node1Name $Node1IP $Node1Volume $Node2Name $Node2IP $Node2Volume $SyncType) -eq $False ) {
		Write-Verbose ($JobName + " post-test verification failed.!")
		$failure = $True
	}
		
	deleteAllJobs
	deleteAllMirrors
	
	return -Not $failure
}

function testMirrorExists() {
	Param(
		[Parameter(Mandatory=$True, Position=0)]
		[string]$JobName,
			
		[Parameter(Mandatory=$True, Position=1)]
		[string]$JobDescription,
		
		[Parameter(Mandatory=$True, Position=2)]
		[string]$Node1Name,
		
		[Parameter(Mandatory=$True, Position=3)]
		[string]$Node1IP,
		
		[Parameter(Mandatory=$True, Position=4)]
		[string]$Node1Volume,
		
		[Parameter(Mandatory=$True, Position=5)]
		[string]$Node2Name,
		
		[Parameter(Mandatory=$True, Position=6)]
		[string]$Node2IP,
		
		[Parameter(Mandatory=$True, Position=7)]
		[string]$Node2Volume,
		
		[Parameter(Mandatory=$True, Position=8)]
		[string]$SyncType,
		
		[Parameter(Mandatory=$True, Position=9)]
		[string]$Mirror1IP,
		
		[Parameter(Mandatory=$True, Position=10)]
		[string]$Mirror1Volume,
		
		[Parameter(Mandatory=$True, Position=11)]
		[string]$Mirror2IP,
		
		[Parameter(Mandatory=$True, Position=12)]
		[string]$Mirror2Volume,
		
		[Parameter(Mandatory=$True, Position=13)]
		[string]$MirrorSyncType
	)
	$failure = $False
	if( $(verifyPrerequisites) -eq $False ) {
		Write-Warning ($JobName + " prerequsites failed. Delete all DK jobs and mirrors, then re-try. Aborting.")
		$failure = $True
	} 
	try {
		New-DataKeeperMirror $Mirror1IP $Mirror1Volume $Mirror2IP $Mirror2Volume $MirrorSyncType 
		New-DataKeeperJob $JobName $JobDescription $Node1Name $Node1IP $Node1Volume $Node2Name $Node2IP $Node2Volume $SyncType > $Null
	} catch {
		Write-Verbose "Exception caught"
		$failure = $True
	}
	if( $(verifyTest $JobName $JobDescription $Node1Name $Node1IP $Node1Volume $Node2Name $Node2IP $Node2Volume $SyncType) -eq $False ) {
		Write-Verbose ($JobName + " post-test verification failed.!")
		$failure = $True
	}
		
	Write-Host "Verify the DataKeeper Snap-in is displaying as desired, then press any key to continue..."
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	
	deleteAllJobs
	deleteAllMirrors
	
	return -Not $failure
}

function Test-CmdletNewDataKeeperJob() {
	# assertTestResults $(testNoJobsNoMirrorsExist test1 desc1 cae-qa-v55 10.200.8.55 e cae-qa-v56 10.200.8.56 e Async) $True test1
	assertTestResults $(testNoJobsNoMirrorsExist test01 "check normal 1" cae-qa-v55 10.200.8.55 e cae-qa-v56 10.200.8.56 e async) $True "test1"
	assertTestResults $(testNoJobsNoMirrorsExist test02 "check normal 2" cae-qa-v56 10.200.8.56 e cae-qa-v55 10.200.8.55 e async) $True "test2"
	assertTestResults $(testNoJobsNoMirrorsExist test03 "check normal 3" cae-qa-v53 10.200.8.53 e cae-qa-v56 10.200.8.56 F async) $True "test3"
	assertTestResults $(testNoJobsNoMirrorsExist test04 "check normal 4" . 10.200.8.55 e cae-qa-v56 10.200.8.56 e async) $True "test4"
	assertTestResults $(testNoJobsNoMirrorsExist test05 "check normal 5" cae-qa-v55 10.200.8.55 e cae-qa-v56 10.200.8.56 e a) $False "test5"
	assertTestResults $(testNoJobsNoMirrorsExist test06 "check normal 6" cae-qa-v55 10.200.8.55 e cae-qa-v56 10.200.8.56 e sync) $True "test6"
	assertTestResults $(testNoJobsNoMirrorsExist test07 "check normal 7" cae-qa-v55 10.200.8.55 e cae-qa-v56 10.200.8.56 e s) $False "test7"
	assertTestResults $(testNoJobsNoMirrorsExist test08 "malformed 8" INVALID 10.200.8.55 e cae-qa-v56 10.200.8.56 e async) $False "test8"
	assertTestResults $(testNoJobsNoMirrorsExist test09 "malformed 9" cae-qa-v55 10.200.8.254 e cae-qa-v56 10.200.8.56 e async) $False "test9"
	assertTestResults $(testNoJobsNoMirrorsExist test10 "malformed 10" cae-qa-v55 10.200.8.53 e cae-qa-v56 10.200.8.56 e async) $False "test10"
	assertTestResults $(testNoJobsNoMirrorsExist test11 "malformed 11" cae-qa-v55 10.200.8.256 e cae-qa-v56 10.200.8.56 e async) $False "test11"
	assertTestResults $(testNoJobsNoMirrorsExist test12 "malformed 12" cae-qa-v55 10.200.8.55 X cae-qa-v56 10.200.8.56 e async) $True "test12"
	assertTestResults $(testNoJobsNoMirrorsExist test13 "malformed 13" cae-qa-v55 10.200.8.55 ELEPHANT cae-qa-v56 10.200.8.56 e async) $True "test13"
	assertTestResults $(testNoJobsNoMirrorsExist test14 "malformed 14" cae-qa-v55 10.200.8.55 ELEPHANT cae-qa-v56 10.200.8.56 e async) $True "test14"
	assertTestResults $(testNoJobsNoMirrorsExist test15 "malformed 15" cae-qa-v55 10.200.8.55 B cae-qa-v56 10.200.8.56 e async) $True "test15"
	assertTestResults $(testNoJobsNoMirrorsExist test16 "malformed 16" cae-qa-v55 10.200.8.55 ~ cae-qa-v56 10.200.8.56 e async) $False "test16"
	
	assertTestResults $(testJobExists test17 "malformed 17" cae-qa-v55 10.200.8.55 F cae-qa-v56 10.200.8.56 E async) $False "test17"
	
	Write-Host "test18 should go green in the gui: "
	assertTestResults $(testMirrorExists test18 "test 18" cae-qa-v55 10.200.8.55 e cae-qa-v56 10.200.8.56 e async 10.200.8.55 e 10.200.8.56 e async) $True "test18"
	
	Write-Host "test18 should stay red in the gui: "
	assertTestResults $(testMirrorExists test19 "test 19" cae-qa-v55 10.200.8.55 e cae-qa-v56 10.200.8.56 E async 10.200.8.55 e 10.200.8.56 F async) $True "test19"
}




