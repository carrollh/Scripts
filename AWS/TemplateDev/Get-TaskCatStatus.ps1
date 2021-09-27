# Get-CFNLatestFailedStack.ps1
# 
# Example usage:
#   PS> .\Get-CFNLatestFailedStack.ps1 -Region us-east-1 -Profile currentgen
#   PS> .\Get-CFNLatestFailedStack.ps1 -Region us-east-1
#

[CmdletBinding()]
Param(
    [ValidateSet('DK','QA')]
    [Parameter(Mandatory=$true, Position=0)]
    [string] $Template,

    [Parameter(Mandatory=$False)]
    [string[]] $Regions = $Null,

    [Parameter(Mandatory=$False)]
    [string] $Profile = 'automation',

    [Parameter(Mandatory=$False)]
    [switch] $IgnoreMissing
)

$cfn, $failedStacks, $stackName = $Null
$stackTable = New-Object System.Collections.ArrayList

if (-Not $Regions) {
    if ($Template -eq 'DK') {
        $Regions = @('ap-south-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','eu-west-3','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2')
    }
    if ($Template -eq 'QA') {
        $Regions = @('ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1')
    }
}

$stackLabels = @('WSFCSTACK','SPSWSTACK','SIOSSTACK','RDGWSTACK','ADSTACK','VPCSTACK')
foreach ($region in $Regions) {
    Write-Verbose $region
    if($Profile -ne '') {
        $cfn = (aws cloudformation describe-stacks --region $Region --profile $Profile --output json | convertfrom-json).Stacks
    }
    else {
        $cfn = (aws cloudformation describe-stacks --region $Region --output json | convertfrom-json).Stacks
    }

    $foundStack = $False
    foreach ($label in $stackLabels) {

        $stack = $cfn | Where-Object -Property StackName -like "*$label*"

        if($stack) {

            if ($stack.RootId) {
                $rootStack = (aws cloudformation describe-stacks --region $region --profile $Profile --output json | ConvertFrom-Json).Stacks | Where-Object -Property StackId -like $stack.RootId
            }
            else {
                $rootStack = $stack
            }

            if (($rootStack.Parameters | Where-Object -Property ParameterKey -like ADScenarioType).ParameterValue -like 'Microsoft AD on Amazon EC2') {
                $adScenario = 'SAD'
            }
            else {
                $adScenario = 'MAD'
            }

            $obj = [PSCustomObject]@{    
                Region = $region
                Stack = $label
                Status = $stack.StackStatus
                OSVersion = ($rootStack.Parameters | Where-Object -Property ParameterKey -like ClusterNodeOSServerVersion).ParameterValue
                AmiType = ($rootStack.Parameters | Where-Object -Property ParameterKey -like AmiType).ParameterValue
                SQLVersion = ($rootStack.Parameters | Where-Object -Property ParameterKey -like SQLServerVersion).ParameterValue
                ADScenario = $adScenario
                ThirdAZ = ($rootStack.Parameters | Where-Object -Property ParameterKey -like ThirdAZ).ParameterValue
            }
            $stackTable.Add($obj) > $Null

            $foundStack = $True
            Break
        }
    }
    
    if((-Not $IgnoreMissing) -And (-Not $foundStack)) {
        $obj = [PSCustomObject]@{    
            Region = $region
            Stack = ''
            Status = ''
            OSVersion = ''
            AmiType = ''
            SQLVersion = ''
            ADScenario = ''
            ThirdAZ = ''
        }
        $stackTable.Add($obj) > $Null
    }
}

if ($stackTable.Count -gt 0) {
    $stackTable | Format-Table
}

