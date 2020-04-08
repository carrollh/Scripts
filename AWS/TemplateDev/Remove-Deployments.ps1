# Remove-Deployments.ps1
# 
# Example usage:
#   PS> $stacks = .\Test-AWSS4HTemplate.ps1 -Regions $regions -Branch test -StackName HAC-S4H -Profile currentgen -Verbose
#   PS> .\Remove-Deployments -Stacks $stacks -Profile currentgen
#   PS> $stacks | .\Remove-Deployments -Profile currentgen
#

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True, ValueFromPipeline, Position=0)]
    [System.Collections.HashTable]  $Stacks = $Null,

    [Parameter(Mandatory=$False, Position=1)]
    [string]   $Profile = $Null
)

$i = 0
$Stacks.Keys | %{
    $i += 1
    if($Profile) {
        Remove-CFNStack -Region $_ -ProfileName $Profile -StackName $Stacks[$_] -Force 
    }
    else {
        Remove-CFNStack -Region $_ -StackName $Stacks[$_] -Force
    }

    Write-Progress -Activity "Removing CFN Stacks" -Status ("Regions Completed: ($i/" + $Stacks.Keys.Count + ")") -PercentComplete ($i / $Stacks.Keys.Count*100)
}