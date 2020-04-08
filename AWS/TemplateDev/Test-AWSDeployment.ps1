# Test-AWSDeployment.ps1
# 
# Example call: 
#    Test-AWSDeployment.ps1 -Template sap-syb753-abap
#    Test-AWSDeployment.ps1 -Template sios-protection-suite-for-sap-optimized
#    Test-AWSDeployment.ps1 -Template sios-protection-suite-no-cluster -OSVersion RHEL76
#
# Notes:
#   
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("sap-syb753-abap","no-cluster", "for-sap-optimized")]
    [String] $Template = $Null,

    [Parameter(Mandatory=$false)]
    [ValidateSet("SLES12SP1","SLES12SP2","SLES12SP3","SLES12SP4","SLES15","SLES15SP1","RHEL74","RHEL75","RHEL76","RHEL80")]
    [String] $OSVersion = $Null,

    [Parameter(Mandatory=$false)]
    [String] $Label = $Null
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

### MAIN ##############################################################################
[string]   $templateURLBase = "https://s3.amazonaws.com/quickstart-sios-protection-suite-$Template/test"
[string]   $templateURL = "$templateURLBase/templates/sios-protection-suite-$Template-master.template"
[string[]] $LinuxOSVersions = "SLES12SP1","SLES12SP2","SLES12SP3","SLES12SP4","SLES15","SLES15SP1","RHEL74","RHEL75","RHEL76","RHEL80"
if($Template -eq "sios-protection-suite-no-cluster" -AND -Not $LinuxOSVersions.Contains($OSVersion)) {
        Write-Error "USAGE`nNew-AWSDeployment.ps1 -Region us-east-1 -Template sios-protection-suite-no-cluster -OSversion <SLES12SP1|SLES12SP2|SLES12SP3|SLES12SP4|SLES15|SLES15SP1|RHEL74|RHEL75|RHEL76|RHEL80> -Verbose"
        return 1
}

# look up common params from ci file
$ParameterFilePath = $TemplateURLBase + "/ci/byol.json"
$parameters = [System.Collections.ArrayList] (Get-ParametersFromURL -URL $ParameterFilePath)

# bork out if parameters not set
if( -Not $parameters ) {
    Write-Error "Failed to parse parameters"
    return 1
} else {
    Write-Verbose "Parameters parsed successfully"
}

# lookup aws access and secret keys from local user creds
$accessKey = ((Select-String -Path ~\.aws\credentials -Pattern '^aws_access_key_id = (.+)$').Matches[6].Groups[1]).Value
$secretKey = ((Select-String -Path ~\.aws\credentials -Pattern '^aws_secret_access_key = (.+)$').Matches[6].Groups[1]).Value

# update params
($parameters | Where-Object -Property ParameterKey -like AvailabilityZones).ParameterValue = $region+"a,"+$region+"b"
($parameters | Where-Object -Property ParameterKey -like AWSAccessKeyID).ParameterValue = $accessKey
($parameters | Where-Object -Property ParameterKey -like AWSSecretAccessKey).ParameterValue = $secretKey
$kpn = ($parameters | Where-Object -Property ParameterKey -like KeyPairName).ParameterValue
$npw = ($parameters | Where-Object -Property ParameterKey -like NewRootPassword).ParameterValue
$slu = ($parameters | Where-Object -Property ParameterKey -like SIOSLicenseKeyFtpURL).ParameterValue
$rac = ($parameters | Where-Object -Property ParameterKey -like RemoteAccessCIDR).ParameterValue

$parameters | Format-Table | Out-String -Stream | Write-Verbose

# create label using username
$customLabel = ""
if($Label -ne $Null) {
    $customLabel = $Label.ToUpper();
}
else {
    $customLabel = & "whoami"
    $customLabel = $customLabel.ToUpper().Replace("STEELEYE\","")
    if($Template -eq "sios-protection-suite-no-cluster") {
        $customLabel += "-$OSVersion-QA"
    } else {
        $customLabel += "-SPSL-QA"
    }
}

# launch deployment
Write-Verbose $templateURL

Switch ($Template) {
    "sap-syb753-abap" {
        & "aws" cloudformation create-stack --profile currentgen --region us-east-1 --stack-name $customLabel --template-url $templateURL --parameters ParameterKey=AWSAccessKeyID,ParameterValue=$accessKey ParameterKey=AWSSecretAccessKey,ParameterValue=$secretKey ParameterKey=AvailabilityZones,ParameterValue="us-east-1a\,us-east-1b" ParameterKey=RemoteAccessCIDR,ParameterValue=$rac --capabilities CAPABILITY_IAM
        break
    }
    "for-sap-optimized" {
        & "aws" cloudformation create-stack --profile currentgen --disable-rollback --region us-east-1 --stack-name $customLabel --template-url $templateURL --parameters ParameterKey=AWSAccessKeyID,ParameterValue=$accessKey ParameterKey=AWSSecretAccessKey,ParameterValue=$secretKey ParameterKey=AvailabilityZones,ParameterValue="us-east-1a\,us-east-1b" ParameterKey=RemoteAccessCIDR,ParameterValue=$rac ParameterKey=KeyPairName,ParameterValue=$kpn ParameterKey=NewRootPassword,ParameterValue=$npw ParameterKey=SIOSLicenseKeyFtpURL,ParameterValue=$slu --capabilities CAPABILITY_IAM
        break
    }
    "no-cluster" {
        & "aws" cloudformation create-stack --profile currentgen --region us-east-1 --stack-name $customLabel --template-url $templateURL --parameters ParameterKey=AWSAccessKeyID,ParameterValue=$accessKey ParameterKey=AWSSecretAccessKey,ParameterValue=$secretKey ParameterKey=AvailabilityZones,ParameterValue="us-east-1a\,us-east-1b" ParameterKey=RemoteAccessCIDR,ParameterValue=$rac --capabilities CAPABILITY_IAM
        break
    }
}

return $results