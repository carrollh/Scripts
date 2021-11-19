# New-SiosAzureBaseVM.ps1
# PS> .\New-SiosAzureBaseVM.ps1 -Product DKCE -Version 8.8.1 -OSVersion WS2019 -Profile currentgen -Verbose

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True, Position=0)]
    [ValidateSet("SPSL","DKCE")]
    [String] $Product = '',

    [Parameter(Mandatory=$True, Position=1)]
    [String] $Version = '',

    [Parameter(Mandatory=$True, Position=2)]
    [ValidateSet("WS2012R2","WS2016","WS2019","RHEL79")]
    [String] $OSVersion = '',

    [Parameter(Mandatory=$True, Position=3)]
    [ValidateSet("BYOL","PAYG")]
    [String] $LicenseType = '',

    [Parameter(Mandatory=$False)]
    [String] $Profile = '',

    [Parameter(Mandatory=$False)]
    [ValidateSet('master','test','develop')]
    [String] $Branch = 'master',

    [Parameter(Mandatory=$False)]
    [Switch] $SAP = $False
)

function Get-ParametersFromURL() {
    Param(
        [Parameter(Mandatory=$False,Position=0)]
        [string] $URL
    )
    return Invoke-WebRequest -Uri $URL | ConvertFrom-Json
}

function Get-ParametersFromFile() {
    Param(
        [Parameter(Mandatory=$False,Position=0)]
        [string] $Path
    )
    return Get-Content $Path | Out-String | ConvertFrom-Json
}

if ( $OutDir -eq $Null -Or $OutDir -eq "" ) {
    $OutDir = $PSScriptRoot
}

### Parameter validation - START
$parametersAreValid = $True

if ( $SAP ) {
    if ( $LicenseType -eq 'BYOL' ) {
        Write-Error "`nSAP AMIs only support PAYG license model."
        $parametersAreValid = $false
    }

    if ( $OSVersion -eq 'WS2012R2' ) {
        Write-Error "`nSAP AMIs are only supported on WS2016+."
        $parametersAreValid = $false
    }
}
if(-Not $parametersAreValid) {
    return 1
}
### Parameter validation - END

### MAIN ##############################################################################
$templateURLBase = "https://s3.amazonaws.com/quickstart-sios-qa/$Branch"

if ( $SAP ) {
    $tag = "$($Product)v$($Version.Replace('.',''))forSAPon$($OSVersion.Replace('WS',''))-$($LicenseType)"
}
else {
    $tag = "$($Product)v$($Version.Replace('.',''))on$($OSVersion.Replace('WS',''))-$($LicenseType)"
}
Write-Verbose "Starting $tag AMI creation process..."

$latestAMI = ''
Write-Verbose "Looking up latest AMI for $OSVersion..."
if ( $OSVersion.StartsWith('WS') ) {
    Switch ( $OSVersion ) {
        WS2012R2 { $latestAMI ="/aws/service/ami-windows-latest/Windows_Server-2012-R2_RTM-English-64Bit-Base" }
        WS2016   { $latestAMI = "/aws/service/ami-windows-latest/Windows_Server-2016-English-Full-Base" }
        WS2019   { $latestAMI = "/aws/service/ami-windows-latest/Windows_Server-2019-English-Full-Base" }
    }
}
elseif ( $OSversion.StartsWith('RHEL') ) {
    $rhelVersion = $OSVersion.Replace('RHEL','')
    $amiNameQuery = "RHEL-$($rhelVersion[0]).$($rhelVersion.Substring(1))_HVM_GA"

    Write-Verbose "Looking for ami names starting with $($amiNameQuery)..."

    if ( $Profile -eq '' ) {
        $rhelAMIs = (aws ec2 describe-images --region us-east-1 --owner 309956199498 --output json | ConvertFrom-Json).Images
    }
    else {
        $rhelAMIs = (aws ec2 describe-images --region us-east-1 --profile $Profile --owner 309956199498 --output json | ConvertFrom-Json).Images
    }

    $latestAMI = ($rhelAMIs | Where-Object -Property Name -Like "$($amiNameQuery)*" | Sort -Property CreationDate -Descending)[0].ImageId
}
Write-Verbose "Found $latestAMI"

# lookup who the user is running this script
$qaUser = & "whoami"
$qaUser = $qaUser.ToUpper().Replace("STEELEYE\",'')

# get parameters for template deployment
$ParameterFilePath = "$($templateURLBase)/ci/ami.json"
$parameters = [System.Collections.ArrayList] (Get-ParametersFromURL -URL $ParameterFilePath)
($parameters | Where-Object -Property ParameterKey -like QAUser).ParameterValue = $qaUser
($parameters | Where-Object -Property ParameterKey -like OSVersion).ParameterValue = $OSVersion
($parameters | Where-Object -Property ParameterKey -like AMILicenseType).ParameterValue = $LicenseType
($parameters | Where-Object -Property ParameterKey -like NodeNameTag).ParameterValue = $tag
($parameters | Where-Object -Property ParameterKey -like LatestAMI).ParameterValue = $latestAMI
($parameters | Where-Object -Property ParameterKey -like QSS3KeyPrefix).ParameterValue = "$Branch/"

if ( $OSVersion.StartsWith('WS') ) {
    $parameters.Add([PSCustomObject]@{
        ParameterKey = "DKVersion"
        ParameterValue = "$Version"
    }) > $Null

    if ( $SAP ) {
        $parameters.Add([PSCustomObject]@{
            ParameterKey = "AMIVersion"
            ParameterValue = "SAP"
        }) > $Null
    }
    else {
        $parameters.Add([PSCustomObject]@{
            ParameterKey = "AMIVersion"
            ParameterValue = "Standard"
        }) > $Null
    }
}
elseif ( $OSversion.StartsWith('RHEL') ) {
    $parameters.Add([PSCustomObject]@{
        ParameterKey = "SPSLVersion"
        ParameterValue = "$Version"
    }) > $Null
}

# format for verbose output
$parameters | Format-Table | Out-String -Stream | Write-Verbose

# format for aws cli json acceptance
$parameters = ($parameters | ConvertTo-Json).Replace("`"","\`"")

$templateURL = $templateURLBase
if ( $OSVersion.StartsWith('WS') ) {
    $templateURL += "/templates/sios-datakeeper-ami.yaml"
}
elseif ( $OSversion.StartsWith('RHEL') ) {
    $templateURL += "/templates/sios-protection-suite-ami.yaml" 
}

Write-Verbose $templateURL

$stackId = ''
if ( $Profile -eq '' ) {
    $stackId = (aws cloudformation create-stack --stack-name "$tag" --template-url "$templateURL" --parameters $parameters --region us-east-1 --capabilities "CAPABILITY_IAM" --disable-rollback --output json | ConvertFrom-Json)
}
else {
    $stackId = (aws cloudformation create-stack --stack-name "$tag" --template-url "$templateURL" --parameters $parameters --region us-east-1 --profile $Profile --capabilities "CAPABILITY_IAM" --disable-rollback --output json | ConvertFrom-Json)
}
return $stackId
