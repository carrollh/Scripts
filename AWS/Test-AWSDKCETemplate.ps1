# Test-AWSDKCETemplate.ps1
# 
# Example call: 
#   .\Test-AWSDKCETemplate.ps1 -Regions eu-west-2 -AMIType BYOL -OSVersion WS2019 -Verbose
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
    [string]   $StackName = "HAC-DKCE",
    [string]   $TemplateURLBase = "https://s3.amazonaws.com/quickstart-sios-datakeeper",
    [string]   $OSVersion = "WS2019",
    [string]   $AMIType = "BYOL",
    [string]   $SIOSLicenseKeyFtpURL = "http://ftp.us.sios.com/pickup/EVAL_joe_user_joe_user_2019-11-22_DKCE/",
    [string]   $SQLServerVersion = "2014SP1",
    [string[]] $Regions = $Null,
    [string]   $Branch = $Null,
    [string]   $Profile = $Null
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

if (-Not $Regions -Or $Regions -like "all") {
    $Regions = @("us-east-1","us-east-2","us-west-1","us-west-2","ca-central-1","ap-northeast-2","ap-southeast-1","ap-southeast-2","eu-central-1","sa-east-1","ap-south-1","eu-west-1","eu-west-2","eu-west-3")
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
    ($parameters | Where-Object -Property ParameterKey -like ClusterNodeOSServerVersion).ParameterValue = $OSVersion
    ($parameters | Where-Object -Property ParameterKey -like SQLServerVersion).ParameterValue = $SQLServerVersion
    if( $region -like "ap-northeast-2" -Or $region -like "sa-east-1" ) {
        ($parameters | Where-Object -Property ParameterKey -like AvailabilityZones).ParameterValue = $region+"a,"+$region+"c"
    } else {
        ($parameters | Where-Object -Property ParameterKey -like AvailabilityZones).ParameterValue = $region+"a,"+$region+"b"
    }
    ($parameters | Where-Object -Property ParameterKey -like DomainAdminPassword).ParameterValue = "SIOS!5105?sios"
    ($parameters | Where-Object -Property ParameterKey -like SQLServiceAccountPassword).ParameterValue = "SIOS!5105?sios"

    ($parameters | Where-Object -Property ParameterKey -like QSS3BucketName).ParameterValue = "quickstart-sios-datakeeper"

    if(($parameters | Where-Object -Property ParameterKey -like QSS3KeyPrefix) -eq $Null) {
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
    }

    $parameters

    if($Profile) {
        $masterStacks.Add($region,(New-CFNStack -Stackname "$StackName-$AMIType" -TemplateURL "$TemplateURLBase/templates/sios-datakeeper-master.template" -Parameters $parameters -Region $region -Capabilities CAPABILITY_IAM -DisableRollback $True -ProfileName $Profile))
    } else {
        $masterStacks.Add($region,(New-CFNStack -Stackname "$StackName-$AMIType" -TemplateURL "$TemplateURLBase/templates/sios-datakeeper-master.template" -Parameters $parameters -Region $region -Capabilities CAPABILITY_IAM -DisableRollback $True))
    }
}

# $jobHT = [ordered]@{}
# foreach ($region in $Regions) {
#     $jobHT.Add($region, (Start-Job -FilePath .\Test-AWSDKCETemplateWorker.ps1 -ArgumentList $region,($masterStacks[$region]),$ParameterFilePath,$TemplateURLBase,$parameters))
# }

return $masterStacks

#$parameters = Get-ParametersFromFile -Path "C:\Users\hcarroll.STEELEYE\DKCE-DK$DKServerVersion-$DKLicenseModel-SQL$SQLServerVersion.json"
#$stack = New-CFNStack -Stackname "DKCE-DATAKEEPER" -TemplateURL $TemplateURL -Parameters $Parameters
