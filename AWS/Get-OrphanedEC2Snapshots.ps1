# Get-OrphanedEC2Snapshots.ps1

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [string] $Profile = $Null,

    [Parameter(Mandatory=$True)]
    [string] $Region = $Null,
    
    [Parameter(Mandatory=$False)]
    [switch] $Delete
)

$amis = Get-EC2Image -Region $Region -ProfileName $Profile -Owner self
$volumes = Get-EC2Volume -Region $Region -ProfileName $Profile
$snapshots = Get-EC2Snapshot -Region $Region -ProfileName $Profile -Owner self

$toKeep = [System.Collections.ArrayList]@()
$toDelete = [System.Collections.ArrayList]@()
$pattern = "^.*(ami-.+) from (vol-.+)$"
foreach ($snapshot in $snapshots) {
    if($snapshot.Description.StartsWith("Created by CreateImage")) {
        $snapshot | Where-Object Description -Match $pattern > $Null
        $amiId = $Matches[1]
        $volId = $Matches[2]

        if($amis.ImageId.Contains($amiId) -Or $volumes.VolumeId.Contains($volId)) {
            $toKeep.Add($snapshot) > $Null
        } else {
            $toDelete.Add($snapshot) > $Null
        }
    } else {
        $toKeep.Add($snapshot) > $Null
    }
}

if($Delete) {
    return $toDelete
}
return $toKeep
# END