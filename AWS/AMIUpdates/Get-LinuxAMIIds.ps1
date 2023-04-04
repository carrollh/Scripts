# Get-RHELAMIIds.ps1 ############################################################
# Requires the AWS CLI to be installed and in the PATH env variable. Also 
# requires the user running this to have access to the relevant subscription 
# prior to running this. The ProductID is really the only param needed for this,
# but filtering by the Windows and DKCE versions in the name helps narrow it 
# down to only one result per region.
#
# Examples running this command:
# PS> .\Get-RHELAMIIds -Profile dev
################################################################################

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True, Position=0)]
    [string] $Profile = '',

    [Parameter(Mandatory=$False, Position=1)]
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
$output = @"
  AWSAMIRegionMap:
    AMI:

"@
$skipAMINames = $False

foreach ($region in $Regions) {
    $ws2019jumpbox = $Null
    $sles12sp5ami = $Null
    $sles15sp1ami = $Null
    $sles15sp2ami = $Null
    $sles15sp3ami = $Null
    $sles15sp4ami = $Null
    $rhel79ami = $Null
    $rhel81ami = $Null
    $rhel82ami = $Null
    $rhel84ami = $Null
    $rhel85ami = $Null
    $rhel86ami = $Null
    $rhel87ami = $Null
    $images = $Null

    Write-Verbose $region
    $amiOSVersionMapping = [Ordered]@{}

    Write-Verbose "*** aws ec2 describe-images --owners 705913476943 --region $region --profile $Profile --output json"
    $images = (aws ec2 describe-images --owners 705913476943 --region $region --profile dev --output json | ConvertFrom-json).Images
    $ws2019jumpbox = ($images | Where -Property Name -like "SPSL-Jumpbox-Internal" | Sort -Property CreationDate -Descending)[0]

    if($ws2019jumpbox -eq $Null) {
        Write-Error "No image found for WIN2019JUMPBOX in $region"
    }

    $amiOSVersionMapping.Add("WIN2019JUMPBOX",$ws2019jumpbox.ImageId) > $Null

    $images = $Null
    Write-Verbose "*** aws ec2 describe-images --owners 013907871322 --region $region --profile $Profile --output json"
    $images = (aws ec2 describe-images --owners 013907871322 --region $region --profile dev --output json | ConvertFrom-json).Images
    $sles12sp5ami = ($images | Where -Property Name -like "*suse*sles*12*sp5*hvm*x86_64*" | Where -Property Name -notlike "*beta*" | Where -Property Name -notlike "*SAP*" | Sort -Property CreationDate -Descending)[0]
    $sles15sp1ami = ($images | Where -Property Name -like "*suse*sles*15*sp1*hvm*x86_64*" | Where -Property Name -notlike "*beta*" | Where -Property Name -notlike "*SAP*" | Sort -Property CreationDate -Descending)[0]
    $sles15sp2ami = ($images | Where -Property Name -like "*suse*sles*15*sp2*hvm*x86_64*" | Where -Property Name -notlike "*beta*" | Where -Property Name -notlike "*SAP*" | Sort -Property CreationDate -Descending)[0]
    $sles15sp3ami = ($images | Where -Property Name -like "*suse*sles*15*sp3*hvm*x86_64*" | Where -Property Name -notlike "*beta*" | Where -Property Name -notlike "*SAP*" | Sort -Property CreationDate -Descending)[0]
    $sles15sp4ami = ($images | Where -Property Name -like "*suse*sles*15*sp4*hvm*x86_64*" | Where -Property Name -notlike "*beta*" | Where -Property Name -notlike "*SAP*" | Sort -Property CreationDate -Descending)[0]

    if($sles12sp5ami -eq $Null) {
        Write-Error "No image found for SLES12SP5 in $region"
    }
    if($sles15sp1ami -eq $Null) {
        Write-Error "No image found for SLES15SP1 in $region"
    }
    if($sles15sp2ami -eq $Null) {
        Write-Error "No image found for SLES15SP2 in $region"
    }
    if($sles15sp3ami -eq $Null) {
        Write-Error "No image found for SLES15SP3 in $region"
    }
    if($sles15sp4ami -eq $Null) {
        Write-Error "No image found for SLES15SP4 in $region"
    }

    $amiOSVersionMapping.Add("SLES12SP5",$sles12sp5ami.ImageId) > $Null
    $amiOSVersionMapping.Add("SLES15SP1",$sles15sp1ami.ImageId) > $Null
    $amiOSVersionMapping.Add("SLES15SP2",$sles15sp2ami.ImageId) > $Null
    $amiOSVersionMapping.Add("SLES15SP3",$sles15sp3ami.ImageId) > $Null
    $amiOSVersionMapping.Add("SLES15SP4",$sles15sp4ami.ImageId) > $Null

    $images = $Null
    Write-Verbose "*** aws ec2 describe-images --owners 309956199498 --region $region --profile $Profile --output json"
    $images = (aws ec2 describe-images --owners 309956199498 --region $region --profile $Profile --output json | ConvertFrom-json).Images
    Write-Verbose "Found $($images.Count) images"
    $rhel79ami = ($images | Where -Property Name -like "*RHEL*7.9*HVM*x86_64*" | Where -Property Name -notlike "*beta*" | Where -Property Name -notlike "*SAP*" | Sort -Property CreationDate -Descending)[0]
    $rhel81ami = ($images | Where -Property Name -like "*RHEL*8.1*HVM*x86_64*" | Where -Property Name -notlike "*beta*" | Where -Property Name -notlike "*SAP*" | Sort -Property CreationDate -Descending)[0]
    $rhel82ami = ($images | Where -Property Name -like "*RHEL*8.2*HVM*x86_64*" | Where -Property Name -notlike "*beta*" | Where -Property Name -notlike "*SAP*" | Sort -Property CreationDate -Descending)[0]
    $rhel84ami = ($images | Where -Property Name -like "*RHEL*8.4*HVM*x86_64*" | Where -Property Name -notlike "*beta*" | Where -Property Name -notlike "*SAP*" | Sort -Property CreationDate -Descending)[0]
    $rhel85ami = ($images | Where -Property Name -like "*RHEL*8.5*HVM*x86_64*" | Where -Property Name -notlike "*beta*" | Where -Property Name -notlike "*SAP*" | Sort -Property CreationDate -Descending)[0]
    $rhel86ami = ($images | Where -Property Name -like "*RHEL*8.6*HVM*x86_64*" | Where -Property Name -notlike "*beta*" | Where -Property Name -notlike "*SAP*" | Sort -Property CreationDate -Descending)[0]
    $rhel87ami = ($images | Where -Property Name -like "*RHEL*8.7*HVM*x86_64*" | Where -Property Name -notlike "*beta*" | Where -Property Name -notlike "*SAP*" | Sort -Property CreationDate -Descending)[0]

    if($rhel79ami -eq $Null) {
        Write-Error "No image found for RHEL79 in $region"
    }
    if($rhel81ami -eq $Null) {
        Write-Error "No image found for RHEL81 in $region"
    }
    if($rhel82ami -eq $Null) {
        Write-Error "No image found for RHEL82 in $region"
    }
    if($rhel84ami -eq $Null) {
        Write-Error "No image found for RHEL84 in $region"
    }
    if($rhel85ami -eq $Null) {
        Write-Error "No image found for RHEL85 in $region"
    }
    if($rhel86ami -eq $Null) {
        Write-Error "No image found for RHEL86 in $region"
    }
    if($rhel87ami -eq $Null) {
        Write-Error "No image found for RHEL87 in $region"
    }

    $amiOSVersionMapping.Add("RHEL79",$rhel79ami.ImageId) > $Null
    $amiOSVersionMapping.Add("RHEL81",$rhel81ami.ImageId) > $Null
    $amiOSVersionMapping.Add("RHEL82",$rhel82ami.ImageId) > $Null
    $amiOSVersionMapping.Add("RHEL84",$rhel84ami.ImageId) > $Null
    $amiOSVersionMapping.Add("RHEL85",$rhel85ami.ImageId) > $Null
    $amiOSVersionMapping.Add("RHEL86",$rhel86ami.ImageId) > $Null
    $amiOSVersionMapping.Add("RHEL87",$rhel87ami.ImageId) > $Null

    $amiRegionMapping.Add($region, $amiOSVersionMapping)

    if(-Not $skipAMINames) {
        $output += @"
      WIN2019JUMPBOX: $($ws2019jumpbox.Name)
      SLES12SP5: $($sles12sp5ami.Name)
      SLES15SP1: $($sles15sp1ami.Name)
      SLES15SP2: $($sles15sp2ami.Name)
      SLES15SP3: $($sles15sp3ami.Name)
      SLES15SP4: $($sles15sp4ami.Name)
      RHEL79:    $($rhel79ami.Name)
      RHEL81:    $($rhel81ami.Name)
      RHEL82:    $($rhel82ami.Name)
      RHEL84:    $($rhel84ami.Name)
      RHEL85:    $($rhel85ami.Name)
      RHEL86:    $($rhel86ami.Name)
      RHEL87:    $($rhel87ami.Name)

"@
        $skipAMINames = $True
    }
    
}

foreach ( $region in $Regions ) {
    $output += "    $($region):`n"
    $map = $amiRegionMapping[$region]
    foreach ( $label in $map.Keys ) {
        $output += "      $($label): $($map[$($label)])`n"
    }
}

return $output
