# Set-AWSTargetNodeType.ps1
# Relies on the AWS CLI, which should be installed and configured to point to our the account containing 
# cluster nodes.
#
# Example:
#   .\Set-AWSTargetNodeType.ps1 D SIOSSQLSERVER WSFCNode2 r3.large

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True, Position=0)]
    [string] $TargetNode = $Null,

    [Parameter(Mandatory=$True, Position=1)]
    [string] $Region = $Null,

    [Parameter(Mandatory=$True, Position=2)]
    [string] $NewInstanceType = $Null
)

# BEGIN
$ht = [System.Collections.Hashtable]@{}
$ht.Add("WSFCNODE1","i-011eb9937a3ecb78c")
$ht.Add("WSFCNODE2","i-08cc8a59a520d2c5c")

$instanceId = $ht[$TargetNode.ToUpper()]
$instance = Get-EC2Instance -InstanceId $instanceId -Region $Region

Write-Host ("Waiting on instance $instanceId (" + ($instance.Instances[0].Tag | Where-Object Key -like "Name").Value + " to be running as the correct type.")

$type = (aws ec2 describe-instances --region $region --instance-ids $instanceId | ConvertFrom-Json).Reservations.Instances.InstanceType
while (-Not ($type -like $NewInstanceType)) {
    Start-Sleep 5
    $type = (aws ec2 describe-instances --region $region --instance-ids $instanceId | ConvertFrom-Json).Reservations.Instances.InstanceType
}

$instance = Get-EC2Instance -InstanceId $instanceId -Region $region
$status = $instance.Instances[0].State.Name.Value
while (-Not ($status -like "running")) {
    Start-Sleep 5
    $instance = Get-EC2Instance -InstanceId $instanceId -Region $region
    $status = $instance.Instances[0].State.Name.Value
}

Write-Verbose "$TargetNode running as type $type"
Start-Sleep 10

exit 0