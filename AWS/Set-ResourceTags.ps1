#Set-ResourceTags.ps1
# Tags an instance and any/all volumes and snapshots associated with it. Requires creating a hashtable 
# of tags (key-value pairs) to be used as input.
#
# Example use:
#     [Hashtable]$ht = @{}
#     $ht.Add("Owner","hcarroll")
#     $ht.Add("Purpose","Testing")
#     .\Set-ResourceTags.ps1 -InstanceIds i-00cdea02749c1150a -Tags $ht -Region us-east-1 -Profile currentgen -Verbose

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False)]
    [string] $Profile = $Null,

    [Parameter(Mandatory=$True)]
    [string] $Region,

    [Parameter(Mandatory=$True)]
    [string[]] $InstanceIds = $Null,

    [Parameter(Mandatory=$True)]
    [HashTable] $Tags = $Null
)

function Set-Tags() {
    Param(
        [Parameter(Mandatory=$True)]
        [string] $Resource
    )

    Write-Verbose "Setting tags on $Resource"

    # format the tags passed in as needed for the aws command
    $tagString  = ""
    foreach ($key in $Tags.Keys) {
        $tagString += "Key=$key,Value=" + $Tags[$key] + " "
    }
    aws ec2 create-tags --profile $Profile --region $Region --resources $Resource --tags $tagString

    # indicate success or failure if -Verbose flag passed
    if( $? ) {
        Write-Verbose "Successfully set tags ($tagString) on $Resource"
    } else {
        Write-Verbose "Failed to set tags ($tagString) on $Resource with error code $LastExitCode"
    }
}

foreach ($instanceId in $InstanceIds) {
    # tag the instances passed in
    Set-Tags -Resource $instanceId

    # lookup all volumes associated with this instance
    $volumes = (aws ec2 describe-volumes --profile $Profile --region $Region --filters Name=attachment.instance-id,Values=$instanceId | ConvertFrom-Json).Volumes
    if ($volumes.Count -lt 1) {
        Write-Verbose ("No volumes attached to $instanceId") 
    }

    foreach ($volume in $volumes) {
        $volumeId = $volume.VolumeId
        # tag the volumes
        Set-Tags -Resource $volumeId

        # lookup all snapshots associated with this volume
        $snapshots = (aws ec2 describe-snapshots --profile $Profile --region $Region --filters Name=volume-id,Values=$volumeId | ConvertFrom-Json).Snapshots

        if ($snapshots.Count -lt 1) {
            Write-Verbose "No snapshots associated with $volumeId"
        }

        foreach ($snapshot in $snapshots) {
            $snapshotId = $snapshot.SnapshotId
            # tag the snapshots that exist
            Set-Tags -Resource $snapshotId
        }
    }
}