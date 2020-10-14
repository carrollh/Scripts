# Get-OrphanedEC2Snapshots.ps1
#
# Example 1:
# .\Get-OrphanedEC2Snapshots.ps1 -Region us-east-1
#
# Example 2:
# $rs = @("ap-east-1","ap-northeast-1","ap-northeast-2","ap-south-1","ap-southeast-1","ap-southeast-2","ca-central-1","eu-central-1","eu-north-1","eu-west-1","eu-west-2","eu-west-3","me-south-1","sa-east-1","us-east-1","us-east-2","us-west-1","us-west-2")
# $outfile = "C:\Users\hcarroll\Desktop\AWS_Summary"
# foreach($p in $ps){ 
#     $info = .\Get-OrphanedEC2Snapshots.ps1 -Profile $p
#     foreach($r in $rs){
#         "`n$r" >> "$outfile\${p}_instances"
#         echo $info["$r"] | ft >> "$outfile\${p}_instances"
#     }
# }

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False)]
    [string] $Profile = '',

    [Parameter(Mandatory=$False)]
    [string[]] $Regions = @("ap-east-1","ap-northeast-1","ap-northeast-2","ap-south-1","ap-southeast-1","ap-southeast-2","ca-central-1","eu-central-1","eu-north-1","eu-west-1","eu-west-2","eu-west-3","me-south-1","sa-east-1","us-east-1","us-east-2","us-west-1","us-west-2"),

    [Parameter(Mandatory=$False)]
    [switch] $Delete
)

$self = (&"aws" sts get-caller-identity --profile $Profile --region us-east-1 --output json | ConvertFrom-Json).Account

$snapshotTable = [Ordered]@{}
foreach ($region in $Regions) {
    if($Profile -eq '') {
        $amis = (&"aws" ec2 describe-images --region $Region --filters "Name=owner-id,Values=$self" --output json | ConvertFrom-Json).Images
        $volumes = (& "aws" ec2 describe-volumes --region $Region --output json | ConvertFrom-Json).Volumes
        $snapshots = (&"aws" ec2 describe-snapshots --region $Region --filters "Name=owner-id,Values=$self" --output json | ConvertFrom-Json).Snapshots
    }
    else {
        $amis = (&"aws" ec2 describe-images --profile $Profile --region $Region --filters "Name=owner-id,Values=$self" --output json | ConvertFrom-Json).Images
        $volumes = (& "aws" ec2 describe-volumes --profile $Profile --region $Region --output json | ConvertFrom-Json).Volumes
        $snapshots = (&"aws" ec2 describe-snapshots --profile $Profile --region $Region --filters "Name=owner-id,Values=$self" --output json | ConvertFrom-Json).Snapshots
    }
    $toKeep = [System.Collections.ArrayList]@()
    $toDelete = [System.Collections.ArrayList]@()
    $pattern = "^.*(ami-.+) from (vol-.+)$"
    foreach ($snapshot in $snapshots) {
        if($snapshot.Description.StartsWith("Created by CreateImage")) {
            $obj = [PSCustomObject]@{
                SnapshotId = $snapshot.SnapshotId
                VolumeId   = $snapshot.VolumeId
                VolumeSize = $snapshot.VolumeSize
                StartTime  = $snapshot.StartTime
            }

            $snapshot | Where-Object Description -Match $pattern > $Null
            $amiId = $Matches[1]
            $volId = $Matches[2]

            if(($amiId -ne $Null -And $amis.ImageId.Contains($amiId)) -Or ($volId -ne $Null -And $volumes.VolumeId.Contains($volId))) {
                $toKeep.Add($obj) > $Null
            } else {
                $toDelete.Add($obj) > $Null
            }
        } else {
            $toKeep.Add($snapshot) > $Null
        }
    }
    if($Delete) {
        $snapshotTable.Add($region, ($toDelete | Sort-Object -Property VolumeId)) > $Null
    }
    else {
        $snapshotTable.Add($region, ($toKeep | Sort-Object -Property VolumeId)) > $Null
    }
}

return $snapshotTable
# END