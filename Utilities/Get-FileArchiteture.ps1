
function Get-FileArchitecture {
	param(
		[Parameter(ValueFromPipeline=$true)]
		$fileobject
	)
	begin { 
		$shell = New-Object -COMObject Shell.Application 

	}
	process {
		if ($_.PSIsContainer -eq $false) {
		    $folder = Split-Path $fileobject.FullName
		    $file = Split-Path $fileobject.FullName -Leaf
		    $machine = & "dumpbin $file | findstr machine"
		}
		
	}
}
