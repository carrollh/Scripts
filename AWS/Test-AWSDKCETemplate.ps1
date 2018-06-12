# Test-AWSDKCETemplate.ps1
Param(
    [string] $ParameterFilePath = ".\",
    [string] $StackName = "DKCE",
    [string] $TemplateURLBase = "https://s3.amazonaws.com/quickstart-sios-datakeeper/test/templates",
    [string] $ADServerOSVersion  = "2016",
    [string] $DKServerOSVersion  = "2016",
    [string] $AMIType   = "BYOL",
    [string] $SIOSLicenseKeyFtpURL = "http://ftp.us.sios.com/pickup/EVAL_Joe_User_joeuser_2018-06-12_DKCE/",
    [string] $SQLServerVersion = "2014SP1",
    [string[]] $Regions = @("us-east-1")
)

function Get-ParametersFromFile() {
    Param(
        [Parameter(Mandatory=$False,Position=0)]
        [string] $Path
    )
    
    return Get-Content $Path | Out-String | ConvertFrom-Json
}

if( -Not (Test-Path -Path "$ParameterFilePath\\sios-datakeeper-master-parameters.json")) {
    Write-Host "Parameter file ($ParameterFilePath\\sios-datakeeper-master-parameters.json) does not exist!"
    exit 0
} else {
    Write-Verbose "Param file found"
}

$parameters = Get-ParametersFromFile -Path "$ParameterFilePath\\sios-datakeeper-master-parameters.json"
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
    
    ($parameters | Where-Object -Property ParameterKey -like AMIType).ParameterValue = $AMIType
    ($parameters | Where-Object -Property ParameterKey -like ADServerOSVersion).ParameterValue = $ADServerOSVersion
    ($parameters | Where-Object -Property ParameterKey -like ClusterNodeOSServerVersion).ParameterValue = $DKServerOSVersion
    ($parameters | Where-Object -Property ParameterKey -like SQLServerVersion).ParameterValue = $SQLServerVersion
    ($parameters | Where-Object -Property ParameterKey -like AvailabilityZones).ParameterValue = $region+"a,"+$region+"b"
    $parameters
    $masterStacks.Add($region,(New-CFNStack -Stackname $StackName -TemplateURL "$TemplateURLBase/sios-datakeeper-master.template" -Parameters $parameters -Region $region -Capabilities CAPABILITY_IAM -DisableRollback $True))
}

# $jobHT = [ordered]@{}
# foreach ($region in $Regions) {
#     $jobHT.Add($region, (Start-Job -FilePath .\Test-AWSDKCETemplateWorker.ps1 -ArgumentList $region,($masterStacks[$region]),$ParameterFilePath,$TemplateURLBase,$parameters))
# }

return $masterStacks

#$parameters = Get-ParametersFromFile -Path "C:\Users\hcarroll.STEELEYE\DKCE-DK$DKServerVersion-$DKLicenseModel-SQL$SQLServerVersion.json"
#$stack = New-CFNStack -Stackname "DKCE-DATAKEEPER" -TemplateURL $TemplateURL -Parameters $Parameters
