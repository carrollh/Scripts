$loop=1
while($true) {

    $systems = "CAE-QA-V55", "CAE-QA-V56", "CAE-QA-V53"

    foreach($s in $systems) {
        move-clustergroup "Available Storage" -Node $s

        Start-Sleep 60
		$needToExit = $False
        $resources = "DataKeeper Volume E", "DataKeeper Volume F", "DataKeeper Volume G", "DataKeeper Volume H"
        foreach($r in $resources) {
            $p = get-clusterresource $r | get-clusterparameter

            foreach($v in $p) {
                if($v.Name -Like "TargetState*") {
                    Write-Host $r $v.Name $v.Value

                    if($v.Value -ne 1) {
						Start-Sleep 210
						if($v.Value -ne 1) {
							get-date
							$needToExit = $True
						}
                    }
                }
            }
			
			if( $needToExit -eq $True ) {
				exit
			}
        }
        Write-Host "Loop " $loop
        $loop=$loop+1
	}
}
