# Stress-SwitchoverLoop.ps1
# A recommended method of running this would be
# > Stress-SwitchoverLoop.ps1 | Tee-Object Stress-SwitchoverLoop.log

Param(
    [Parameter(Mandatory=$False)]
    [System.Array]$Nodes = @("cae-qa-v200","cae-qa-v201","cae-qa-v202"),

    [Parameter(Mandatory=$False)]
    [System.Array]$Vols = @("E")
)

# Continuously loop over the nodes switching ownership to the 
# next one in the node array. This should allow this to work for
# clusters of any size without needing an addtional script.
$result = @()
$nodeIndex = 0
while($true) {
    # verify the mirrors are all in the mirroring state on the current source
    foreach ($vol in $Vols) {
        $result = & "$env:ExtMirrBase\emcmd" $node GetMirrorVolInfo $vol
        if($result[0][3] -NotLike 1 -Or $result[0][$result[0].Length - 1] -NotLike 1) {
            Write-Host "Volume $vol not in the mirroring state!"
            return 1
        }
    }

    # switchover each volume to the next node in the array 
    $nodeIndex++
    $nodeIndex %= $Nodes.Length
    $node = $Nodes[$nodeIndex]
    foreach ($vol in $Vols) {
        $result = & "$env:ExtMirrBase\emcmd" $node SwitchoverVolume $vol
        if(-Not $?) {
            Write-Host "Switchover of volume $vol to $node failed with $result"
            return 1
        }
    }

    Start-Sleep 30
}