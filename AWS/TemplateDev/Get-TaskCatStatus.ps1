# Get-CFNLatestFailedStack.ps1
# 
# Example usage:
#   PS> .\Get-CFNLatestFailedStack.ps1 -Region us-east-1 -Profile currentgen
#   PS> .\Get-CFNLatestFailedStack.ps1 -Region us-east-1
#

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False)]
    [string[]] $Regions = $Null,

    [Parameter(Mandatory=$False)]
    [string] $Profile = 'automation'
)

$cfn, $failedStacks, $stackName = $Null
$stackTable = New-Object System.Collections.ArrayList

if (-Not $Regions -Or $Regions -like "all") {
    $Regions = @("us-east-1","us-east-2","us-west-1","us-west-2","eu-west-1")
}

$stackLabels = @('SIOSSTACK','RDGWSTACK','ADSTACK','VPCSTACK')
foreach ($region in $Regions) {
    Write-Verbose $region
    if($Profile -ne '') {
        $cfn = (aws cloudformation describe-stacks --region $Region --profile $Profile --output json | convertfrom-json).Stacks
    }
    else {
        $cfn = (aws cloudformation describe-stacks --region $Region --output json | convertfrom-json).Stacks
    }
    
    foreach ($label in $stackLabels) {
        $stack = $cfn | Where-Object -Property StackName -like "*$label*"
        if($stack) {
            $obj = [PSCustomObject]@{    
              Region = $region
              Stack = $label
              Status = $stack.StackStatus
            }
            $stackTable.Add($obj) > $Null
            Break
        }
    }
}

if ($stackTable.Count -gt 0) {
    $stackTable | Format-Table
}

