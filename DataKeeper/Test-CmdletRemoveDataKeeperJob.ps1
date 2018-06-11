
. .\Utilities_DK.ps1
. .\TestDK.ps1

function verifyTest() {
	Param(
		[Parameter(Mandatory=$True, Position=0)]
		[string]$SourceIP
	)
	
	$failure = $False
	
	$nodeList = New-Object System.Collections.Generic.List[System.String]
	$nodeList.Add("CAE-QA-V55")
	$nodeList.Add("CAE-QA-V56")
	$nodeList.Add("CAE-QA-V53")
	
	# make sure no mirrors exist
	$nodeList | foreach-object {
		$mirrorList = @{}
		findDKMirrorsOnNode $mirrorList $_
		if( $mirrorList.$_.Count -ne 0 ) {
			$failure = $True
		}
	}
	
	# make sure no jobs exist
	$nodeList | foreach-object { 
		$joblist = Get-DataKeeperJobList $_
		if( $jobList.Count -ne 0 ) { 
			$failure = $True 
		} 
	}
	
	return -Not $failure	
}

function testNoJobsNoMirrorsExist() {
	Param(
		[Parameter(Mandatory=$True, Position=0)]
		[string]$Node,
		
		[Parameter(Mandatory=$True, Position=1)]
		[string]$JobName,
			
		[Parameter(Mandatory=$True, Position=2)]
		[string]$JobDescription,
		
		[Parameter(Mandatory=$True, Position=3)]
		[string]$Node1Name,
		
		[Parameter(Mandatory=$True, Position=4)]
		[string]$Node1IP,
		
		[Parameter(Mandatory=$True, Position=5)]
		[string]$Node1Volume,
		
		[Parameter(Mandatory=$True, Position=6)]
		[string]$Node2Name,
		
		[Parameter(Mandatory=$True, Position=7)]
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
		$job = New-DataKeeperJob $JobName $JobDescription $Node1Name $Node1IP $Node1Volume $Node2Name $Node2IP $Node2Volume $SyncType > $Null
		Remove-DataKeeperJob $node $job.JobId

		if( $(verifyTest $SourceIP $SourceVolume $TargetIP $TargetVolume $SyncType) -eq $False ) {
			Write-Verbose ("Post-test verification failed!")
			$failure = $True
		}
	} catch {
		Write-Verbose "Exception caught"
		$failure = $True
	}
		
	deleteAllJobs
	deleteAllMirrors
	
	return -Not $failure 
}

# effectively the main
function Test-CmdletRemoveDataKeeperJob() {
	assertTestResults $(testNoJobsNoMirrorsExist cae-qa-v55.qagroup.com test01 "check normal 1" cae-qa-v55.qagroup.com 10.200.8.55 e cae-qa-v56.qagroup.com 10.200.8.56 e async) $True Test01

}


