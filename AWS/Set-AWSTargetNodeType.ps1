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
    [string] $NewInstanceType = $Null,

    [Parameter(Mandatory=$False)]
    [switch] $Lambda
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

if($Lambda) {

    $payload = @{
        InstanceId = $instanceId
        Region = $region
        Type = $type
    } | ConvertTo-Json

    Invoke-LMFunction -FunctionName Set-TargetNodeType -Region $region -InvocationType Event -Payload $payload

} else {
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
}
exit 0