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

$cfn, $failedStacks, $stackName = $Null

if($Profile -ne '') {
    $cfn = & "aws" cloudformation describe-stacks --region $Region --profile $Profile --output json | convertfrom-json
}
else {
    $cfn = & "aws" cloudformation describe-stacks --region $Region --output json | convertfrom-json
}
Write-Verbose $cfn

$failedStacks = $cfn.Stacks | Where-Object -Property StackStatus -eq 'CREATE_FAILED'
Write-Verbose $failedStacks.Count

$stack = ($failedStacks | Sort-Object -Property CreationTime -Descending)[0]

return $stack