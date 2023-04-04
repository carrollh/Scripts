[CmdletBinding()]
param(
    [Parameter(Mandatory=$True)]
    [string] $Profile = ""
)

$users = (aws iam list-users --profile $Profile --output json | ConvertFrom-Json).Users
Foreach ($user in $users) {
    $username = $user.UserName
    if(-Not ($username -like "heath*")) {
        $accesskeys = (aws iam list-access-keys --profile $Profile --user-name $username | ConvertFrom-Json).AccessKeyMetadata.AccessKeyId
        Foreach ($key in $accesskeys) {
            if(-Not ($key -like "")) {
                Write-Verbose "disabling $key ($username)"
                aws iam update-access-key --profile $Profile --access-key-id $key --status Inactive --user-name $username
            }
        }
    }
}