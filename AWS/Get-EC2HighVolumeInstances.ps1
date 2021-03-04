# Get-EC2HighVolumeInstances.ps1
#
# Description:
#   This script relies on two others to generate a hashtable of instance data, sorted
#   by total volume size.
#
# Example 1:
# Get-EC2HighVolumeInstances.ps1 -Profile dev -Region ca-central-1
#
# Example 2 (get 2 regions worth of data from 2 profiles):
# $profiles = @("dev","currentgen")
# $regions = @("ca-central-1","us-east-1")
# $output = @{}
# foreach($profile in $profiles){
#    $profileOutput = @{}
#    foreach($region in $regions){
#       $regionOutput = .\Get-EC2HighVolumeInstances.ps1 -Profile $profile -Region $region
#       $profileOutput.Add($region, $regionOutput)
#    }
#    $output.Add($profile, $profileOutput)
# }
# 
# Example 3 (get all sorted summaries in all regions for all accounts):
# $profiles = @("dev","qa","support","ts","ps","currentgen","automation")
# $output = @{}
# foreach($profile in $profiles){
#     $profileOutput = .\Get-EC2HighVolumeInstances.ps1 -Profile $profile
#     $output.Add($profile, $profileOutput)
# }

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [string] $Profile = $Null,

    [Parameter(Mandatory=$False)]
    [string[]] $Regions = @("ap-east-1","ap-northeast-1","ap-northeast-2","ap-south-1","ap-southeast-1","ap-southeast-2","ca-central-1","eu-central-1","eu-north-1","eu-west-1","eu-west-2","eu-west-3","me-south-1","sa-east-1","us-east-1","us-east-2","us-west-1","us-west-2")
)

Write-Verbose "Get-EC2HighVolumeInstances - START"
Write-Verbose "`tParameters ($($PsBoundParameters.Values.Count)):"
$PsBoundParameters.Keys | foreach {
    Write-Verbose "`t$_ = $($PsBoundParameters[$_])"
}
$outputTable = [Ordered]@{}
foreach ($region in $Regions) {
    Write-Verbose "`t$region"
    $volumeSummary = (.\Get-EC2VolumeSummary.ps1 -Profile $Profile -Region $region) | Sort -Property "VolumeSize" -Descending
    $instanceSummary = .\Get-EC2InstanceSummary.ps1 -Profile $Profile -Region $region

    $instances = $Null
    if($Profile) {
        Write-Verbose "---`taws ec2 describe-instances --region $region --profile $Profile --output json"
        $instances = (& "aws" ec2 describe-instances --region $region --profile $Profile | ConvertFrom-Json).Reservations.Instances
    }
    else {
        Write-Verbose "---`taws ec2 describe-instances --region $region --output json"
        $instances = (& "aws" ec2 describe-instances --region $region | ConvertFrom-Json).Reservations.Instances
    }

    for ($i = 0; $i -lt $instanceSummary[$region].Count; $i+=1) {
        $size = 0
        $volumeIds = ($instances | Where-Object -Property InstanceId -like $instanceSummary[$region][$i].InstanceId).BlockDeviceMappings.Ebs.VolumeId
        foreach ($id in $volumeIds) {
            $size += ($volumeSummary[$region] | Where-Object -Property VolumeId -Like $id).VolumeSize
        }
        $instanceSummary[$region][$i] | Add-Member -MemberType NoteProperty -Name "TotalVolumeSize" -Value $size
    }

    $outputTable.Add($region, ($instanceSummary[$region] | Sort -Property "TotalVolumeSize" -Descending)) > $Null
}

Write-Verbose "Get-EC2HighVolumeInstances - END"

# spit out the desired instances sorted by most amount of storage first (per region)
# unfortunately we may have volumes that are unaccounted for
return $outputTable
