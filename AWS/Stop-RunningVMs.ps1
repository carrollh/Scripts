#Stop-RunningVMs.ps1

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False)]
    [HashTable] $HashTable = $Null,

    [Parameter(Mandatory=$False)]
    [string[]]$Profiles = $Null,

    [Parameter(Mandatory=$False)]
    [string[]] $Regions = $Null
)

if($HashTable -eq $Null) {
    Write-Host "No hashtable passed in, querying EC2..."
    $HashTable = .\Get-RunningEC2Instances.ps1 -Profiles $Profiles -Regions $Regions
} else {
    if($Profiles -eq $Null) {
        $Profiles = $HashTable.Keys
    }
}

foreach ( $p in $Profiles ) {
    Write-Host ($p.ToUpper() + " account:")
    #$HashTable[$p] | Sort-Object MonthlyCost -Descending | Format-Table AvailabilityZone,Identifier,InstanceType,MonthlyCost,ShutdownStrategy
    foreach ( $instance in $HashTable[$p] ) {
        if(-Not $instance.ShutdownStrategy) { 
            Write-Verbose ("Shutting down " + $instance.Identifier)
            $region = $instance.AvailabilityZone.Substring(0, $instance.AvailabilityZone.Length-1)
            Write-Verbose ("Calling: aws ec2 stop-instances --instance-id " + $instance.InstanceId + " --profile $p --region $region")
            aws ec2 stop-instances --instance-id $instance.InstanceId --profile $p --region $region
        } else {
            Write-Verbose ("SKIPPING " + $instance.Identifier)
        }
    }
}