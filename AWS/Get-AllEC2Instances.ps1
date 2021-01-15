# Get-AllEC2Instances.ps1

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False)]
    [string[]]$profiles = @("dev","support","qa","ps","ts","currentgen","automation"),

    [Parameter(Mandatory=$False)]
    [string[]] $Regions = $Null
)

# BEGIN

# loop over regions looking for instances
$finalTable = @{}
foreach ( $profile in $profilerofiles ) {
    Write-Verbose ("Scanning the " + $profile.ToUpper() + " profile")

    if ($Regions -eq $Null) {
        $TargetRegions = $(aws ec2 describe-regions --profile $profile --region us-east-1 --output json | ConvertFrom-Json).Regions.RegionName
    } else {
        $TargetRegions = $Regions
    }
    Write-Verbose ("Scanning " + $TargetRegions.Count + " regions.")

    $instanceTable = @{}
    foreach ( $region in $TargetRegions ) {
        $reservations = $(aws ec2 describe-instances --profile $profile --region $region --output json | ConvertFrom-Json).Reservations
        $instanceTable.add($region, $reservations) > $Null
    }

    $regionTable = @{}
    foreach ( $regionKey in $instanceTable.Keys ) {
        [System.Collections.ArrayList]$customList = @()
        Write-Verbose "Scanning $regionKey..."
        foreach ( $reservation in $instanceTable[$regionKey] ) {
            $instances = $reservation.Instances
            for ($i=0; $i -lt $instances.Count; $i+=1) {
                $epochTime = [DateTimeOffset]::Now.ToUnixTimeSeconds()
                $startTime = $epochTime - 3600
                if($instances[$i].Platform -eq "windows") {
                    $costs = aws ec2 describe-spot-price-history --profile $profile --region $regionKey --start-time $startTime --end-time $epochTime --product-descriptions="Windows (Amazon VPC)" --instance-types $instanceType --output json | ConvertFrom-Json
                } else {
                    $costs = aws ec2 describe-spot-price-history --profile $profile --region $regionKey --start-time $startTime --end-time $epochTime --product-descriptions="Linux/UNIX (Amazon VPC)" --instance-types $instanceType --output json | ConvertFrom-Json
                }
                $monthlyCost = [Math]::Round([float]($costs.SpotPriceHistory | Where-Object AvailabilityZone -eq $instances[$i].AvailabilityZone).SpotPrice * 3000, 2)

                $instanceId = $instances[$i].InstanceId
                $instanceTags = $(aws ec2 describe-tags --profile $profile --region $regionKey --filters "Name=resource-id,Values=$instanceId" | ConvertFrom-Json).Tags
                if($instanceTags.Count -gt 0) {
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
                    $instances[$i] | Add-Member -NotePropertyName "AMI" -NotePropertyValue $instances[$i].ImageId -Force
                    $instances[$i] | Add-Member -NotePropertyName "MonthlyCost" -NotePropertyValue $monthlyCost -Force
                }
                $customList.Add($instances[$i]) > $Null
            }
        }

        $regionTable.Add($regionKey, $customList) > $Null
        if($customList.Count -gt 0) {
            Write-Verbose ("Found " + $customList.Count + " instances in $regionKey.")
        }
    }

    $finalTable.add($profile, $regionTable) > $Null
}

return $finalTable
# END



