#Set-ResourceTags.ps1
# Tags an instance and any/all volumes and snapshots associated with it. Requires creating a hashtable 
# of tags (key-value pairs) to be used as input.
#
# Example use:
#     $instances = @("i-1234567890","i-0987654321")
#     [Hashtable]$ht = @{}
#     $ht.Add("Owner","hcarroll")
#     $ht.Add("Purpose","Case 123456")
#     .\Set-ResourceTags.ps1 -InstanceIds $instances -Tags $ht -Region us-east-1 -Verbose

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False)]
    [string] $Profile = '',

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
    foreach ($key in $Tags.Keys) {
        $tagString = "Key=$key,Value=" + $Tags[$key]

        if($Profile -ne '') {
            aws ec2 create-tags --profile $Profile --region $Region --resources $Resource --tags $tagString
        }
        else {
            aws ec2 create-tags --region $Region --resources $Resource --tags $tagString
        }

        # indicate success or failure if -Verbose flag passed
        if( $? ) {
            Write-Verbose "Successfully set tags ($tagString) on $Resource"
        } else {
            Write-Verbose "Failed to set tags ($tagString) on $Resource with error code $LastExitCode"
        }
    }
}

foreach ($instanceId in $InstanceIds) {
    # tag the instances passed in
    Set-Tags -Resource $instanceId

    # lookup all volumes associated with this instance
    if($Profile -ne '') {
        $volumes = (aws ec2 describe-volumes --profile $Profile --region $Region --filters Name=attachment.instance-id,Values=$instanceId | ConvertFrom-Json).Volumes
    }
    else {
        $volumes = (aws ec2 describe-volumes --region $Region --filters Name=attachment.instance-id,Values=$instanceId | ConvertFrom-Json).Volumes
    }
    
    if ($volumes.Count -lt 1) {
        Write-Verbose ("No volumes attached to $instanceId") 
    }

    foreach ($volume in $volumes) {
        $volumeId = $volume.VolumeId
        # tag the volumes
        Set-Tags -Resource $volumeId

        # lookup all snapshots associated with this volume
        if($Profile -ne '') {
            $snapshots = (aws ec2 describe-snapshots --profile $Profile --region $Region --filters Name=volume-id,Values=$volumeId | ConvertFrom-Json).Snapshots
        }
        else {
            $snapshots = (aws ec2 describe-snapshots --region $Region --filters Name=volume-id,Values=$volumeId | ConvertFrom-Json).Snapshots
        }

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