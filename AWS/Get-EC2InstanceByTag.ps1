# Get-EC2InstanceByTag.ps1
# 
# Example calls:
#   .\New-AWSDeployment.ps1 -OSVersion RHEL76
#
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [string] $Tag = '',

    [Parameter(Mandatory=$False)]
    [string] $Profile = '',

    [Parameter(Mandatory=$False)]
    [string[]] $Regions = $Null
)

if ($Regions -eq $Null) {
    $targetRegions = (&"aws" ec2 describe-regions --profile $Profile --region us-east-1 --output json | ConvertFrom-Json).Regions.RegionName
} else {
    $targetRegions = $Regions
}

$ht = [ordered]@{}
Write-Verbose ("Scanning " + $targetRegions.Count + " regions.")
foreach ($region in $targetRegions) {
    Write-Verbose "$region"
    $nametags = (aws ec2 describe-instances --region $region --profile $Profile --output json --filters "Name=tag-key,Values=Name" --query "Reservations[*].Instances[*].{Name:Tags[?Key=='Name']|[0].Value}" | ConvertFrom-Json).Name
    Write-Verbose "$nametags"
    $ht.Add("$region","$nametags")
}

$output = [System.Collections.ArrayList]@()
foreach ($region in $targetRegions) {
    Write-Verbose "$region"
    return $ht["$region"]
    foreach($tag in $ht["$region"]){
        Write-Verbose "HEATH $tag"
        if ($tag -like "*$($Tag)*" ) {
            Write-Verbose "    $($ht[$region])"
            $output.Add("$region $($ht[$region])")
        }
    }
}
return $output