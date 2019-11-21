# Set-AWSTargetNodeType.ps1
# Relies on the AWS CLI, which should be installed and configured to point to our the account containing 
# cluster nodes.
#
# Example:
#   .\Set-AWSTargetNodeType.ps1 D SIOSSQLSERVER WSFCNode2 r3.large

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True, Position=0)]
    [char] $MirrorVol = $Null,

    [Parameter(Mandatory=$True, Position=1)]
    [string] $ClusterRole = $Null,

    [Parameter(Mandatory=$True, Position=2)]
    [string] $TargetNode = $Null,

    [Parameter(Mandatory=$True, Position=3)]
    [ValidateSet("c3.large","c3.xlarge","c3.2xlarge","c3.4xlarge","c5d.large","c5d.xlarge","c5d.2xlarge","c5d.4xlarge","c5d.9xlarge","c5d.18xlarge","d2.xlarge","d2.2xlarge","d2.4xlarge","d2.8xlarge","f1.2xlarge","f1.4xlarge","f1.16xlarge","g2.2xlarge","h1.2xlarge","h1.4xlarge","h1.8xlarge","h1.16xlarge","i2.xlarge","i2.2xlarge","i2.4xlarge","i3.large","i3.xlarge","i3.2xlarge","i3.4xlarge","i3.8xlarge","i3.16xlarge","i3.metal","m3.large","m3.xlarge","m3.2xlarge","m5d.large","m5d.xlarge","m5d.2xlarge","m5d.4xlarge","m5d.12xlarge","m5d.24xlarge","m5d.metal","p3dn.24xlarge","r3.large","r3.xlarge","r3.2xlarge","r3.4xlarge","r5d.large","r5d.xlarge","r5d.2xlarge","r5d.4xlarge","r5d.12xlarge","r5d.24xlarge","r5d.metal","x1.16xlarge","x1.32xlarge","x1e.xlarge","x1e.2xlarge","x1e.4xlarge","x1e.8xlarge","x1e.16xlarge","x1e.32xlarge","z1d.large","z1d.xlarge","z1d.2xlarge","z1d.3xlarge","z1d.6xlarge","z1d.12xlarge","z1d.metal")]
    [string] $NewInstanceType = $Null
)

# BEGIN
$role = Get-ClusterGroup $ClusterRole
$resources = $role | Get-ClusterResource | Where-Object { $_.ResourceType -eq "DataKeeper Volume" }
$volResource = $resources | Where-Object { $_.Name -like "DataKeeper Volume $MirrorVol" }

if($volResource -eq $Null) {
    Write-Error "DataKeeper Volume resource for mirror volume $MirrorVol not found in cluster role $ClusterRole"
    exit 1
}

if($role.OwnerNode -like $TargetNode) {
    Write-Error "The specified target node is the current source. Move the cluster resource to proceed."
    exit 1
}

if(-Not (($volResource | Get-ClusterOwnerNode).OwnerNodes.Name.Contains($TargetNode.ToUpper()))) { 
    Write-Error "The specified target node is not a potential owner for the cluster role $ClusterRole"
    exit 1
}

# if we're here then the target is valid for the mirror vol
Write-Verbose "Querying $TargetNode for its instance id"
$instanceId = invoke-command -ComputerName $TargetNode -ArgumentList $token -ScriptBlock {
    $token = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token-ttl-seconds" = "10"} -Method PUT -Uri http://169.254.169.254/latest/api/token
    Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token" = $token} -Method GET -Uri http://169.254.169.254/latest/meta-data/instance-id
}

Write-Verbose "Querying $TargetNode for its region"
$region = invoke-command -ComputerName $TargetNode -ArgumentList $token -ScriptBlock {
    $token = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token-ttl-seconds" = "10"} -Method PUT -Uri http://169.254.169.254/latest/api/token
    (Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token" = $token} -Method GET -Uri http://169.254.169.254/latest/dynamic/instance-identity/document ).region
}

Write-Verbose "Stopping $TargetNode..."
aws ec2 stop-instances --region $region --instance-ids $instanceId --output json > $Null
$status = "running"
while (-Not ($status -like "stopped")) {
    Start-Sleep 5
    $json = aws ec2 describe-instances --region $region --instance-ids $instanceId --output json | ConvertFrom-Json
    $status = $json.Reservations.Instances.State.Name
}

Write-Verbose "Resizing $TargetNode"
$typejson = "{`"Value`": `"$NewInstanceType`"}" | ConvertTo-Json
aws ec2 modify-instance-attribute --region $region --instance-id $instanceId --instance-type $typejson --output json > $Null
$type = $json.Reservations.Instances.InstanceType
while (-Not ($type -like $NewInstanceType)) {
    Start-Sleep 5
    $type = (aws ec2 describe-instances --region $region --instance-ids $instanceId | ConvertFrom-Json).Reservations.Instances.InstanceType
}

Write-Verbose "Restarting $TargetNode..."
aws ec2 start-instances --region $region --instance-ids $instanceId --output json > $Null
while (-Not ($status -like "running")) {
    Start-Sleep 5
    $json = aws ec2 describe-instances --region $region --instance-ids $instanceId --output json | ConvertFrom-Json
    $status = $json.Reservations.Instances.State.Name
}

Write-Verbose "$TargetNode running as type $type"
exit 0