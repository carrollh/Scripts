﻿# Test-AWSSPSLTemplate.ps1

[CmdletBinding()]
Param(
    [string] $ParameterFilePath = "C:\Users\hcarroll.STEELEYE",
    [string] $StackName = "SPSL",
    [string] $TemplateURLBase = "https://s3.amazonaws.com/quickstart-sios-lifekeeper/test/templates",
    [string] $LKServerOSVersion  = "RHEL74",
    [string] $AMIType   = "PAYG",
    [string] $SIOSLicenseKeyFtpURL = "",
    [string[]] $Regions = @("us-east-1","eu-west-1","eu-west-2","eu-west-3")
)

function Get-ParametersFromFile() {
    Param(
        [Parameter(Mandatory=$False,Position=0)]
        [string] $Path
    )
    
    return Get-Content $Path | Out-String | ConvertFrom-Json
}

if ( -Not (Test-Path -Path "$ParameterFilePath\\sios-lifekeeper-master-parameters.json") ) {
    Write-Host "Parameter file ($ParameterFilePath\\sios-lifekeeper-master-parameters.json) does not exist!"
    exit 0
} else {
    Write-Verbose "Param file found"
}

$parameters = Get-ParametersFromFile -Path "$ParameterFilePath\\sios-lifekeeper-master-parameters.json"
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
    $masterStacks.Add($region,(New-CFNStack -Stackname $StackName -TemplateURL "$TemplateURLBase/sios-lifekeeper-master.template" -Parameters $parameters -Region $region -Capabilities CAPABILITY_IAM -DisableRollback $True))
}

# $jobHT = [ordered]@{}
# foreach ($region in $Regions) {
#     $jobHT.Add($region, (Start-Job -FilePath .\Test-AWSDKCETemplateWorker.ps1 -ArgumentList $region,($masterStacks[$region]),$ParameterFilePath,$TemplateURLBase,$parameters))
# }

return $masterStacks

#$parameters = Get-ParametersFromFile -Path "C:\Users\hcarroll.STEELEYE\DKCE-DK$DKServerVersion-$DKLicenseModel-SQL$SQLServerVersion.json"
#$stack = New-CFNStack -Stackname "DKCE-DATAKEEPER" -TemplateURL $TemplateURL -Parameters $Parameters
