#Stop-RunningVMs.ps1

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False)]
    [HashTable] $HashTable = $Null,

    [Parameter(Mandatory=$False)]
    [string[]]$Profiles = @("dev","support","qa","ps","ts","currentgen"),

    [Parameter(Mandatory=$False)]
    [string[]] $Regions = $Null
)

if($HashTable -eq $Null) {
    Write-Host "No hashtable passed in, querying EC2..."
    $HashTable = .\Get-RunningEC2Instances.ps1 -Profiles $Profiles -Regions $Regions
}

foreach ( $p in $Profiles ) {
    Write-Host ($p.ToUpper() + " account:")
    $HashTable[$p] | Sort-Object MonthlyCost -Descending | Format-Table AvailabilityZone,Identifier,InstanceType,MonthlyCost,ShutdownStrategy
}