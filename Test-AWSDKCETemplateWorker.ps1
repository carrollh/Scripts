# Test-AWSDKCETemplateWorker.ps1

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True, Position=0)]
    [string] $Region,
    
    [Parameter(Mandatory=$True, Position=1)]
    [Object] $MasterStack,
    
    [Parameter(Mandatory=$False, Position=2)]
    [string] $ParameterFilePath = "C:\Users\hcarroll.STEELEYE",
    
    [Parameter(Mandatory=$False, Position=3)]
    [string] $TemplateURLBase = "https://s3.amazonaws.com/quickstart-sios-datakeeper/test/templates",
    
    [Parameter(Mandatory=$False, Position=4)]
    [Object[]] $MasterParameters,
    
    [Parameter(Mandatory=$False, Position=5)]
    [string] $AMIType = "PAYG",
    
    [Parameter(Mandatory=$False, Position=6)]
    [string] $OSVersion = "2016"
    
)

function Get-ParametersFromFile() {
    Param(
        [Parameter(Mandatory=$False,Position=0)]
        [string] $Path
    )
    
    return Get-Content $Path | Out-String | ConvertFrom-Json
}

$vpcStack = Get-CFNStack -Region $Region | Where-Object -Property StackName -Like ($MasterStack.StackName + "-VPCStack*")
$adStack = Get-CFNStack -Region $Region | Where-Object -Property StackName -Like ($MasterStack.StackName + "-ADStack*")


$parameters = Get-ParametersFromFile -Path "$ParameterFilePath\\sios-datakeeper-parameters.json"

# wait for the vpc stack to get to CREATE_COMPLETE, break out if failure with status code
# get outputs from vpc stack (subnet ids, etc)
# add needed output ids from vpc stack to parameter array

if( $AMIType -Like "BYOL" -AND $SIOSLicenseKeyFtpURL ) {
    ($parameters | Where-Object -Property ParameterKey -like SIOSLicenseKeyFtpURL).ParameterValue = $SIOSLicenseKeyFtpURL
}

($parameters | Where-Object -Property ParameterKey -like AMIType).ParameterValue = $AMIType
($parameters | Where-Object -Property ParameterKey -like OSVersion).ParameterValue = $OSVersion
($parameters | Where-Object -Property ParameterKey -like DomainMemberSGID).ParameterValue = ($adStack.Outputs | Where-Object -Property OutputKey -Like "DomainMemberSGID").OutputValue
($parameters | Where-Object -Property ParameterKey -like VPCID).ParameterValue = ($vpcStack.Outputs | Where-Object -Property OutputKey -Like "VPCID").OutputValue
($parameters | Where-Object -Property ParameterKey -like PrivateSubnet1ID).ParameterValue = ($vpcStack.Outputs | Where-Object -Property OutputKey -Like "PrivateSubnet1AID").OutputValue
($parameters | Where-Object -Property ParameterKey -like PrivateSubnet2ID).ParameterValue = ($vpcStack.Outputs | Where-Object -Property OutputKey -Like "PrivateSubnet2AID").OutputValue
($parameters | Where-Object -Property ParameterKey -like SQLServerVersion).ParameterValue = $sqlServerVersion

$parameters

return New-CFNStack -Stackname "DKCE-DataKeeper" -TemplateURL "$TemplateURLBase/sios-datakeeper.template" -Parameters ($parameters) -Region $region -Capabilities CAPABILITY_IAM -DisableRollback $True

# wait for ad stack to get to CREATE_COMPLETE, break out if failure with status code
# wait for rdgw stack to get to CREATE_COMPLETE, break out if failure with status code
# wait for sios stack to get to CREATE_COMPLETE, break out if failure with status code
# delete sios stack
# wait for sios stack to fully delete

#prepare parameters to create next 3 endpoint template tests

# sios-datakeeper.template deploy 2
# sios-datakeeper.template deploy 3
# sios-datakeeper.template deploy 4



# Get the needed params from the vpc stack (subnet ids)
