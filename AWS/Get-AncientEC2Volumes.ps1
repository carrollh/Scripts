# Get-AncientEC2Volumes.ps1

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [string] $Profile = $Null,

    [Parameter(Mandatory=$True)]
    [string] $Region = $Null,

    [Parameter(Mandatory=$False)]
    [switch] $Delete,

    [Parameter(Mandatory=$False)]
    [switch] $Keep
)

$amis = Get-EC2Image -Region $Region -ProfileName $Profile -Owner self
$volumes = Get-EC2Volume -Region $Region -ProfileName $Profile

$toKeep = [System.Collections.ArrayList]@()
$toDelete = [System.Collections.ArrayList]@()
$pattern = "^.*(ami-.+) from (vol-.+)$"

$today = Get-Date
$volumes | % {
    if($_.CreateTime.AddMonths(6) -lt $today){
        $toKeep.Add($_) > $Null
    }
    else {
        $toDelete.Add($_) > $Null
    }
}
if($Delete) {
    return $toDelete
}
if($Keep) {
    return $toKeep
}

return $volumes
# END
