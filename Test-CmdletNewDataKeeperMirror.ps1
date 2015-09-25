
. .\Utilities_DK.ps1
. .\TestDK.ps1

function verifyTest() {
	Param(
		[Parameter(Mandatory=$True, Position=0)]
		[string]$SourceIP,
		
		[Parameter(Mandatory=$True, Position=1)]
		[string]$SourceVolume,
		
		[Parameter(Mandatory=$True, Position=2)]
		[string]$TargetIP,
		
		[Parameter(Mandatory=$True, Position=3)]
		[string]$TargetVolume,
		
		[Parameter(Mandatory=$True, Position=4)]
		[string]$SyncType
	)
	
	$nodeList = New-Object System.Collections.Generic.List[System.String]
	$nodeList.Add("CAE-QA-V55")
	$nodeList.Add("CAE-QA-V56")
	$nodeList.Add("CAE-QA-V53")
	
	# get all mirrors on all nodes
	$nodeMirrorListDict = New-Object -TypeName "System.Collections.Generic.Dictionary[[string],[System.Collections.Generic.Dictionary[[string],[DKPwrShell.Mirror]]]]]" 
	foreach( $node in $nodeList ) {
		$nodeMirrorListDict.Add($node,$(Get-DataKeeperConfiguration $node))
	}
	
	$failure = $False
	# make sure the mirror exists as defined on the source
	$sMirror = $nodeMirrorListDict.$(resolveIPtoComputerName $SourceIP).$SourceVolume
	if( -Not $sMirror.sVol -like $SourceVolume ) { $failure = $True; Write-Host "FAILED " 1 }
	if( -Not $sMirror.sRole -like "Source" ) 	 { $failure = $True; Write-Host "FAILED " 2 }
#	if( -Not $sMirror.sState -like "Mirroring" ) { $failure = $True; Write-Host "FAILED " 3 }
	if( -Not $sMirror.sType -like $SyncType ) 	 { $failure = $True; Write-Host "FAILED " 4 }
	
	$tMirror = $nodeMirrorListDict.$(resolveIPtoComputerName $TargetIP).$TargetVolume
	if( -Not $tMirror.sVol -like $TargetVolume ) { $failure = $True; Write-Host "FAILED " 5 }
	if( -Not $tMirror.sRole -like "Target" ) 	 { $failure = $True; Write-Host "FAILED " 6 }
#	if( -Not $tMirror.sState -like "Mirroring" ) { $failure = $True; Write-Host "FAILED " 7 }
	if( -Not $tMirror.sType -like $SyncType ) 	 { $failure = $True; Write-Host "FAILED " 8 }	
	
	# make sure the mirror exists as defined on the target
	
	# make sure no other mirrors exist on other nodes and volumes
}

