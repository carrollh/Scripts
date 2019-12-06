# Get-RunningEC2InstancesLambda.ps1
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

$emailMessage = ""

# loop over regions looking for running instances and build the first part of the message along the way
$grandTotalRunningVMsFound = 0
$grandTotalVMsFound = 0
$finalTable = @{}

$regions = @("ap-northeast-1","ap-northeast-2","ap-south-1","ap-southeast-1","ap-southeast-2","ca-central-1","eu-central-1","eu-north-1","eu-west-1","eu-west-2","eu-west-3","sa-east-1","us-east-1","us-east-2","us-west-1","us-west-2")
$totalRunningVMsFound = 0
$totalVMsFound = 0
[System.Collections.ArrayList]$customList = @()
foreach ( $region in $regions ) {
    [System.Collections.ArrayList]$runningVMs = @()
    $instances = Get-EC2Instance -Region $region
    $instances.Instances | % { if ($_.State.Name -like "running") { $runningVMs.Add($_) > $Null } }

    $numRunningVMsFound = $runningVMs.Count
    $numVMsFound = $instances.Count
    $message = "Found " + $runningVMs.Count + "/" + $instances.Count + " running in " + $region + ".`n"
    $emailMessage += $message

    for ( $i=0; $i -lt $runningVMs.Length; $i+=1 ) {
        if($runningVMs[$i].Count -gt 0) {
            $customList.Add($runningVMs[$i]) > $Null
        }
    }

    if ($runningVMs.Count -gt 0) {
        $totalRunningVMsFound += $numRunningVMsFound
        $totalVMsFound += $numVMsFound
    }
}

$emailMessage += "Found a grand total of $totalRunningVMsFound running (out of $totalVMsFound) across all " + $regions.Count + " regions"
Write-Host $emailMessage
return $customList
# END



