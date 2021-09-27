# Remove-TaskCatArtifacts.ps1
[CmdletBinding()]
Param(
    [ValidateSet('DK','QA')]
    [Parameter(Mandatory=$true, Position=0)]
    [string]   $Template,

    [Parameter(Mandatory=$false)]
    [string[]] $Regions = $Null,

    [Parameter(Mandatory=$false)]
    [string]   $Profile = 'automation',

    [Parameter(Mandatory=$false)]
    [switch]   $FailedOnly
)

if (-Not $Regions) {
    if ($Template -eq 'DK') {
        $Regions = @('ap-south-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','eu-west-3','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2')
    }
    if ($Template -eq 'QA') {
        $Regions = @('ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1')
    }
}

if ($Template -eq 'DK') {
    $stackPattern = "tCaT-quickstart-sios-datakeeper-ws"
    $bucketPattern = "quickstart-sios-datakeeper"
}
if ($Template -eq 'QA') {
    $stackPattern = "tCaT-quickstart-sios-qa-"
    $bucketPattern = "quickstart-sios-qa"
}

foreach ($region in $Regions) {

    Write-Verbose "$region"
    if ($FailedOnly) {
        $stack = .\Get-CFNLatestFailedStack.ps1 -Region $region -Profile $Profile
        if ($stack -eq $Null) {
            Write-Verbose "`tno failed stacks found in region."
            Continue
        }
    }

    $stacks = (aws cloudformation describe-stacks --region $Region --profile $Profile --output json | ConvertFrom-Json).Stacks | Where-Object -Property StackName -like "*$stackPattern*"
    foreach ($stack in $stacks) {
        if (-Not ($stack.RootId)) {
            Write-Verbose "`tdeleting root stack $($stack.StackName)"
            aws cloudformation delete-stack --stack-name $stack.StackName --region $region --profile $Profile
        }
    }

    Write-Verbose "$region"
    $buckets = (aws s3 ls --region $region --profile $Profile --output json).Substring(20)
    Write-Verbose "`tdeleting buckets..."
    if($buckets -ne $Null) {
        foreach ($bucket in $buckets) {
            $files = [string[]](aws s3 ls "s3://$bucket" --region $region --profile $Profile)
            if($files -And ($files[0] -like "*$bucketPattern*")) {
                Write-Verbose "`t`ts3://$bucket"
                if((aws s3api get-bucket-versioning --bucket $bucket --profile $Profile --output json | ConvertFrom-Json).Status -eq 'Enabled') {
                    Write-Verbose "`t`tversioning enabled, skipping"
                }
                else {
                    aws s3 rb "s3://$bucket" --region $region --profile $Profile --force > $Null
                }
            }
        }
    }
    else {
        Write-Verbose "`tno s3 buckets found in region"
    }

    Write-Verbose "`tdeleting logs..."
    $logs = ((aws logs describe-log-groups --region $region --profile $Profile --output json | ConvertFrom-Json).logGroups | Where-Object -Property logGroupName -like "*$stackPattern*").logGroupName
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
