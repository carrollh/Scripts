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
    [Parameter(Mandatory=$False, Position=0)]
    [string[]] $ProductIDs = $Null,

    [Parameter(Mandatory=$False, Position=1)]
    [string[]] $AmiNames = $Null,
    
    [Parameter(Mandatory=$False, Position=2)]
    [string] $Description = $Null,

    [Parameter(Mandatory=$False, Position=3)]
    [string[]] $Regions = @("us-east-1","us-east-2","us-west-1","us-west-2","ca-central-1","ap-south-1","ap-northeast-2","ap-southeast-1","ap-southeast-2","eu-central-1","eu-west-1","eu-west-2","eu-west-3","sa-east-1"),
    
    [Parameter(Mandatory=$False, Position=4)]
    [Switch] $Linux
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

if( -Not $ProductIDs ) {
    if( $Linux ) {
        $ProductIDs = @("036d4d80-182d-460e-b9cc-01ebc2f842e4")
    } else {
        $ProductIDs = @("ea8c4f6b-0676-4494-90e9-d595a7444eaa","131676ee-31be-464b-8ae0-ba2495e88b22","374b4000-5f0b-4005-92e5-119d4836d1d6","9a7d70de-0121-4ecf-b190-10e31dd8ad5a")
    }
}

if( -Not $AmiNames ) {
    if( $Linux ) {
        $AmiNames = @("SIOS Protection Suite for Linux 9.2.2 on RHEL 7.4 BYOL")
    } else {
        $AmiNames = @("SIOS DataKeeper v8.6.1 on 2012R2","SIOS DataKeeper v8.6.1 on 2012R2 BYOL","SIOS DataKeeper v8.6.1 on 2016","SIOS DataKeeper v8.6.1 on 2016 BYOL")
    }
}

if( -Not $Description ) {
    if( $Linux ) {
        $Description = "SIOS Protection Suite makes Linux clusters easy to build, easy to use, and easy to own. You get out-of-the-box protection for SAP, Oracle, and other business-critical applications. Create a high availability SAN or SANless cluster quickly and easily."
    } else {
        $Description = "SIOS DataKeeper provides high Availability (HA) and disaster recovery (DR) in AWS. Simply add SIOS DataKeeper software as an ingredient to your Windows Server Failover Clustering (WSFC) environment to eliminate the need for shared storage."
    }
}

$final = [ordered]@{}
$i = 0
foreach ($region in $Regions) {
    $ht = [ordered]@{}
    Write-Progress -Activity "Querying $region" -PercentComplete ($i / $Regions.Count * 100)
    
    Write-Debug "Calling 'aws describe-images, this will take a second...`n"
    $jsonString = Invoke-Command -ScriptBlock { Param($d) &'aws' ec2 describe-images --region $region --owners 679593333241 --filter "Name=description,Values='$d'" } -ArgumentList $Description
    #$jsonString = Invoke-Command -ScriptBlock { Param($a) &'aws' ec2 describe-images --region $region --owners 801119661308 --filter $a } -ArgumentList $args
    $json = $jsonString -Join "" 
    Write-Debug "$json`n"
    
    $hashtable = ConvertFrom-Json $json | ConvertTo-OrderedHashtable
    Write-Verbose ($region)
    (0..($AmiNames.Length-1)) | foreach { 
        $amiId = ($hashtable."Images" | Where-Object -Property "Name" -Like ($AmiNames[$_] + "-" + $ProductIDs[$_] + "*")).ImageId
        Write-Verbose ("`t" + $AmiNames[$_] + ": `t`t`t" + $amiId)
        $ht.Add($AmiNames[$_], $amiID)
    }
    
    $final.Add($region,$ht)
    $i++
}

$final | Foreach-Object { $_ | Format-Table -AutoSize }
