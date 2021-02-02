# Get-IAMRoles.ps1
#
# Example 1:
# .\Get-IAMRoles.ps1 -Kit route53
#
# Example 2:
# $missingRoles = .\Get-IAMRoles.ps1 -Kit route53
#

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False)]
    [String] $Kit = '',

    [Parameter(Mandatory=$False)]
    [String] $Extra = ''
)

$LKBIN="$env:LKROOT\Bin"

# set log redirect location
$log = $Null
if($env:VERBOSE_AWS_ROLE_CHECK.Count -gt 1) {
    $log = $env:VERBOSE_AWS_ROLE_CHECK
    Start-Transcript -Path $log
}

function Test-Route53() {
    Param(
        [Parameter(Mandatory=$False)]
        [string] $Zone = ''
    )

    $zones = (&"aws" route53 list-hosted-zones --output json | ConvertFrom-Json).HostedZones
    if($LastExitCode -ne 0) {
        $roleerr = 'route53:ListHostedZones'
        Write-Host $roleerr
    }
    
    $message = "One or more of the following IAM policy actions are not allowed for the current profile or instance roles:\nroute53:GetChange\nroute53:ListHostedZones\nroute53:ChangeResourceRecordSets\nroute53:ListResourceRecordSets.\nAll four are required for proper Route53 resource operation."
    &"$LKBIN\lk_err" -c FRS_ERR -n 99999 -d TO_STDERR -p $PSScriptRoot $message > $Null
}



# MAIN
Get-Command -Name "aws" 2>&1 > $Null
if(-Not $?) {
    Write-Host "The `"aws`" command was not found.`nPlease install the AWS-CLIv2 utility."
    Exit 1
}

if($Kit -eq '') {
    Write-Host "Unknown service"
    Exit 1
}

Switch($Kit) {
    "route53" { Test-Route53 -Zone $Extra }
}

if($log -ne $Null) {
    Stop-Transcript -Path $log
}
# END
