# Get-AWSImageIds.ps1 ############################################################
# Requires the AWS CLI to be installed and in the PATH env variable. Also 
# requires the user running this to have access to the relevant subscription 
# prior to running this. The ProductID is really the only param needed for this,
# but filtering by the Windows and DKCE versions in the name helps narrow it 
# down to only one result per region.
#
# Examples running this command:
# PS> $ht = [System.Collections.Hashtable]@{}
# PS> $ht = .\Get-AWSImageIds -Profile dev 
################################################################################

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False, Position=0)]
    [string] $Profile = $Null,

    [Parameter(Mandatory=$False, Position=1)]
    [string[]] $Regions = $Null
)

If ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

function ConvertTo-OrderedHashtable {
    param (
        [Parameter(ValueFromPipeline)]
        [PSCustomObject]$InputObject
    )

    process {
        if ($null -eq $InputObject) { return $null }

        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @(
                foreach ($object in $InputObject) { $object | ConvertTo-OrderedHashtable }
            )
            Write-Output -NoEnumerate $collection
        }
        elseif ($InputObject -is [psobject]) {
            $properties = $InputObject.PSObject.Properties | Out-String
            if ($properties.Contains("Length")) {
                return $InputObject
            }
            $hash = [ordered]@{}

            foreach ($property in $InputObject.PSObject.Properties) {
                $hash[$property.Name] = $property.Value | ConvertTo-OrderedHashtable
            }

            return $hash
        }
        else {
            return $InputObject
        }
    }
}

################################################################################
$osFilters = [ordered]@{
    SLES12SP1 = "suse-sles-12-sp1-*-hvm-ssd-x86_64";
    SLES12SP2 = "suse-sles-12-sp2-*-hvm-ssd-x86_64";
    SLES12SP3 = "suse-sles-12-sp3-v????????-hvm-ssd-x86_64";
    SLES12SP4 = "suse-sles-12-sp4-v????????-hvm-ssd-x86_64";
    SLES12SP5 = "suse-sles-12-sp5-v????????-hvm-ssd-x86_64";
    SLES15    = "suse-sles-15-v????????-hvm-ssd-x86_64";
    SLES15SP1 = "suse-sles-15-sp1-v????????-hvm-ssd-x86_64";
    RHEL74 = "RHEL-7.4*HVM_GA*x86_64*";
    RHEL75 = "RHEL-7.5*HVM_GA*x86_64*";
    RHEL76 = "RHEL-7.6*HVM_GA*x86_64*";
    RHEL77 = "RHEL-7.7*HVM_GA*x86_64*";
    RHEL78 = "RHEL-7.8*HVM_GA*x86_64*";
    RHEL80 = "RHEL-8.0*HVM*x86_64*";
    RHEL81 = "RHEL-8.1*HVM*x86_64*";
    RHEL82 = "RHEL-8.2*HVM*x86_64*";
}

if( -Not $Regions -Or $Regions -like "all") {
    $Regions = @("ap-northeast-1","ap-northeast-2","ap-south-1","ap-southeast-1","ap-southeast-2","ca-central-1","eu-central-1","eu-north-1","eu-west-1","eu-west-2","eu-west-3","sa-east-1","us-east-1","us-east-2","us-west-1","us-west-2")
}

$amiRegionMapping = [ordered]@{}
$rdgwMapping = [ordered]@{}
foreach ($region in $Regions) {
    Write-Verbose $region

    $rdgwAmi = (& "aws" ec2 describe-images --owners 705913476943 --query 'sort_by(Images, &CreationDate)[*].[CreationDate,Name,ImageId]' --filters "Name=name,Values=*SPSL-Jumpbox-Internal*" --region $region --output json | ConvertFrom-Json).split("`n")[2]
    $rdgwMapping.Add($region, $rdgwAmi) > $Null

    $amiOSVersionMapping = [ordered]@{}
    foreach ($key in $osFilters.GetEnumerator().Name) {
        Write-Verbose $key
        $filter = $osFilters[$key]

        if($filter -like "RHEL*") {
            $images = & "aws" ec2 describe-images --owners 309956199498 --query 'reverse(sort_by(Images, &CreationDate))[*].[CreationDate,Name,ImageId]' --filters "Name=name,Values=$filter" --region $region --output json | ConvertFrom-Json
        }
        else {
            $images = & "aws" ec2 describe-images --owners amazon --query 'reverse(sort_by(Images, &CreationDate))[*].[CreationDate,Name,ImageId]' --filters "Name=name,Values=$filter" --region $region --output json | ConvertFrom-Json
        }
        $amiid = $Null
        $amiid = [string]($images[0] | % { if($_ -like "ami-*") { $_ } })
        
        Write-Verbose $amiid
        $amiOSVersionMapping.Add($key,$amiid) > $Null
    }
    $amiRegionMapping.Add($region, $amiOSVersionMapping)
}

foreach ($region in $amiRegionMapping.GetEnumerator().Name) {
    [string]("    " + $region + ":")
    [string]("      WIN2019JUMPBOX: " + $rdgwMapping[$region])
    foreach($osLabel in $amiRegionMapping[$region].GetEnumerator().Name) {
        [string]("      " + $osLabel + ": " + $amiRegionMapping[$region][$osLabel])
    }
}

# return $amiRegionMapping