# Get-AWSAMIIds.ps1 ############################################################
# Requires the AWS CLI to be installed and in the PATH env variable. Also 
# requires the user running this to have access to the relevant subscription 
# prior to running this. The ProductID is really the only param needed for this,
# but filtering by the Windows and DKCE versions in the name helps narrow it 
# down to only one result per region.
#
# Examples running this command:
# PS> Get-AWSAMIIds dev 9.4.0 -Linux
# PS> Get-AWSAMIIds -Profile dev -Version 8.7.0 
################################################################################

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True, Position=0)]
    [string] $Profile = $Null,

    [Parameter(Mandatory=$False, Position=1)]
    [string[]] $Version = $Null,

    [Parameter(Mandatory=$True, Position=2)]
    [string[]] $OSVersions = $Null,

    [Parameter(Mandatory=$False, Position=3)]
    [string[]] $Regions = $Null,
    
    [Parameter(Mandatory=$False)]
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
if( -Not $Version ) {
    Write-Host "Software version needed!`nUsage: Get-AWSAMIIds -Version <ver> ...`n"
    return;
}

if( $OSVersions -like "all" ) {
    if( -Not $Linux ) {
        $OSVersions = @("2012R2","2012R2 BYOL","2016","2016 BYOL","2019","2019 BYOL")
    }
}

if( -Not $Regions -Or $Regions -like "all") {
    $Regions = @("ap-northeast-1","ap-northeast-2","ap-south-1","ap-southeast-1","ap-southeast-2","ca-central-1","eu-central-1","eu-north-1","eu-west-1","eu-west-2","eu-west-3","sa-east-1","us-east-1","us-east-2","us-west-1","us-west-2")
}

$amiRegionMapping = [System.Collections.Hashtable]@{}
foreach ($region in $Regions) {
    Write-Verbose $region
    $amis = Get-EC2Image -Owner 679593333241 -ProfileName $Profile -Region $region

    $amiOSVersionMapping = [System.Collections.Hashtable]@{}
    foreach ($osVersion in $OSVersions) {
        if ($Linux) {
            $namePattern = "^SIOS Protection Suite for Linux v$Version on $osVersion-.*"
        } else {
            $namePattern = "^SIOS DataKeeper v$Version on $osVersion-.*"
        }

        $ami = $amis | Where-Object Name -Match $namePattern
        $amiOSVersionMapping.Add($osVersion.Replace(" ",""),$ami.ImageId)
    }

    $amiRegionMapping.Add($region, $amiOSVersionMapping)
}

return $amiRegionMapping

<#
if( -Not $ProductIDs ) {
    if( $Linux ) {
        $ProductIDs = @("273a5693-de58-4437-87fa-d3b56f714e95","036d4d80-182d-460e-b9cc-01ebc2f842e4")
    } else {
        $ProductIDs = @("ea8c4f6b-0676-4494-90e9-d595a7444eaa","131676ee-31be-464b-8ae0-ba2495e88b22","374b4000-5f0b-4005-92e5-119d4836d1d6","9a7d70de-0121-4ecf-b190-10e31dd8ad5a")
    }
}

$AMIRegionMapping = [System.Collections.Hashtable]@{}
if( $Linux ) {
    $AmiNames = @("SIOS Protection Suite for Linux $Version on RHEL 7.6","SIOS Protection Suite for Linux $Version on RHEL 7.6 BYOL")
    $AMIRegionMapping.Add($AmiNames[0],"SPSLRHEL")
    $AMIRegionMapping.Add($AmiNames[1],"SPSLRHELBYOL")
} else {
    $AmiNames = @("SIOS DataKeeper v$Version on 2012R2","SIOS DataKeeper v$Version on 2012R2 BYOL","SIOS DataKeeper v$Version on 2016","SIOS DataKeeper v$Version on 2016 BYOL")
    $AMIRegionMapping.Add($AmiNames[0],"SIOS2012R2") > $Null
    $AMIRegionMapping.Add($AmiNames[1],"SIOS2012R2BYOL") > $Null
    $AMIRegionMapping.Add($AmiNames[2],"SIOS2016") > $Null
    $AMIRegionMapping.Add($AmiNames[3],"SIOS2016BYOL") > $Null
}

if( $Linux ) {
    $Description = "SIOS Protection Suite makes Linux clusters easy to build, easy to use, and easy to own. You get out-of-the-box protection for SAP, Oracle, and other business-critical applications. Create a high availability SAN or SANless cluster quickly and easily."
} else {
    $Description = "SIOS DataKeeper provides high Availability (HA) and disaster recovery (DR) in AWS. Simply add SIOS DataKeeper software as an ingredient to your Windows Server Failover Clustering (WSFC) environment to eliminate the need for shared storage."
}

$final = [ordered]@{}
$i = 0
foreach ($region in $Regions) {
    $ht = [ordered]@{}
    Write-Progress -Activity "Querying $region" -PercentComplete ($i / $Regions.Count * 100)
    
    Write-Debug "Calling 'aws describe-images, this will take a second...`n"
    $jsonString = Invoke-Command -ScriptBlock { Param($d) &'aws' ec2 describe-images --profile currentgen --region $region --owners 679593333241 --filter "Name=description,Values='$d'" } -ArgumentList $Description
    #$jsonString = Invoke-Command -ScriptBlock { Param($a) &'aws' ec2 describe-images --region $region --owners 801119661308 --filter $a } -ArgumentList $args
    $json = $jsonString -Join "" 
    Write-Debug "$json`n"
    
    $hashtable = ConvertFrom-Json $json | ConvertTo-OrderedHashtable
    Write-Verbose ($region)
    (0..($AmiNames.Length-1)) | foreach { 
        $amiId = ($hashtable."Images" | Where-Object -Property "Name" -Like ($AmiNames[$_] + "-" + $ProductIDs[$_] + "*")).ImageId
        Write-Verbose ("`t" + $AmiNames[$_] + ": `t`t`t" + $amiId)
        $ht.Add($AMIRegionMapping.($AmiNames[$_]), $amiID)
    }
    
    $final.Add($region,$ht)
    $i++
}

$final | ConvertTo-Json
#>
