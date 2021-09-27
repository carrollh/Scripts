# Get-AWSAMIIds.ps1 ############################################################
# Requires the AWS CLI to be installed and in the PATH env variable. Also 
# requires the user running this to have access to the relevant subscription 
# prior to running this.
#
# return type is [System.Collections.ArrayList]
#
# Examples running this command:
# PS> $allowedTypes = .\Get-EC2AllowedInstanceTypes.ps1 -Profile dev -RHELVersion 7.9 -Verbose
################################################################################

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True, Position=0)]
    [string] $Profile = '',

    [Parameter(Mandatory=$True, Position=1)]
    [ValidateSet('7.8','7.9','8.2','8.3')]
    [string] $RHELVersion = '7.9',

    [Parameter(Mandatory=$False, Position=2)]
    [string[]] $Regions = $Null
)

################################################################################
if( -Not $Regions -Or $Regions -like "all") {
    $Regions = @("ap-northeast-2","ap-south-1","ap-southeast-1","ap-southeast-2","ca-central-1","eu-central-1","eu-north-1","eu-west-1","eu-west-2","eu-west-3","sa-east-1","us-east-1","us-east-2","us-west-1","us-west-2")
}

$searchString = [ordered]@{
    '7.9' = 'RHEL-7.9_HVM_GA*x86*';
    '8.2' = 'RHEL-8.2_HVM*x86*';
}

$list = [System.Collections.ArrayList]@()

foreach ($region in $regions) {
    Write-Verbose "Looking up ami-id for $($region)..."
    $amiId = ((aws ec2 describe-images --region $region --profile $Profile --filters Name=name,Values=$($searchString[$RHELVersion]) --output json | ConvertFrom-Json).Images | Sort -Property CreationDate -Descending)[0].ImageId
    Write-Verbose "`tFound ami-id $amiId"

    Write-Verbose "Retrieving all possible types for region..."
    $types = (aws ec2 describe-instance-types --region $region --profile $Profile --output json | ConvertFrom-Json).InstanceTypes.InstanceType
    Write-Verbose "`tFound $($types.Count) possible types"

    Write-Verbose "Attempting to create instances using ami-id: $($amiId)`n`tThis is going to take a while..."
    foreach ($type in $types) {
        if ( -Not ($list.Contains($type)) ){
            $output = (aws ec2 run-instances --region $region --profile $Profile --image-id $amiId --instance-type $type --count 1 --dry-run) 2>&1
            if ($output[1].ToString().Contains("DryRunOperation")) {
                $list.Add($type) > $Null
            }
        }
    }
}

return $list