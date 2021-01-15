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
    [Object[]]  $Stacks = $Null,

    [Parameter(Mandatory=$False, Position=1)]
    [string]   $Profile = $Null
)

$i = 0
$Stacks.Keys | %{
    if($Profile) {
        Remove-CFNStack -Region $_ -ProfileName $Profile -StackName $stacks[$i][$_] -Force
    }
    else {
        Remove-CFNStack -Region $_ -StackName $stacks[$i][$_] -Force
    }
    $i++
    Write-Progress -Activity "Removing CFN Stacks" -Status ("Regions Completed: ($i/" + $Stacks.Count + ")") -PercentComplete ($i / $Stacks.Count*100)
}