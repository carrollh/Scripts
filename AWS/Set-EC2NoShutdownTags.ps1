# Set-EC2NoShutdownTags.ps1
# Tags any running instances in a given region with the appropriate tags to prevent shutdown by the sios automated shutdown scripts
#
# Example use: 
#    Set-EC2NoShutdownTags.ps1 -Profile dev -Region ap-northeast-1 -Verbose

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False)]
    [string] $Profile = '',

    [Parameter(Mandatory=$True)]
    [string] $Region,

    [Parameter(Mandatory=$False)]
    [Switch] $DryRun = $False
)

function Set-Tags() {
    Param(
        [Parameter(Mandatory=$True)]
        [string] $Resource
    )

    Write-Verbose "Setting tags on $Resource"

    # format the tags passed in as needed for the aws command
    foreach ($key in $Tags.Keys) {
        $tagString = "Key=$key,Value=" + $Tags[$key]

        if($Profile -ne '') {
            aws ec2 create-tags --profile $Profile --region $Region --resources $Resource --tags $tagString
        }
        else {
            aws ec2 create-tags --region $Region --resources $Resource --tags $tagString
        }

        if(-Not $DryRun) {
            # indicate success or failure if -Verbose flag passed
            if( $? ) {
                Write-Verbose "Successfully set tags ($tagString) on $Resource"
            } else {
                Write-Verbose "Failed to set tags ($tagString) on $Resource with error code $LastExitCode"
            }
        }
    }
}

$tags = @{};
$tags.Add("ShutdownStrategy","NoShutdown")

# only grab running instances (state-code = 16)
if($Profile -ne '') {
    $instances = (aws ec2 describe-instances --region $Region --profile $Profile --output json --filter "Name=instance-state-code,Values=16"|Convertfrom-json).Reservations.Instances
}
else {
    $instances = (aws ec2 describe-instances --region $Region --output json --filter "Name=instance-state-code,Values=16"|Convertfrom-json).Reservations.Instances
}

foreach ($instance in $instances) {
    # tag the instances passed in
    Set-Tags -Resource ($instance.InstanceId)
}