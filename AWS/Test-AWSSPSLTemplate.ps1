# Test-AWSSPSLTemplate.ps1

[CmdletBinding()]
Param(
    [string] $ParameterFilePath = ".\",
    [string] $StackName = "SPSL",
    [string] $TemplateURLBase = "https://s3.amazonaws.com/quickstart-sios-protection-suite/test/templates",
    [string] $LKServerOSVersion  = "RHEL74",
    [string] $AMIType   = "BYOL",
    [string] $SIOSLicenseKeyFtpURL = "http://ftp.us.sios.com/pickup/EVAL_Joe_USer_joeuser_2018-06-12_SPSLinux/",
    [string[]] $Regions = @("us-east-1")
)

function Get-ParametersFromFile() {
    Param(
        [Parameter(Mandatory=$False,Position=0)]
        [string] $Path
    )
    
    return Get-Content $Path | Out-String | ConvertFrom-Json
}

if ( -Not (Test-Path -Path "$ParameterFilePath\\sios-protection-suite-master-parameters.json") ) {
    Write-Host "Parameter file ($ParameterFilePath\\sios-protection-suite-master-parameters.json) does not exist!"
    exit 0
} else {
    Write-Verbose "Param file found"
}

$parameters = Get-ParametersFromFile -Path "$ParameterFilePath\\sios-protection-suite-master-parameters.json"
if( -Not $parameters ) {
    Write-Host "Failed to parse param file"
} else {
    Write-Verbose "Param file parsed"
}

$masterStacks = [ordered]@{}

foreach ($region in $Regions) {
    if( $AMIType -Like "BYOL" -AND $SIOSLicenseKeyFtpURL ) {
        ($parameters | Where-Object -Property ParameterKey -like SIOSLicenseKeyFtpURL).ParameterValue = $SIOSLicenseKeyFtpURL
    }
    
    #($parameters | Where-Object -Property ParameterKey -like AMIType).ParameterValue = $AMIType
    #($parameters | Where-Object -Property ParameterKey -like ClusterNodeOSServerVersion).ParameterValue = $LKServerOSVersion
    ($parameters | Where-Object -Property ParameterKey -like AvailabilityZones).ParameterValue = $region+"a,"+$region+"b"
    $parameters
    $masterStacks.Add($region,(New-CFNStack -Stackname $StackName -TemplateURL "$TemplateURLBase/sios-protection-suite-master.template" -Parameters $parameters -Region $region -Capabilities CAPABILITY_IAM -DisableRollback $True))
}

# $jobHT = [ordered]@{}
# foreach ($region in $Regions) {
#     $jobHT.Add($region, (Start-Job -FilePath .\Test-AWSDKCETemplateWorker.ps1 -ArgumentList $region,($masterStacks[$region]),$ParameterFilePath,$TemplateURLBase,$parameters))
# }

return $masterStacks

#$parameters = Get-ParametersFromFile -Path "C:\Users\hcarroll.STEELEYE\DKCE-DK$DKServerVersion-$DKLicenseModel-SQL$SQLServerVersion.json"
#$stack = New-CFNStack -Stackname "SPSL" -TemplateURL $TemplateURL -Parameters $Parameters
