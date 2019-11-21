# Get-AllEC2Instances.ps1
# Relies on the AWS CLI, which should be installed and configured to point to our CurrentGen account.
# 
# The following commands were run to create a secure text password file. The password and username
# used are for an account on the smtp server used. There are better ways to do this that don't require
# having a hashed password file somewhere on the system. This is just a proof of concept. 
#
#    $password = "********"
#    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force 
#    $securePassword | ConvertFrom-SecureString | Set-Content "C:\password.txt" 
#
# $securePasswordFilePath should be created using method above, and 
# the "********" should be the password for the $hancockUser profile 

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False)]
    [string[]]$Profiles = @("dev","support","qa","ps","ts","currentgen"),

    [Parameter(Mandatory=$False)]
    [string[]] $Regions = $Null
)

# BEGIN

# loop over regions looking for instances
$finalTable = @{}
foreach ( $p in $Profiles ) {
    Write-Verbose ("Scanning the " + $p.ToUpper() + " profile")

    if ($Regions -eq $Null) {
        $TargetRegions = $(aws ec2 describe-regions --profile $p --output json | ConvertFrom-Json).Regions.RegionName
    } else {
        $TargetRegions = $Regions
    }

    $instanceTable = @{}
    foreach ( $region in $TargetRegions ) {
        $reservations= (aws ec2 describe-instances --profile $p --region $region --output json | ConvertFrom-Json).Reservations
        $instanceTable.add($region, $reservations) > $null
    }

    [System.Collections.ArrayList]$customList = @()
    foreach ( $regionKey in $instanceTable.Keys ) {
        foreach ( $reservation in $instanceTable[$regionKey] ) {
            $instances = $reservation.Instances
            foreach ($instance in $instances) {
                $epochTime = [DateTimeOffset]::Now.ToUnixTimeSeconds()
                $startTime = $epochTime - 3600
                if($instance.Platform -eq "windows") {
                    $costs = aws ec2 describe-spot-price-history --profile $p --region $regionKey --start-time $startTime --end-time $epochTime --product-descriptions="Windows (Amazon VPC)" --instance-types $instanceType --output json | ConvertFrom-Json
                } else {
                    $costs = aws ec2 describe-spot-price-history --profile $p --region $regionKey --start-time $startTime --end-time $epochTime --product-descriptions="Linux/UNIX (Amazon VPC)" --instance-types $instanceType --output json | ConvertFrom-Json
                }
                $monthlyCost = [Math]::Round([float]($costs.SpotPriceHistory | Where-Object AvailabilityZone -eq $instances[$i].AvailabilityZone).SpotPrice * 3000, 2)

                $instanceId = $instance.InstanceId
                $instanceTags = $(aws ec2 describe-tags --profile $p --region $regionKey --filters "Name=resource-id,Values=$instanceId" | ConvertFrom-Json).Tags
                if($instanceTags.Key.Contains("Name")) {
                    $nameTag = ($instanceTags | Where-Object Key -eq "Name").Value
                    $instances[$i] | Add-Member -NotePropertyName "NameTag" -NotePropertyValue $nameTag -Force
                    $instances[$i] | Add-Member -NotePropertyName "Identifier" -NotePropertyValue $nameTag -Force
                } else {
                    $instances[$i] | Add-Member -NotePropertyName "NameTag" -NotePropertyValue "Not defined" -Force
                    $instances[$i] | Add-Member -NotePropertyName "Identifier" -NotePropertyValue $instanceId -Force
                }
                if($instanceTags.Key.Contains("ShutdownStrategy")) {
                    $shutdownTag = ($instanceTags | Where-Object Key -eq "ShutdownStrategy").Value
                    $instances[$i] | Add-Member -NotePropertyName "ShutdownStrategy" -NotePropertyValue $shutdownTag -Force
                }

                $instances[$i] | Add-Member -NotePropertyName "InstanceType" -NotePropertyValue $instanceType -Force
                $instances[$i] | Add-Member -NotePropertyName "AMI" -NotePropertyValue $instance.ImageId -Force
                $instances[$i] | Add-Member -NotePropertyName "MonthlyCost" -NotePropertyValue $monthlyCost -Force

                $customList.Add($instances[$i]) > $Null
            }
        }
    }

    $finalTable.add($p, $customList) > $null
}

return $finalTable
# END



