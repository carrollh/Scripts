# Test-AWSDKCE.ps1
# 
# Example call: 
#   .\Test-AWSDKCE.ps1 -SIOSLicenseKeyFtpURL http://ftp.us.sios.com/pickup/EVAL_H_Carroll_hcarroll_2020-04-02_DKCE/ -Branch develop -Profile dev
#
# Notes:
#   There aren't any /ci/payg-*.json files in this repo as AWS can't/doesn't test them, so 
#   you'll need to provide a local path to a parameters file. You can use '.\' for ParameterFilePath,
#   and it will grab the included sios-datakeeper-master-parameters.json file. The second example 
#   above works with that file.

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [string]   $SIOSLicenseKeyFtpURL,

    [Parameter(Mandatory=$False)]
    [string]   $Branch = "develop",

    [Parameter(Mandatory=$True)]
    [ValidateSet("currentgen","dev","qa")]
    [string]   $Profile = "dev"
)

$masterStacks = [ordered]@{}

$masterStacks.Add("ap-northeast-2",(.\Test-AWSDKCETemplate.ps1 -Stackname HAC-DK-2012R2-SQL-PAYG -OSVersion WS2012R2 -SQLServerVersion 2014SP1 -AMIType PAYG -Region ap-northeast-2 -Branch develop -Profile $Profile -Verbose))
$masterStacks.Add("ap-south-1",(.\Test-AWSDKCETemplate.ps1 -Stackname HAC-DK-2012R2-SQL-BYOL -OSVersion WS2012R2 -SQLServerVersion 2014SP1 -AMIType BYOL -SIOSLicenseKeyFtpURL $SIOSLicenseKeyFtpURL -Region ap-south-1 -Branch develop -Profile $Profile -Verbose))
$masterStacks.Add("ap-southeast-1",(.\Test-AWSDKCETemplate.ps1 -Stackname HAC-DK-2012R2-NoSQL-PAYG -OSVersion WS2012R2 -SQLServerVersion None -AMIType PAYG -Region ap-southeast-1 -Branch develop -Profile $Profile -Verbose))
$masterStacks.Add("ap-southeast-2",(.\Test-AWSDKCETemplate.ps1 -Stackname HAC-DK-2012R2-NoSQL-BYOL -OSVersion WS2012R2 -SQLServerVersion None -AMIType BYOL -SIOSLicenseKeyFtpURL $SIOSLicenseKeyFtpURL -Region ap-southeast-2 -Branch develop -Profile $Profile -Verbose))

$masterStacks.Add("ca-central-1",(.\Test-AWSDKCETemplate.ps1 -Stackname HAC-DK-2016-SQL-PAYG -OSVersion WS2016 -SQLServerVersion 2014SP1 -AMIType PAYG -Region ca-central-1 -Branch develop -Profile $Profile -Verbose))
$masterStacks.Add("eu-central-1",(.\Test-AWSDKCETemplate.ps1 -Stackname HAC-DK-2016-SQL-BYOL -OSVersion WS2016 -SQLServerVersion 2014SP1 -AMIType BYOL -SIOSLicenseKeyFtpURL $SIOSLicenseKeyFtpURL -Region eu-central-1 -Branch develop -Profile $Profile -Verbose))
$masterStacks.Add("us-east-2",(.\Test-AWSDKCETemplate.ps1 -Stackname HAC-DK-2016-NoSQL-PAYG -OSVersion WS2016 -SQLServerVersion None -AMIType PAYG -Region us-east-2 -Branch develop -Profile $Profile -Verbose))
$masterStacks.Add("eu-west-1",(.\Test-AWSDKCETemplate.ps1 -Stackname HAC-DK-2016-NoSQL-BYOL -OSVersion WS2016 -SQLServerVersion None -AMIType BYOL -SIOSLicenseKeyFtpURL $SIOSLicenseKeyFtpURL -Region eu-west-1 -Branch develop -Profile $Profile -Verbose))

$masterStacks.Add("eu-west-2",(.\Test-AWSDKCETemplate.ps1 -Stackname HAC-DK-2019-SQL-PAYG -OSVersion WS2019 -SQLServerVersion 2014SP1 -AMIType PAYG -Region eu-west-2 -Branch develop -Profile $Profile -Verbose))
$masterStacks.Add("eu-west-3",(.\Test-AWSDKCETemplate.ps1 -Stackname HAC-DK-2019-SQL-BYOL -OSVersion WS2019 -SQLServerVersion 2014SP1 -AMIType BYOL -SIOSLicenseKeyFtpURL $SIOSLicenseKeyFtpURL -Region eu-west-3 -Branch develop -Profile $Profile -Verbose))
$masterStacks.Add("sa-east-1",(.\Test-AWSDKCETemplate.ps1 -Stackname HAC-DK-2019-NoSQL-PAYG -OSVersion WS2019 -SQLServerVersion None -AMIType PAYG -Region sa-east-1 -Branch develop -Profile $Profile -Verbose))
$masterStacks.Add("us-east-1",(.\Test-AWSDKCETemplate.ps1 -Stackname HAC-DK-2019-NoSQL-BYOL -OSVersion WS2019 -SQLServerVersion None -AMIType BYOL -SIOSLicenseKeyFtpURL $SIOSLicenseKeyFtpURL -Region us-east-1 -Branch develop -Profile $Profile -Verbose))

return $masterStacks