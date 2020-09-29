# Get-AWSUserdata.ps1
# 
# Example usage:
#   PS> .\Get-AWSUserdata.ps1 -Region ap-northeast-1 -Profile currentgen -InstanceId i-01234567890
#

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [string] $Region = "",

    [Parameter(Mandatory=$False)]
    [string] $Profile = "",

    [Parameter(Mandatory=$True)]
    [string] $InstanceId = ""
)

$UserData_encoded = (Get-EC2InstanceAttribute -InstanceId $InstanceId -Attribute userData -Region $Region -ProfileName $Profile).UserData
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($UserData_encoded))