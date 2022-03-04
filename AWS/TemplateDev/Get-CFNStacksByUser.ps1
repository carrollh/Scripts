# Get-CFNStacksByUser.ps1
# 
# Example usage: 
#

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True, Position=0)]
    [string] $User = '',

    [Parameter(Mandatory=$False, Position=1)]
    [string] $Profile = '',

    [Parameter(Mandatory=$False, Position=2)]
    [String[]] $Regions = $Null,

    [Parameter(Mandatory=$False, Position=3)]
    [Switch] $RootOnly = $False
)

if( -Not $Regions -Or $Regions -like "all") {
    $Regions = @("ap-northeast-2","ap-south-1","ap-southeast-1","ap-southeast-2","ca-central-1","eu-central-1","eu-north-1","eu-west-1","eu-west-2","eu-west-3","sa-east-1","us-east-1","us-east-2","us-west-1","us-west-2")
}

$results = [ordered]@{}

foreach ($region in $Regions) {
    Write-Verbose "$region"
    if($Profile) {
        $stacks = (aws cloudformation describe-stacks --profile $Profile --region $region --output json | ConvertFrom-Json).Stacks | Where-Object -Property StackName -like "$($User)*"
    }
    else {
        $stacks = (aws cloudformation describe-stacks --region $region --output json | ConvertFrom-Json).Stacks | Where-Object -Property StackName -like "$($User)*"
    }

    if($RootOnly) {
        $stacks = $stacks | Where-Object -Property ParentId -like ''
    }

    foreach ($stack in $stacks) {
        Write-Verbose "`t$($stack.StackName)"
    }

    $results.Add("$region", $stacks)
}

$results