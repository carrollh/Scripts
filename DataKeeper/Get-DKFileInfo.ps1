
function Get-FileVersion {
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
		    $shellfolder = $shell.Namespace($folder)
		    $shellfile = $shellfolder.ParseName($file)
		    285 | ForEach-Object {
				$fullpath = $shellfolder.GetDetailsOf($shellfile, 0)
				$copyright = $shellfolder.GetDetailsOf($shellfile, 25)
				$fVersion = $shellfolder.GetDetailsOf($shellfile, 158)
				$pVersion = $shellfolder.GetDetailsOf($shellfile, $_) 
				if ($pVersion -as [Double]) { $pVersion = [Double]$pVersion }
				$obj = New-Object PSObject
				$obj | Add-Member NoteProperty File($fullpath)
				$obj | Add-Member NoteProperty Copyright($copyright)
				$obj | Add-Member NoteProperty FileVersion($fVersion)
				$obj | Add-Member NoteProperty ProductVersion($pVersion)
				Write-Output $obj
			}
		}
	}
}

$extmirrbase = "C:\Program Files (x86)\SIOS\DataKeeper"
$list = dir $extmirrbase -Recurse | Get-FileVersion
$list