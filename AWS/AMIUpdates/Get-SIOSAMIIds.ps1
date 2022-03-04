# Get-AWSAMIIds.ps1 ############################################################
# Requires the AWS CLI to be installed and in the PATH env variable. Also 
# requires the user running this to have access to the relevant subscription 
# prior to running this. The ProductID is really the only param needed for this,
# but filtering by the Windows and DKCE versions in the name helps narrow it 
# down to only one result per region.
#
# Examples running this command:
# PS> .\Get-AWSAMIIds -Profile dev -Template SPSL
################################################################################

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True, Position=0)]
    [string] $Profile = '',

    [Parameter(Mandatory=$True, Position=1)]
    [ValidateSet('DKCE','SPSL')]
    [string] $Template = '',

    [Parameter(Mandatory=$False, Position=2)]
    [string[]] $Regions = $Null
)

If ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

################################################################################
if( -Not $Regions -Or $Regions -like "all") {
    $Regions = @("ap-northeast-2","ap-south-1","ap-southeast-1","ap-southeast-2","ca-central-1","eu-central-1","eu-north-1","eu-west-1","eu-west-2","eu-west-3","sa-east-1","us-east-1","us-east-2","us-west-1","us-west-2")
}

$amiRegionMapping = [Ordered]@{}
$output = "  AWSAMIRegionMap:`n"
foreach ($region in $Regions) {
    Write-Verbose $region
    $amiOSVersionMapping = [Ordered]@{}
    if ( $Template -eq 'DKCE' ) {
        $ws2012r2paygAMI = ((aws ec2 describe-images --owners aws-marketplace --region $region --profile $Profile --output json --filters "Name=product-code,Values=dvw0k1cslwup93kxyf85trjxm" | ConvertFrom-json).Images | Sort -Property CreationDate -Descending)[0]
        $ws2012r2byolAMI = ((aws ec2 describe-images --owners aws-marketplace --region $region --profile $Profile --output json --filters "Name=product-code,Values=14oj75sfcidvzwqizi8lzs7c2" | ConvertFrom-json).Images | Sort -Property CreationDate -Descending)[0]
        $ws2016paygAMI = ((aws ec2 describe-images --owners aws-marketplace --region $region --profile $Profile --output json --filters "Name=product-code,Values=39ui2evyq6bmfxwhpwyci6l06" | ConvertFrom-json).Images | Sort -Property CreationDate -Descending)[0]
        $ws2016byolAMI = ((aws ec2 describe-images --owners aws-marketplace --region $region --profile $Profile --output json --filters "Name=product-code,Values=959g9sxo7jo9axg7au8fjxvmi" | ConvertFrom-json).Images | Sort -Property CreationDate -Descending)[0]
        $ws2019paygAMI = ((aws ec2 describe-images --owners aws-marketplace --region $region --profile $Profile --output json --filters "Name=product-code,Values=4751lqgr72zqz6fwj12p82x8s" | ConvertFrom-json).Images | Sort -Property CreationDate -Descending)[0]
        $ws2019byolAMI = ((aws ec2 describe-images --owners aws-marketplace --region $region --profile $Profile --output json --filters "Name=product-code,Values=4em0o0s00hf8yye81sq8d619d" | ConvertFrom-json).Images | Sort -Property CreationDate -Descending)[0]

        $amiOSVersionMapping.Add("SDKCEWIN2012R2",$ws2012r2paygAMI.ImageId) > $Null
        $amiOSVersionMapping.Add("SDKCEWIN2012R2BYOL",$ws2012r2byolAMI.ImageId) > $Null
        $amiOSVersionMapping.Add("SDKCEWIN2016",$ws2016paygAMI.ImageId) > $Null
        $amiOSVersionMapping.Add("SDKCEWIN2016BYOL",$ws2016byolAMI.ImageId) > $Null
        $amiOSVersionMapping.Add("SDKCEWIN2019",$ws2019paygAMI.ImageId) > $Null
        $amiOSVersionMapping.Add("SDKCEWIN2019BYOL",$ws2019byolAMI.ImageId) > $Null
    }
    elseif ( $Template -eq 'SPSL' ) {
        $byolAMI = ((aws ec2 describe-images --owners aws-marketplace --region $region --profile $Profile --output json --filters "Name=product-code,Values=7axs50cedfvb18mqwotd482s" | ConvertFrom-json).Images | Sort -Property CreationDate -Descending)[0]
        $paygAMI = ((aws ec2 describe-images --owners aws-marketplace --region $region --profile $Profile --output json --filters "Name=product-code,Values=2blt83b3g52sgw0zaufvu4exh" | ConvertFrom-json).Images | Sort -Property CreationDate -Descending)[0]

        $amiOSVersionMapping.Add("SPSLRHEL",$paygAMI.ImageId) > $Null
        $amiOSVersionMapping.Add("SPSLRHELBYOL",$byolAMI.ImageId) > $Null
    }

    $amiRegionMapping.Add($region, $amiOSVersionMapping)
}

foreach ( $region in $Regions ) {
    $output += "    $($region):`n"
    $map = $amiRegionMapping[$region]
    foreach ( $label in $map.Keys ) {
    $output += "      $($label): $($map[$($label)])`n"
    }
}

return $output
