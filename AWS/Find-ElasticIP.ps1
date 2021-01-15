# Find-ElasticIP.ps1

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False)]
    [string[]]$Profiles = @("dev","support","qa","ps","ts","currentgen"),

    [Parameter(Mandatory=$False)]
    [string[]] $Regions = $Null,

    [Parameter(Mandatory=$False)]
    [string] $PublicIP = ""
)

# BEGIN

# loop over regions looking for instances
$finalTable = @{}
foreach ( $p in $Profiles ) {
    Write-Verbose ("Scanning the " + $p.ToUpper() + " profile")

    if ($Regions -eq $Null) {
        $TargetRegions = $(aws ec2 describe-regions --profile $p --output json | ConvertFrom-Json).Regions.RegionName
    } else {
        $TargetRegions = $Regions
    }

    foreach ( $region in $TargetRegions ) {
        $query = (aws ec2 describe-addresses --public-ips $PublicIP --profile $p --region $region --output json | ConvertFrom-Json)
        if($LastExitCode -ne 255) {
            Write-Host "EIP found in profile $P and region $region"
        }
    }
}

return $False
# END



