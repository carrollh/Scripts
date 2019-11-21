# Set-AWSInstanceType.ps1
# Change the instance type for a VM in the stopped state
#
# Example:
#    .\Set-AWSInstanceType.ps1 us-east-1 i-0123456789 i3.xlarge

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True, Position=0)]
    [string] $Region = $Null,

    [Parameter(Mandatory=$True, Position=1)]
    [string] $InstanceId = $Null,

    [Parameter(Mandatory=$True, Position=2)]
    [string] $NewInstanceType = $Null
)

$typejson = "{`"Value`": `"$NewInstanceType`"}" | ConvertTo-Json
aws ec2 modify-instance-attribute --region $Region --instance-id $InstanceId --instance-type $typejson --output json