# Get-EC2VolumeSummary.ps1
#
# Example:
# $rs = @("ap-east-1","ap-northeast-1","ap-northeast-2","ap-south-1","ap-southeast-1","ap-southeast-2","ca-central-1","eu-central-1","eu-north-1","eu-west-1","eu-west-2","eu-west-3","me-south-1","sa-east-1","us-east-1","us-east-2","us-west-1","us-west-2")
# $outfile = "C:\Users\hcarroll\Desktop\AWS_Summary"
# foreach($p in $ps){ 
#     $volinfo = .\Get-EC2VolumeSummary.ps1 -Profile $p
#     foreach($r in $rs){
#         "`n$r" >> "$outfile\${p}_volumes"
#         echo $volinfo["$r"] >> "$outfile\${p}_volumes"
#     }
# }

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [string] $Profile = $Null,

    [Parameter(Mandatory=$False)]
    [string[]] $Regions = @("ap-east-1","ap-northeast-1","ap-northeast-2","ap-south-1","ap-southeast-1","ap-southeast-2","ca-central-1","eu-central-1","eu-north-1","eu-west-1","eu-west-2","eu-west-3","me-south-1","sa-east-1","us-east-1","us-east-2","us-west-1","us-west-2")
)

$volTable = [Ordered]@{}
foreach ($region in $Regions) {
    $volumes = (& "aws" ec2 describe-volumes --region $region --profile $Profile --output json | convertfrom-json).Volumes
    $tags = (& "aws" ec2 describe-tags --region $region --profile $Profile --filters "Name=resource-type,Values=instance" "Name=key,Values=Name" --output json | convertfrom-json).Tags
    $volinfo = [System.Collections.ArrayList]@()
    $volumes | %{
        $nametag = ($tags | Where-Object -Property ResourceId -like ($_.Attachments.InstanceId)).Value
        if($nametag -like ''){
            $nametag = "N/A"
        }
        $obj = [PSCustomObject]@{
            VolumeId        = $_.VolumeId
            VolumeSize      = $_.Size
            InstanceNameTag = $nametag
            InstanceId      = $_.Attachments.InstanceId
            CreateTime      = $_.CreateTime
        }
        $volinfo.Add($obj) > $Null
    }

    $volTable.Add($region, ($volinfo | Sort-Object -Property CreateTime)) > $Null
}

return $volTable
# END
