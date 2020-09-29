# Grant-AWSImageAccess.ps1 ############################################################
# Requires the AWS CLI to be installed and in the PATH env variable. Also 
# requires the user running this to have access to the relevant subscription 
# prior to running this. 
#
# Example running this command:
# PS> .\Grant-AWSImageAccess.ps1 -SourceProfile qa -SourceAccountId 705913476943 -Filter SPSL-Jumpbox-Internal -AccountIds @("881352791487","171925695631","377444680806","690117724028","077381238538")
#
################################################################################

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True, Position=0)]
    [string] $SourceProfile = "",

    [Parameter(Mandatory=$True, Position=1)]
    [string] $SourceAccountId = "",

    [Parameter(Mandatory=$False, Position=2)]
    [string] $Filter = "",

    [Parameter(Mandatory=$False, Position=2)]
    [string[]] $Regions = $Null,

    [Parameter(Mandatory=$True, Position=3)]
    [string[]] $AccountIds = $Null
)

if( -Not $Regions -Or $Regions -like "all") {
    $Regions = @("ap-northeast-1","ap-northeast-2","ap-south-1","ap-southeast-1","ap-southeast-2","ca-central-1","eu-central-1","eu-north-1","eu-west-1","eu-west-2","eu-west-3","sa-east-1","us-east-1","us-east-2","us-west-1","us-west-2")
}

foreach ($userId in $AccountIds) {
    foreach ($region in $Regions) {
        $ami = (& "aws" ec2 describe-images --owners $SourceAccountId --query 'reverse(sort_by(Images, &CreationDate))[:1].[CreationDate,Name,ImageId]' --filters "Name=name,Values=$filter" --region $region --output json | ConvertFrom-Json).split("`n")[2]
        & "aws" ec2 modify-image-attribute --region $region --profile $SourceProfile --launch-permission "Add=[{UserId=$userId}]" --image-id $ami
    }
}

