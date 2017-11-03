# Get-AWSAMIIds.ps1 ############################################################
# Requires the AWS CLI to be installed and in the PATH env variable. Also 
# requires the user running this to have access to the relevant subscription 
# prior to running this. The ProductID is really the only param needed for this,
# but filtering by the Windows and DKCE versions in the name helps narrow it 
# down to only one result per region.
#
# Examples running this command:
# PS> Get-AWSAMIIds 12345678-1234-abcd-0123456789ab 8.6 2016
# PS> Get-AWSAMIIds -ProductID 12345678-1234-abcd-0123456789ab -DkVer 8.6 -WinVer 2016 
################################################################################

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True, Position=0)]
    [string] $ProductID = "12345678-1234-abcd-0123456789ab",

    [Parameter(Mandatory=$False, Position=1)]
    [string] $DkVer = "8.5.3",
    
    [Parameter(Mandatory=$False, Position=2)]
    [string] $WinVer = "2012 R2",
    
    [Parameter(Mandatory=$False, Position=3)]
    [string] $Description = "SIOS DataKeeper provides high Availability (HA) and disaster recovery (DR) in AWS. Simply add SIOS DataKeeper software as an ingredient to your Windows Server Failover Clustering (WSFC) environment to eliminate the need for shared storage.",

    [Parameter(Mandatory=$False, Position=4)]
    [string[]] $Regions = @("us-east-1", "us-east-2", "us-west-1", "us-west-2", "ca-central-1", "ap-south-1", "ap-northeast-2", "ap-southeast-1", "ap-southeast-2", "eu-central-1", "eu-west-1", "eu-west-2", "sa-east-1")
)

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
$ht = [ordered]@{}
$i = 0
foreach ($region in $Regions) {
    #$region = $regions[0]
    Write-Progress -Activity "Querying $region" -PercentComplete ($i / $Regions.Count * 100)
    $args = '"Name=description,Values="' + $Description
    $jsonString = Invoke-Command -ScriptBlock { Param($a) &'aws' ec2 describe-images --region $region --owners 679593333241 --filter $a } -ArgumentList $args
    $json = $jsonString -Join "" 
    
    if($Verbose) { $json }
    
    $hashtable = ConvertFrom-Json $json | ConvertTo-OrderedHashtable
    $amiId = ($hashtable."Images" | Where-Object -Property "ImageLocation" -Like "*aws-marketplace*" | Where-Object -Property "Name" -Like ("*" + $DkVer + "*" + $WinVer + "*" + $ProductID + "*")).ImageId
    $ht.Add($region, $amiID)
    $i++
}

$ht | Format-Table -AutoSize
