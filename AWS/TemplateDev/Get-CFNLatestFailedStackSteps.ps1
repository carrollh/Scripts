# Get-CFNLatestFailedStackSteps.ps1
# 
# Example usage:
#   PS> .\Get-CFNLatestFailedStackSteps.ps1 -Region us-east-1 -Profile currentgen
#   PS> .\Get-CFNLatestFailedStackSteps.ps1 -Region us-east-1
#

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [string] $Region = '',

    [Parameter(Mandatory=$False)]
    [string] $Profile = '',

    [Parameter(Mandatory=$False)]
    [Switch] $AllSteps
)

$stack = .\Get-CFNLatestFailedStack.ps1 -Region $Region -Profile $Profile

$stackName = $stack.StackName
Write-Verbose "stackName = $stackName"

if($AllSteps) {
    if($Profile -ne '') {
        $steps = .\Get-SSMDocumentSteps.ps1 -Region $region -Profile $profile -StackName $stackName -AllSteps -Verbose
    }
    else {
        $steps = .\Get-SSMDocumentSteps.ps1 -Region $region -StackName $stackName -AllSteps -Verbose
    }
}
else {
    if($Profile -ne '') {
        $steps = .\Get-SSMDocumentSteps.ps1 -Region $region -Profile $profile -StackName $stackName -Verbose
    }
    else {
        $steps = .\Get-SSMDocumentSteps.ps1 -Region $region -StackName $stackName -Verbose
    }
}

return $steps