# Get-EC2Userdata.ps1
# 
# Example usage:
#   PS> .\Get-EC2Userdata.ps1 -Region us-east-1 -Profile currentgen -InstanceId i-0123456789
#   PS> .\Get-EC2Userdata.ps1 -Region us-east-1 -InstanceId i-0123456789
#

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [string] $InstanceId = '',

    [Parameter(Mandatory=$True)]
    [string] $Region = '',

    [Parameter(Mandatory=$False)]
    [string] $Profile = ''
)

if ($Profile -eq '') {
    $userdataBase64 = (aws ec2 describe-instance-attribute --attribute userData --instance-id $InstanceId --region $Region --output json | ConvertFrom-Json).UserData.Value
}
else {
    $userdataBase64 = (aws ec2 describe-instance-attribute --attribute userData --instance-id $InstanceId --region $Region --profile $Profile --output json | ConvertFrom-Json).UserData.Value
}

$userdata = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($userdataBase64)).Replace(";","`n")

return $userdata