# Remove-TaskCatArtifacts.ps1
[CmdletBinding()]
Param(
    [string[]] $Regions = $Null,
    [string]   $Profile = 'automation'
)

if (-Not $Regions -Or $Regions -like "all") {
    $Regions = @("eu-west-1","us-east-1","us-east-2","us-west-1","us-west-2")
}

# delete stacks first since them being gone asap is helpful
Write-Verbose "deleting stacks..."
foreach ($region in $Regions) {

    Write-Verbose "$region"
    $stack = .\Get-CFNLatestFailedStack.ps1  -Region $region -Profile $Profile -Verbose
    if ($stack -eq $Null) {
        Write-Verbose "`tno failed stacks found in region."
        Continue
    }

    if ($stack.StackStatus -like 'CREATE_FAILED') {
        Write-Verbose "`tfound failed stack $($stack.StackName)..."
        if ($stack.RootId) {
            $rootStack = (aws cloudformation describe-stacks --region $region --profile $Profile --output json | ConvertFrom-Json).Stacks | Where-Object -Property StackId -like $stack.RootId
        }
        else {
            $rootStack = $stack
        }

        Write-Verbose "`tdeleting root stack $($rootStack.StackName)"
        aws cloudformation delete-stack --stack-name $rootStack.StackName --region $region --profile $Profile
    }
}

# delete everything left behind after stacks clean themselves up
Write-Verbose "Cleaning up after taskcat stacks"
foreach ($region in $Regions) {

    Write-Verbose "$region"
    $buckets = (aws s3 ls --region $region --profile $Profile --output json).Substring(20)
    Write-Verbose "`tdeleting buckets..."
    if($buckets -ne $Null) {
        foreach ($bucket in $buckets) {
            Write-Verbose "`t`ts3://$bucket"
            aws s3 rb "s3://$bucket" --region $region --profile $Profile --force
        }
    }
    else {
        Write-Verbose "`tno s3 buckets found in region"
    }

    Write-Verbose "`tdeleting logs..."
    $logs = ((aws logs describe-log-groups --region $region --profile $Profile --output json | ConvertFrom-Json).logGroups | Where-Object -Property logGroupName -like "*tCaT-quickstart-sios-datakeeper*").logGroupName
    if($logs -ne $null) {
        foreach ($log in $logs) {
            Write-Verbose "`t`t$log"
            aws logs delete-log-group --log-group-name $log --region $region --profile $Profile
        }
    }
    else {
        Write-Verbose "`tno taskcat cloudwatch logs found in region"
    }
}
