# Get-SSMDocumentSteps.ps1
# 
# Example usage:
#   PS> .\Get-SSMDocumentSteps.ps1 -StackName SIOSStack -Profile currentgen
#   PS> .\Get-SSMDocumentSteps.ps1 -Profile currentgen
#

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [string] $StackName = "",

    [Parameter(Mandatory=$True)]
    [string] $Region = "",

    [Parameter(Mandatory=$False)]
    [string] $Profile = "",

    [Parameter(Mandatory=$False)]
    [Switch] $AllSteps
)

$steps, $executionId, $ssm, $step, $docs = $Null

if($Profile -ne "") {
    $ssm = & "aws" ssm describe-automation-executions --region $Region --profile $Profile | convertfrom-json
}
else {
    $ssm = & "aws" ssm describe-automation-executions --region $Region | convertfrom-json
}

$docs = $ssm.AutomationExecutionMetadataList | Where-Object -Property DocumentName -like "$StackName*"

if(-Not $docs) {
    Write-Verbose "SSM Document not found. Try again later."
    return
}

$executionId = $docs[0].AutomationExecutionId
Write-Verbose "AutomationExecutionId = $executionId"

if($Profile -ne "") {
    $results = & "aws" ssm get-automation-execution --automation-execution-id $executionId --region $Region --profile $Profile | convertfrom-json
}
else {
    $results = & "aws" ssm get-automation-execution --automation-execution-id $executionId --region $Region | convertfrom-json
}

$steps = $results.AutomationExecution.StepExecutions

if($AllSteps) {
    return $steps
}

$step = $steps | Where-Object -Property StepStatus -like "Failed"
if($step) {
    Write-Verbose "FAILURE"
}
else {
    $step = $steps | Where-Object -Property StepStatus -like "InProgress"
    Write-Verbose "IN PROGRESS"
}

$($ssm.AutomationExecutionMetadataList | Where-Object -Property DocumentName -like "$StackName*")[0]

if($step) {
   return $step 
}
else {
   Write-Verbose "SUCCESS"
   return $NULL
}