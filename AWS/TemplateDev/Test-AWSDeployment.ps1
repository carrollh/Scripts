# Test-AWSDeployment.ps1
# 
# Example call: 
#   .\Test-AWSDeployment.ps1 -Profile qa -Branch develop -Linux -Verbose
#
# Notes:
#   There aren't any /ci/payg-*.json files in this repo as AWS can't/doesn't test them, so 
#   you'll need to provide a local path to a parameters file. You can use '.\' for ParameterFilePath,
#   and it will grab the included sios-datakeeper-master-parameters.json file. The second example 
#   above works with that file.

[CmdletBinding()]
Param(
    [string[]] $Regions = $Null,
    [string]   $Branch = "",
    [string]   $Profile = "",
    [string[]] $OSVersions = $Null,
    [Switch]   $Windows,
    [Switch]   $Linux
)

if ($Branch -ne "") {
    $TemplateURLBase += "/$Branch"
} else {
    $TemplateURLBase += "/test"
}

if (-Not $Regions -Or $Regions -like "all") {
    $Regions = @("ap-northeast-1","ap-northeast-2","ap-south-1","ap-southeast-1","ap-southeast-2","ca-central-1","eu-central-1","eu-north-1","eu-west-1","eu-west-2","eu-west-3","sa-east-1","us-east-1","us-east-2","us-west-1","us-west-2")
}

if(-Not $OSVersions) {
    $OSVersions = [System.Collections.ArrayList]@()
    if($Windows) {
        $OSVersions.Add("WS2012") > $Null
        $OSVersions.Add("WS2012R2") > $Null
        $OSVersions.Add("WS2016") > $Null
        $OSVersions.Add("WS2019") > $Null
    }
    if($Linux) {
        $OSVersions.Add("SLES12SP1") > $Null
        $OSVersions.Add("SLES12SP2") > $Null
        $OSVersions.Add("SLES12SP3") > $Null
        $OSVersions.Add("SLES12SP4") > $Null
        $OSVersions.Add("SLES12SP5") > $Null
        $OSVersions.Add("SLES15") > $Null
        $OSVersions.Add("SLES15SP1") > $Null
        $OSVersions.Add("RHEL74") > $Null
        $OSVersions.Add("RHEL75") > $Null
        $OSVersions.Add("RHEL76") > $Null
        $OSVersions.Add("RHEL77") > $Null
        $OSVersions.Add("RHEL78") > $Null
        $OSVersions.Add("RHEL80") > $Null
        $OSVersions.Add("RHEL81") > $Null
        $OSVersions.Add("RHEL82") > $Null
    }
}

$i = 0
$masterStacks = [ordered]@{}
foreach ($region in $Regions) {
    $i %= $Regions.Count
    if($OSVersions[$i] -like "WS*") {
        if($Profile) {
            $masterStacks.Add($region,(C:\GitHub\quickstart-sios-qa\New-AWSDeployment.ps1 -OSVersion $OSVersions[$i] -DKVersion latestbuild -Verbose -ProfileName $Profile -Region $region -Branch $Branch))
        } else {
            $masterStacks.Add($region,(C:\GitHub\quickstart-sios-qa\New-AWSDeployment.ps1 -OSVersion $OSVersions[$i] -DKVersion latestbuild -Verbose -Region $region -Branch $Branch))
        }
    } else {
        if($Profile) {
            $masterStacks.Add($region,(C:\GitHub\quickstart-sios-qa\New-AWSDeployment.ps1 -OSVersion $OSVersions[$i] -SPSLVersion latestbuild -Verbose -ProfileName $Profile -Region $region -Branch $Branch))
        } else {
            $masterStacks.Add($region,(C:\GitHub\quickstart-sios-qa\New-AWSDeployment.ps1 -OSVersion $OSVersions[$i] -SPSLVersion latestbuild -Verbose -Region $region -Branch $Branch))
        }
    }
    $i += 1
}
return $masterStacks