function testNoJobsNoMirrorsExist() {
	Param(
		[Parameter(Mandatory=$True, Position=3)]
		[string]$SourceIP,
		
		[Parameter(Mandatory=$True, Position=4)]
		[string]$SourceVolume,
		
		[Parameter(Mandatory=$True, Position=6)]
		[string]$TargetIP,
		
		[Parameter(Mandatory=$True, Position=8)]
		[string]$TargetVolume,
		
		[Parameter(Mandatory=$True, Position=9)]
		[string]$SyncType
	)
	
	$failure = $False
	if( $(verifyPrerequisites) -eq $False ) {
		Write-Warning ($JobName + " prerequsites failed. Delete all DK jobs and mirrors, then re-try. Aborting.")
		$failure = $True
	} 
	try {
		New-DataKeeperMirror $SourceIP $SourceVolume $TargetIP $TargetVolume $SyncType
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

function testMirrorsExist() {
	Param(
		[Parameter(Mandatory=$True, Position=0)]
		[string]$SourceIP,
		
		[Parameter(Mandatory=$True, Position=1)]
		[string]$SourceVolume,
		
		[Parameter(Mandatory=$True, Position=2)]
		[string]$TargetIP,
		
		[Parameter(Mandatory=$True, Position=3)]
		[string]$TargetVolume,
		
		[Parameter(Mandatory=$True, Position=4)]
		[string]$SyncType,
		
		[Parameter(Mandatory=$True, Position=5)]
		[string]$Mirror1IP,
		
		[Parameter(Mandatory=$True, Position=6)]
		[string]$Mirror1Volume,
		
		[Parameter(Mandatory=$True, Position=7)]
		[string]$Mirror2IP,
		
		[Parameter(Mandatory=$True, Position=8)]
		[string]$Mirror2Volume,
		
		[Parameter(Mandatory=$True, Position=9)]
		[string]$MirrorSyncType
	)
	
	$failure = $False
	if( $(verifyPrerequisites) -eq $False ) {
		Write-Warning ($JobName + " prerequsites failed. Delete all DK jobs and mirrors, then re-try. Aborting.")
		$failure = $True
	} 
	try {
		New-DataKeeperMirror $Mirror1IP $Mirror1Volume $Mirror2IP $Mirror2Volume $MirrorSyncType
		New-DataKeeperMirror $SourceIP $SourceVolume $TargetIP $TargetVolume $SyncType
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

function testJobsExist() {
	Param(
		[Parameter(Mandatory=$True, Position=0)]
		[string]$SourceIP,
		
		[Parameter(Mandatory=$True, Position=1)]
		[string]$SourceVolume,
		
		[Parameter(Mandatory=$True, Position=2)]
		[string]$TargetIP,
		
		[Parameter(Mandatory=$True, Position=3)]
		[string]$TargetVolume,
		
		[Parameter(Mandatory=$True, Position=4)]
		[string]$SyncType,
		
		[Parameter(Mandatory=$True, Position=5)]
		[string]$JobName,
			
		[Parameter(Mandatory=$True, Position=6)]
		[string]$JobDescription,
		
		[Parameter(Mandatory=$True, Position=7)]
		[string]$Node1Name,
		
		[Parameter(Mandatory=$True, Position=8)]
		[string]$Node1IP,
		
		[Parameter(Mandatory=$True, Position=9)]
		[string]$Node1Volume,
		
		[Parameter(Mandatory=$True, Position=10)]
		[string]$Node2Name,
		
		[Parameter(Mandatory=$True, Position=11)]
		[string]$Node2IP,
		
		[Parameter(Mandatory=$True, Position=12)]
		[string]$Node2Volume,
		
		[Parameter(Mandatory=$True, Position=13)]
		[string]$JobSyncType
	)
	
	$failure = $False
	if( $(verifyPrerequisites) -eq $False ) {
		Write-Warning ($JobName + " prerequsites failed. Delete all DK jobs and mirrors, then re-try. Aborting.")
		$failure = $True
	} 
	try {
		New-DataKeeperJob $JobName $JobDescription $Node1Name $Node1IP $Node1Volume $Node2Name $Node2IP $Node2Volume $JobSyncType
		New-DataKeeperMirror $SourceIP $SourceVolume $TargetIP $TargetVolume $SyncType
		if( $(verifyTest $SourceIP $SourceVolume $TargetIP $TargetVolume $SyncType) -eq $False ) {
			Write-Verbose ("Post-test verification failed!")
			$failure = $True
		}
	} catch {
		Write-Verbose "Exception caught"
		$failure = $True
	}
		
	Write-Host "Verify the DataKeeper Snap-in is displaying as desired, then press any key to continue..."
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	
	deleteAllJobs
	deleteAllMirrors
	
	return -Not $failure 
}

# effectively the main
function Test-CmdletNewDataKeeperMirror() {
	assertTestResults $(testNoJobsNoMirrorsExist 10.200.8.55 e 10.200.8.56 e async) $True Test01
	assertTestResults $(testNoJobsNoMirrorsExist 10.200.8.56 e 10.200.8.55 e async) $True Test02
	assertTestResults $(testNoJobsNoMirrorsExist 10.200.8.53 e 10.200.8.56 e async) $True Test03
	assertTestResults $(testNoJobsNoMirrorsExist cae-qa-v55 e 10.200.8.56 e async) $False Test04
	assertTestResults $(testNoJobsNoMirrorsExist 10.200.8.55 e cae-qa-v56 e async) $False Test05
	assertTestResults $(testNoJobsNoMirrorsExist 10.200.8.55 e " " e async) $False Test06
	assertTestResults $(testNoJobsNoMirrorsExist 10.200.8.55 e 10.200.8.56 " " async) $False Test07
	
	assertTestResults $(testNoJobsNoMirrorsExist 10.200.8.254 e 10.200.8.56 e async) $False Test08
	assertTestResults $(testNoJobsNoMirrorsExist 10.200.8.256 e 10.200.8.56 e async) $False Test09
	assertTestResults $(testNoJobsNoMirrorsExist 10.200.8.55 x 10.200.8.56 e async) $False Test10
	assertTestResults $(testNoJobsNoMirrorsExist 10.200.8.55 ELEPHANT 10.200.8.56 e async) $True Test11
	assertTestResults $(testNoJobsNoMirrorsExist 10.200.8.55 A 10.200.8.56 e async) $False Test12
	assertTestResults $(testNoJobsNoMirrorsExist 10.200.8.55 % 10.200.8.56 e async) $False Test13
	assertTestResults $(testNoJobsNoMirrorsExist 10.200.8.55 e 10.200.8.256 e async) $False Test14

	assertTestResults $(testNoJobsNoMirrorsExist 10.200.8.55 e 10.200.8.56 e a) $False Test15
	assertTestResults $(testNoJobsNoMirrorsExist 10.200.8.55 e 10.200.8.56 e sync) $True Test16
	assertTestResults $(testNoJobsNoMirrorsExist 10.200.8.55 g 10.200.8.53 g disk) $False Test17
	assertTestResults $(testNoJobsNoMirrorsExist 10.200.8.55 e 10.200.8.56 e d) $False Test18
	
	assertTestResults $(testMirrorsExist 10.200.8.55 e 10.200.8.56 e async 10.200.8.55 f 10.200.8.56 f async) $True Test19
	assertTestResults $(testMirrorsExist 10.200.8.55 e 10.200.8.56 e async 10.200.8.55 f 10.200.8.56 f sync) $True Test20
	assertTestResults $(testMirrorsExist 10.200.8.55 e 10.200.8.56 e async 10.200.8.55 e 10.200.8.56 e async) $False Test21
	assertTestResults $(testMirrorsExist 10.200.8.55 e 10.200.8.56 e async 10.200.8.55 e 10.200.8.56 e sync) $False Test22
	assertTestResults $(testMirrorsExist 10.200.8.53 e 10.200.8.56 f async 10.200.8.55 e 10.200.8.56 e async) $True Test23
	assertTestResults $(testMirrorsExist 10.200.8.55 e 10.200.8.56 e async 10.200.8.55 f 10.200.8.56 e async) $False Test24
	assertTestResults $(testMirrorsExist 10.200.8.55 e 10.200.8.56 e async 10.200.8.55 e 10.200.8.53 e async) $True Test25
	assertTestResults $(testMirrorsExist 10.200.8.55 e 10.200.8.56 e async 10.200.8.55 e 10.200.8.56 f async) $False Test26
	assertTestResults $(testMirrorsExist 10.200.8.55 e 10.200.8.56 e async 10.200.8.55 e 10.200.8.53 f async) $True Test26a
	
	Write-Host "test27 should go green in the gui: "
	assertTestResults $(testJobsExist 10.200.8.55 e 10.200.8.56 e async test27 "check normal 27" CAE-QA-V55 10.200.8.55 e CAE-QA-V56 10.200.8.56 e async) $True Test27
	
	Write-Host "test28 should go green in the gui: "
	assertTestResults $(testJobsExist 10.200.8.55 e 10.200.8.56 e sync test28 "check normal 28" CAE-QA-V55 10.200.8.55 e CAE-QA-V56 10.200.8.56 e sync) $True Test28

	Write-Host "test29 should go green in the gui: "
	assertTestResults $(testJobsExist 10.200.8.56 e 10.200.8.53 e async test29 "check normal 29" CAE-QA-V56 10.200.8.56 e CAE-QA-V53 10.200.8.53 e async) $True Test29
	
	#Write-Host "test30 should stay green in the gui (for now): "
	assertTestResults $(testJobsExist 10.200.8.55 e 10.200.8.56 e async test30 "check normal fail to pickup 30" CAE-QA-V55 10.200.8.55 e CAE-QA-V56 10.200.8.56 e sync) $True Test30
	
	Write-Host "test31 should stay red in the gui: "	
	assertTestResults $(testJobsExist 10.200.8.55 e 10.200.8.56 e async test31 "check normal fail to pickup 31" CAE-QA-V55 10.200.8.55 e CAE-QA-V56 10.200.8.56 f async) $True Test31

	Write-Host "test32 should stay red in the gui: "	
	assertTestResults $(testJobsExist 10.200.8.55 e 10.200.8.53 e async test32 "check normal fail to pickup 32" CAE-QA-V55 10.200.8.55 e CAE-QA-V56 10.200.8.56 e async) $True Test32
}


