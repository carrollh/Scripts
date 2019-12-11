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

$instance = Get-EC2Instance -InstanceId $LambdaInput.InstanceId -Region $LambdaInput.Region
Write-Host ("Stopping " + $LambdaInput.InstanceId + " (" + ($instance.Instances[0].Tag | Where-Object Key -like "Name").Value + ")")
Stop-EC2Instance -InstanceId $LambdaInput.InstanceId -Region $LambdaInput.Region

$status = $instance.Instances[0].State.Name.Value
while (-Not ($status -like "stopped")) {
    Start-Sleep 5
    $instance = Get-EC2Instance -InstanceId $LambdaInput.InstanceId -Region $LambdaInput.Region
    $status = $instance.Instances[0].State.Name.Value
}

Write-Host ("Changing instance type for " + $LambdaInput.InstanceId + " to " + $LambdaInput.Type)
Edit-EC2InstanceAttribute -InstanceId $LambdaInput.InstanceId -InstanceType $LambdaInput.Type

$currentType = $instance.Instances[0].InstanceType.Value
while (-Not ($currentType -like $LambdaInput.Type)) {
    Start-Sleep 5
    $instance = Get-EC2Instance -InstanceId $LambdaInput.InstanceId -Region $LambdaInput.Region
    $currentType = $instance.Instances[0].InstanceType.Value
}

Write-Host ("Starting " + $LambdaInput.InstanceId + " (" + ($instance.Instances[0].Tag | Where-Object Key -like "Name").Value + ")")
Start-EC2Instance -InstanceId $LambdaInput.InstanceId -Region $LambdaInput.Region

# END



