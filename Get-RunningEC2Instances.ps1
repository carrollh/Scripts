# Get-RunningEC2Instances.ps1
#
# Should be configured to run daily in Task Scheduler to alert someone that the incorrect
# number of VMs are running in AWS after COB.
#
# Relies on the AWS CLI, which should be installed and configured to point to our CurrentGen account.
# 
# The following commands were run to create a secure text password file. The password and username
# used are for an account on the smtp server used. There are better ways to do this that don't require
# having a hashed password file somewhere on the system. This is just a proof of concept. 
#
#    $password = "********"
#    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force 
#    $securePassword | ConvertFrom-SecureString | Set-Content "C:\password.txt" 

# $securePasswordFilePath should be created using method above, and 
# the "********" should be the password for the $hancockUser profile 
$hancockUser            = "hcarroll"
$securePasswordFilePath = "C:\password.txt"

# this is the SMTP server needed for the email, I used hancock
$hancockFQDN            = "hancock.sc.steeleye.com"
$toEmailAddress         = "heath.carroll@us.sios.com"

# The iQ team is currently always running 4 VMs, so as long as that many are running we're good
$numberOfPersistentVMs  = 4

# Simple email function. Relies on secure password file described in comment header
function Send-Email() {
    Param(
        [Parameter(Mandatory=$True, Position=0)]
        [string]$username,
        
        [Parameter(Mandatory=$True, Position=1)]
        [string]$smtpServer,
        
        [Parameter(Mandatory=$True, Position=2)]
        [string]$recipientEmail,
        
        [Parameter(Mandatory=$True, Position=3)]
        [string]$message,
        
        [Parameter(Mandatory=$True, Position=4)]
        [string]$subject
    )
    
    # get hashed password from file created as described in header
    $password = Get-Content $securePasswordFilePath | ConvertTo-SecureString
    
    # Alternate password generation technique
    # password = ConvertTo-SecureString "********" -AsPlainText -Force 
    
    $credential = New-Object System.Management.Automation.PSCredential $username,$password
    Send-MailMessage -To $recipientEmail -Subject $subject -Body $message -From ($username+"@"+$smtpServer) -SMTP $smtpServer -Credential $credential
}


# BEGIN
# exit if password file for the smtp server (hancock) doesn't exist
if( -NOT (Test-Path -Path $securePasswordFilePath) ) {
    throw (New-Object System.Exception "PASSWORD FILE DOES NOT EXIST. (Read script header for details.)",$_.Exception)
}

$totalRunningVMsFound = 0
$instanceTable = @{}
$emailMessage = ""

# loop over all regions looking for running instances and build the first part of the message along the way
$regions = aws ec2 describe-regions | ConvertFrom-Json
foreach ( $region in $regions.Regions ) {
    $instances = aws ec2 describe-instance-status --region $region.RegionName --filters "Name=instance-state-code,Values=16" | ConvertFrom-Json
    
    # add running instance data to hashtable using region name as key
    if($instances.InstanceStatuses.Count -gt 0) {
        $instanceTable.add($region.RegionName, ($instances | ConvertTo-Json))
        $totalRunningVMsFound += $instances.InstanceStatuses.Count
    }
    $emailMessage += "Found " + $instances.InstanceStatuses.Count + " running in " + $region.RegionName + ".`n"
}
$emailMessage += "Found a total of " + $totalRunningVMsFound + " VMs running across all " + $regions.Regions.Count + " regions.`n"

# nicely format the instance hash table for viewing in email 
foreach ( $key in $instanceTable.Keys ) { 
    $emailMessage += "REGION: " + $key 
    $emailMessage += $instanceTable[$key] + "`n" 
}

# send an email if an unusual number of VMs are found to be running
if( $totalRunningVMsFound -gt $numberOfPersistentVMs ) {
    $emailSubject           = "HEATH: >4 EC2 INSTANCES ARE RUNNING"
    Send-Email $hancockUser $hancockFQDN $toEmailAddress $emailMessage $emailSubject
} elseif( $totalRunningVMsFound -lt $numberOfPersistentVMs ) {
    $emailSubject           = "HEATH: iQ may have a down production server"
    Send-Email $hancockUser $hancockFQDN $toEmailAddress $emailMessage $emailSubject
} else {
    "Exactly $numberOfPersistentVMs running VMs found. This is correct."
}

return $emailMessage
# END



