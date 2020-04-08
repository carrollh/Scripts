# Get-DeploymentStatus.ps1
# 
# Example usage:
#   PS> $stacks = .\Test-AWSS4HTemplate.ps1 -Regions $regions -Branch test -StackName HAC-S4H -Profile currentgen -Verbose
#   PS> .\Get-DeploymentStatus -Stacks $stacks -Profile currentgen
#   PS> $stacks | .\Get-DeploymentStatus -Profile currentgen
#

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True, ValueFromPipeline, Position=0)]
    [System.Collections.HashTable]  $Stacks = $Null,

    [Parameter(Mandatory=$False, Position=1)]
    [string]   $Profile = $Null
)

$results = [System.Collections.HashTable]@{}
$i = 0
foreach ($region in $Stacks.Keys) {
    $i += 1
    $result = [System.Collections.ArrayList]@()

    if($Profile) {
        $rootStack = Get-CFNStack -Region $region -StackName $Stacks[$region] -ProfileName $Profile
        $result.Add($rootStack) > $Null
        Get-CFNStack -Region $region -ProfileName $Profile | Where ParentId -like $Stacks[$region] | %{
            $result.Add($_) > $Null
        }
    }
    else {
        $rootStack = Get-CFNStack -Region $region -StackName $Stacks[$region]
        $result.Add($rootStack) > $Null
        Get-CFNStack -Region $region | Where ParentId -like $Stacks[$region] | %{
            $result.Add($_) > $Null
        }
    }

    $results.Add($region, $result)
    Write-Progress -Activity "Querying AWS" -Status ("Regions Completed: ($i/" + $Stacks.Keys.Count + ")") -PercentComplete ($i / $Stacks.Keys.Count*100)
}

$results.Keys | %{
    Write-Host $_ 
    $results[$_] | Format-Table | Out-Host
}
