# Get-EC2ElasticIPs.ps1
#
# Example 1:
# .\Get-EC2ElasticIPs.ps1 -Region us-east-1 -Profile currentgen -ToDelete -Verbose
#
# Example 2:
# $profiles = @("automation","currentgen","dev","ps","qa","support","ts")
# $toDelete = [ordered]@{}
# foreach ($profile in $profiles) {
#     $del = .\Get-EC2ElasticIPs.ps1 -Profile $profile -ToDelete
#     $toDelete.Add($profile,$del)
# }

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [string] $Profile = $Null,

    [Parameter(Mandatory=$False)]
    [string[]] $Regions = $Null,

    [Parameter(Mandatory=$False)]
    [switch] $ToDelete,

    [Parameter(Mandatory=$False)]
    [switch] $ToKeep
)

if ($Regions -eq $Null) {
    $TargetRegions = (&"aws" ec2 describe-regions --profile $Profile --region us-east-1 --output json | ConvertFrom-Json).Regions.RegionName
} else {
    $TargetRegions = $Regions
}

Write-Verbose ("Scanning " + $TargetRegions.Count + " regions.")
$keep = [System.Collections.ArrayList]@()
$delete = [System.Collections.ArrayList]@()
$elasticIPs = [System.Collections.ArrayList]@()
foreach ($region in $TargetRegions) {
    $eips = Get-EC2Address -Region $region -ProfileName $Profile
    Write-Verbose $eips.Count

    $eips | % {
        if($_.AssociationId -eq $Null) {
            $delete.Add($_) > $Null
        }
        else {
            $keep.Add($_) > $Null
        }
        $elasticIPs.Add($_) > $Null
    }
}
if($ToDelete) {
    return $delete
}
if($ToKeep) {
    return $keep
}
return $elasticIPs
# END
