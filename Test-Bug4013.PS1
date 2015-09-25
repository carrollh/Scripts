
function Test-Bug4013() {
	Param(		
		[Parameter(Mandatory=$True,Position=0)]
		[string]$Node,
			
		[Parameter(Mandatory=$True,Position=1)]
		[string]$Volume,
		
		[Parameter(Mandatory=$False,Position=2)]
		[int]$LoopCount = 100
	)
	
	$i = 1
	while( $i -le $LoopCount ) {
		Write-Host $i ": " 
		emcmd $Node lockvolume $Volume
		emcmd $Node unlockvolume $Volume
		emcmd $Node pausemirror $Volume
		emcmd $Node continuemirror $Volume
		dir ($Volume+":") > $NUL
		emcmd $Node getmirrorvolinfo $Volume
		
		$i++
	}
}