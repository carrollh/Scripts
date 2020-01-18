# Stop-RunningEC2InstancesLambda.ps1
# 
# When executing in Lambda the following variables will be predefined.
#   $LambdaInput - A PSObject that contains the Lambda function input data.
#   $LambdaContext - An Amazon.Lambda.Core.ILambdaContext object that contains information about the currently running Lambda environment.
#
# The last item in the PowerShell pipeline will be returned as the result of the Lambda function.
#
# To include PowerShell modules with your Lambda function, like the AWSPowerShell.NetCore module, add a "#Requires" statement 
# indicating the module and version.

#Requires -Modules @{ModuleName='AWSPowerShell.NetCore';ModuleVersion='4.0.1.1'}

$instanceId = $LambdaInput.InstanceId
$region = $LambdaInput.Region
$type = $LambdaInput.Type

$instance = Get-EC2Instance -InstanceId $instanceId -Region $region

# exit if already the correct size
if($instance.Instances[0].InstanceType.Value -like $type) {
    Write-Host ("Nothing to do. Instance $instanceId (" + ($instance.Instances[0].Tag | Where-Object Key -like "Name").Value + " is already the correct type.")
    exit 0
}

Write-Host ("Stopping " + $instanceId + " (" + ($instance.Instances[0].Tag | Where-Object Key -like "Name").Value + ")")
Stop-EC2Instance -InstanceId $instanceId -Region $region

$status = $instance.Instances[0].State.Name.Value
while (-Not ($status -like "stopped")) {
    Start-Sleep 5
    $instance = Get-EC2Instance -InstanceId $instanceId -Region $region
    $status = $instance.Instances[0].State.Name.Value
}

Write-Host ("Changing instance type for " + $instanceId + " to " + $type)
Edit-EC2InstanceAttribute -InstanceId $instanceId -InstanceType $type

$currentType = $instance.Instances[0].InstanceType.Value
while (-Not ($currentType -like $type)) {
    Start-Sleep 5
    $instance = Get-EC2Instance -InstanceId $instanceId -Region $region
    $currentType = $instance.Instances[0].InstanceType.Value
}

Write-Host ("Starting " + $instanceId + " (" + ($instance.Instances[0].Tag | Where-Object Key -like "Name").Value + ")")
Start-EC2Instance -InstanceId $instanceId -Region $region

# END



