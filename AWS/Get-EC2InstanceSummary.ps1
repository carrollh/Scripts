# Get-EC2InstanceSummary.ps1
#
# Example 1 (super simple):
#   $instanceSummary = .\Get-EC2InstanceSummary.ps1 -Profile "dev" -Regions "ca-central-1"
#
# Example 2 (for use with other scripts or saving as json doc):
#   $ht = @{}
#   $ps = @("dev","currentgen")
#   $rs = @("ca-central-1","us-east-1","us-east-2","us-west-1","us-west-2")
#   foreach($p in $ps){ 
#       $profileInfo = .\Get-EC2InstanceSummary.ps1 -Profile $p -Regions $rs
#       $ht.Add($p, $profileInfo)
#   }
#   $ht | ConvertTo-Json -Depth 10 | Out-File -Encoding utf8 -FilePath "C:\Users\hcarroll\Desktop\AWS_Summary.txt"
#
# Example 3 (for easy to read output in a file; edit $outfile FIRST):
#   $ps = @("dev","currentgen")
#   $rs = @("ca-central-1","us-east-1","us-east-2","us-west-1","us-west-2")
#   $outfile = "C:\Users\hcarroll\Desktop\AWS_Summary"
#   foreach($p in $ps){ 
#       $ec2info = .\Get-EC2InstanceSummary.ps1 -Profile $p
#       foreach($r in $rs){
#           "`n$r" >> "$outfile\${p}_instances"
#           echo $ec2info["$r"] | ft >> "$outfile\${p}_instances"
#       }
#   }

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False)]
    [string] $Profile = $Null,

    [Parameter(Mandatory=$False)]
    [string[]] $Regions = @("ap-east-1","ap-northeast-1","ap-northeast-2","ap-south-1","ap-southeast-1","ap-southeast-2","ca-central-1","eu-central-1","eu-north-1","eu-west-1","eu-west-2","eu-west-3","me-south-1","sa-east-1","us-east-1","us-east-2","us-west-1","us-west-2")
)

Write-Verbose "`tGet-EC2InstanceSummary - START"
Write-Verbose "`t`tParameters ($($PsBoundParameters.Values.Count)):"
$PsBoundParameters.Keys | foreach {
    Write-Verbose "`t`t$_ = $($PsBoundParameters[$_])"
}
$instanceTable = [Ordered]@{}
foreach ($region in $Regions) {
    Write-Verbose "`t`t$region"
    $instances = $Null
    $tags = $Null
    if($Profile) {
        Write-Verbose "---`taws ec2 describe-instances --region $region --profile $Profile --output json"
        $instances = (& "aws" ec2 describe-instances --region $region --profile $Profile --output json | convertfrom-json).Reservations.Instances
        Write-Verbose "---`taws ec2 describe-tags --region $region --profile $Profile --filters `"Name=resource-type,Values=instance`" `"Name=key,Values=Name`" --output json"
        $tags = (& "aws" ec2 describe-tags --region $region --profile $Profile --filters "Name=resource-type,Values=instance" "Name=key,Values=Name" --output json | convertfrom-json).Tags
    }
    else {
        Write-Verbose "---`taws ec2 describe-instances --region $region --output json"
        $instances = (& "aws" ec2 describe-instances --region $region --output json | convertfrom-json).Reservations.Instances
        Write-Verbose "---`taws ec2 describe-tags --region $region --filters `"Name=resource-type,Values=instance`" `"Name=key,Values=Name`" --output json"
        $tags = (& "aws" ec2 describe-tags --region $region --filters "Name=resource-type,Values=instance" "Name=key,Values=Name" --output json | convertfrom-json).Tags
    }

    $instanceInfo = [System.Collections.ArrayList]@()
    $instances | %{
        $nametag = ($tags | Where-Object -Property ResourceId -like ($_.InstanceId)).Value
        if($nametag -like ''){
            $nametag = "N/A"
        }
        $obj = [PSCustomObject]@{
            InstanceId       = $_.InstanceId
            InstanceType     = $_.InstanceType
            InstanceNameTag  = $nametag
            LaunchTime       = $_.LaunchTime
            State            = $_.State.Name
            TransitionReason = $_.StateTransitionReason
        }
        $instanceInfo.Add($obj) > $Null
    }

    $instanceTable.Add($region, ($instanceInfo | Sort-Object -Property LaunchTime)) > $Null
}

Write-Verbose "`tGet-EC2InstanceSummary - END"
return $instanceTable
# END
