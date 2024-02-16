# Get-CFNLatestFailedStack.ps1
# 
# Example usage:
#   PS> .\Get-CFNLatestFailedStack.ps1 -Region us-east-1 -Profile currentgen
#   PS> .\Get-CFNLatestFailedStack.ps1 -Region us-east-1
#

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [string] $Region = '',

    [Parameter(Mandatory=$False)]
    [string] $Profile = ''
)

$stacks, $failedStacks = $Null

if($Profile -ne '') {
    $stacks = (& "aws" cloudformation describe-stacks --region $Region --profile $Profile --output json | ConvertFrom-Json).Stacks
}
else {
    $stacks = (& "aws" cloudformation describe-stacks --region $Region --output json | ConvertFrom-Json).Stacks
}

if ($Null -eq $stacks) {
    Write-Verbose "No stacks found?!"
}
else {
    Write-Verbose "Found $($stacks.Count) stacks"
}

$failedStacks = $stacks | Where-Object -Property StackStatus -like "CREATE_FAILED"

if($Null -eq $failedStacks) {
    return $Null
}

$stack = ($failedStacks | Sort-Object -Property CreationTime -Descending)[0]
return $stack
