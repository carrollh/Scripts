
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
				$version = $shellfolder.GetDetailsOf($shellfile, $_)
				if($version) {
					if ($version -as [Double]) { $version = [Double]$version }
					$obj = New-Object PSObject
					$obj | Add-Member NoteProperty Assembly($file)
					$obj | Add-Member NoteProperty Version($version)
					Write-Output $obj
				}
			}
		}
	}
}

$path = "C:\Program Files (x86)\SIOS\DataKeeper"
$dkList = dir $path -Recurse | Get-FileVersion
$dkList

$path = "C:\LK"
$lkPath = dir $path -Recurse | Get-FileVersion
$lkPath