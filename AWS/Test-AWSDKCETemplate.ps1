# Test-AWSDKCETemplate.ps1
# 
# Example call: 
#   .\Test-AWSDKCETemplate.ps1 -Regions eu-west-2 -AMIType BYOL -Verbose
#   .\Test-AWSDKCETemplate.ps1 -Regions eu-west-3 -AMIType PAYG -Verbose -ParameterFilePath .\
#
# Notes:
#   There aren't any /ci/payg-*.json files in this repo as AWS can't/doesn't test them, so 
#   you'll need to provide a local path to a parameters file. You can use '.\' for ParameterFilePath,
#   and it will grab the included sios-datakeeper-master-parameters.json file. The second example 
#   above works with that file.

[CmdletBinding()]
Param(
    [string]   $ParameterFilePath = $Null,
    [string]   $StackName = "DKCE",
    [string]   $TemplateURLBase = "https://s3.amazonaws.com/quickstart-sios-datakeeper",
    [string]   $ADServerOSVersion = "2016",
    [string]   $DKServerOSVersion = "2016",
    [string]   $AMIType = "BYOL",
    [string]   $SIOSLicenseKeyFtpURL = "http://ftp.us.sios.com/pickup/EVAL_Aaron_Lima_aarlim_2019-03-19_DKCE/",
    [string]   $SQLServerVersion = "2014SP1",
    [string[]] $Regions = @("us-east-1"),
    #[string[]] $Regions = @("us-east-1","us-east-2","us-west-1","us-west-2","ca-central-1","ap-northeast-2","ap-southeast-1","ap-southeast-2","eu-central-1","sa-east-1","ap-south-1","eu-west-1","eu-west-2","eu-west-3"),
    [string]   $Branch = $Null
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

if ($Branch) {
    $TemplateURLBase += "/$Branch"
} else {
    $TemplateURLBase += "/test"
}

if (-Not $ParameterFilePath) {
    # the payg file contains the same thing as the byol one, except for fixes made below based on param values
    # so we can currently use the payg file as a base
    if($SQLServerVersion -Like "None") {
        $ParameterFilePath = $TemplateURLBase + "/ci/" + $AMIType.ToLower() + "-nosql.json"
        $SQLServerVersion = "None"
    } else {
        $ParameterFilePath = $TemplateURLBase + "/ci/" + $AMIType.ToLower() + "-sql" + $SQLServerVersion.ToLower() + ".json"
    }
    Write-Verbose "Attempting parameter read from $ParameterFilePath"
    $parameters = [System.Collections.ArrayList] (Get-ParametersFromURL -URL $ParameterFilePath)
} else {
    $parameters = [System.Collections.ArrayList] (Get-ParametersFromFile -Path "$ParameterFilePath\\sios-datakeeper-master-parameters$Branch.json")
}

if( -Not $parameters ) {
    Write-Host "Failed to parse parameters"
    exit 1
} else {
    Write-Verbose "Parameters parsed successfully"
}

$masterStacks = [ordered]@{}

foreach ($region in $Regions) {
    if( $AMIType -Like "BYOL" -AND $SIOSLicenseKeyFtpURL ) {
        ($parameters | Where-Object -Property ParameterKey -like SIOSLicenseKeyFtpURL).ParameterValue = $SIOSLicenseKeyFtpURL
    }
    
    ($parameters | Where-Object -Property ParameterKey -like AMIType).ParameterValue = $AMIType
    ($parameters | Where-Object -Property ParameterKey -like KeyPairName).ParameterValue = "AUTOMATION"
    ($parameters | Where-Object -Property ParameterKey -like ClusterNodeOSServerVersion).ParameterValue = $DKServerOSVersion
    ($parameters | Where-Object -Property ParameterKey -like SQLServerVersion).ParameterValue = $SQLServerVersion
    if( $region -like "ap-northeast-2" ) {
        ($parameters | Where-Object -Property ParameterKey -like AvailabilityZones).ParameterValue = $region+"a,"+$region+"c"
    } else {
        ($parameters | Where-Object -Property ParameterKey -like AvailabilityZones).ParameterValue = $region+"a,"+$region+"b"
    }
    ($parameters | Where-Object -Property ParameterKey -like DomainAdminPassword).ParameterValue = "SIOS!5105?sios"
    ($parameters | Where-Object -Property ParameterKey -like SQLServiceAccountPassword).ParameterValue = "SIOS!5105?sios"

    $parameters.Add([PSCustomObject]@{
        ParameterKey = "QSS3BucketName"
        ParameterValue = "quickstart-sios-datakeeper"
    }) > $Null
    
    if($Branch) {
        $parameters.Add([PSCustomObject]@{
            ParameterKey = "QSS3KeyPrefix"
            ParameterValue = "$Branch/"
        }) > $Null
    } else {
        $parameters.Add([PSCustomObject]@{
            ParameterKey = "QSS3KeyPrefix"
            ParameterValue = "test/"
        }) > $Null
    }
    
    $parameters
    $masterStacks.Add($region,(New-CFNStack -Stackname $StackName -TemplateURL "$TemplateURLBase/templates/sios-datakeeper-master.template" -Parameters $parameters -Region $region -Capabilities CAPABILITY_IAM -DisableRollback $True))
}

# $jobHT = [ordered]@{}
# foreach ($region in $Regions) {
#     $jobHT.Add($region, (Start-Job -FilePath .\Test-AWSDKCETemplateWorker.ps1 -ArgumentList $region,($masterStacks[$region]),$ParameterFilePath,$TemplateURLBase,$parameters))
# }

return $masterStacks

#$parameters = Get-ParametersFromFile -Path "C:\Users\hcarroll.STEELEYE\DKCE-DK$DKServerVersion-$DKLicenseModel-SQL$SQLServerVersion.json"
#$stack = New-CFNStack -Stackname "DKCE-DATAKEEPER" -TemplateURL $TemplateURL -Parameters $Parameters
