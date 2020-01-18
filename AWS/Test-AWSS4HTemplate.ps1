# Test-AWSSPSLTemplate.ps1
# 
# Example call: 
#   .\Test-AWSS4HTemplate.ps1 -SIOSLicenseKeyFtpURL <license> -Regions us-east-1 -Branch develop -StackName HAC-Test -Profile currentgen -Verbose
#
# Notes:
#   

[CmdletBinding(SupportsShouldProcess)]
Param(
    [string]   $ParameterFilePath = $Null,
    [string]   $StackName = $Null,
    [string]   $TemplateURLBase = "https://s3.amazonaws.com/",
    [string]   $SIOSLicenseKeyFtpURL = "http://ftp.us.sios.com/pickup/EVAL_Joe_User_joeuser_2020-01-18_SPSLinux/",
    [string[]] $Regions = @("us-east-1"),
    [string]   $Branch = $Null,
    [string]   $Profile = "default"
)

if ($Regions -like "all") {
    $Regions = @("us-east-1","us-east-2","us-west-1","us-west-2","ca-central-1","ap-south-1","ap-northeast-2","ap-southeast-1","ap-southeast-2","eu-central-1","eu-north-1","eu-west-1","eu-west-2","eu-west-3","sa-east-1")
}

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

function Get-ProfileIndex() {
    Param(
        [string[]] $text =  $Null
    )
    if($text) {
        # lookup aws access and secret keys from local user cred file for $Profile
        write-verbose $text[0]
        $pattern = "*$Profile*"
        write-verbose $pattern
        for($i=0;$i -lt $text.length; $i=$i+1){ 
            if($text[$i] -like $pattern){
                return $i
            }
        }
    }
    return -1
}
$repo = "sios-protection-suite-s4hana"
$bucket = "quickstart-$repo"
if ($Branch) {
    $TemplateURLBase += $bucket + "/$Branch"
} else {
    $TemplateURLBase += $bucket + "/test"
}

$content = (Get-Content -Path  ~\.aws\credentials)
$index = Get-ProfileIndex $content
if($index -lt 0) {
    exit $index
}

$accessKey = (($content[$index+1] | Select-String -Pattern '^aws_access_key_id = (.+)$').Matches.Groups[1]).Value
$secretKey = (($content[$index+2] | Select-String -Pattern '^aws_secret_access_key = (.+)$').Matches.Groups[1]).Value

if (-Not $ParameterFilePath) {
    # using RHEL-RHEL until SLES versions are viable
    $ParameterFilePath = $TemplateURLBase + "/ci/RHEL-RHEL.json"
    $parameters = [System.Collections.ArrayList] (Get-ParametersFromURL -URL $ParameterFilePath)
} else {
    Write-Host "FAILED TO LOAD PARAMETER FILE"
    exit 1
}

if( -Not $parameters ) {
    Write-Host "Failed to parse parameters"
    exit 1
} else {
    Write-Verbose "Parameters parsed successfully"
}
$rac = (Invoke-WebRequest itomation.ca/mypublicip).Content + "/32"
($parameters | Where-Object -Property ParameterKey -like RemoteAccessCIDR).ParameterValue = $rac
($parameters | Where-Object -Property ParameterKey -like SIOSLicenseKeyFtpURL).ParameterValue = $SIOSLicenseKeyFtpURL
($parameters | Where-Object -Property ParameterKey -like AWSAccessKeyID).ParameterValue = $accessKey
($parameters | Where-Object -Property ParameterKey -like AWSSecretAccessKey).ParameterValue = $secretKey
($parameters | Where-Object -Property ParameterKey -like NewRootPassword).ParameterValue = "SIOS!5105?sios"
($parameters | Where-Object -Property ParameterKey -like HANAMasterPass).ParameterValue = "SIOS5105sios"
($parameters | Where-Object -Property ParameterKey -like KeyPairName).ParameterValue = "AUTOMATION"
($parameters | Where-Object -Property ParameterKey -like SAPInstallMediaBucket).ParameterValue = "sios-s4hana-linux"
($parameters | Where-Object -Property ParameterKey -like SAPInstallMediaKeyPrefix).ParameterValue = "sap"
($parameters | Where-Object -Property ParameterKey -like HANAInstallMediaKeyPrefix).ParameterValue = "hana/HANA-DB-2.0-SPS04"
($parameters | Where-Object -Property ParameterKey -like QSS3BucketName).ParameterValue = $bucket

if($Branch) {
    ($parameters | Where-Object -Property ParameterKey -like QSS3KeyPrefix).ParameterValue = "$Branch/"
} else {
    ($parameters | Where-Object -Property ParameterKey -like QSS3KeyPrefix).ParameterValue = "test/"
}

$masterStacks = [ordered]@{}

foreach ($region in $Regions) {
    ($parameters | Where-Object -Property ParameterKey -like AvailabilityZones).ParameterValue = $region+"a,"+$region+"b"
    $parameters | Format-Table | Out-String -Stream | Write-Verbose

    if($PSCmdlet.ShouldProcess($StackName)) {
        if($Profile) {
            $masterStacks.Add($region,(New-CFNStack -Stackname $StackName -TemplateURL "$TemplateURLBase/templates/$repo-master.template" -Parameters $parameters -Region $region -Capabilities CAPABILITY_IAM -DisableRollback $True -ProfileName $Profile))
        } else {
            $masterStacks.Add($region,(New-CFNStack -Stackname $StackName -TemplateURL "$TemplateURLBase/templates/$repo-master.template" -Parameters $parameters -Region $region -Capabilities CAPABILITY_IAM -DisableRollback $True))
        }
    }
}

# $jobHT = [ordered]@{}
# foreach ($region in $Regions) {
#     $jobHT.Add($region, (Start-Job -FilePath .\Test-AWSDKCETemplateWorker.ps1 -ArgumentList $region,($masterStacks[$region]),$ParameterFilePath,$TemplateURLBase,$parameters))
# }

return $masterStacks

#$parameters = Get-ParametersFromFile -Path "C:\Users\hcarroll.STEELEYE\DKCE-DK$DKServerVersion-$DKLicenseModel-SQL$SQLServerVersion.json"
#$stack = New-CFNStack -Stackname "SPSL" -TemplateURL $TemplateURL -Parameters $Parameters
