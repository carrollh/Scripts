# Get-RunningEC2Instances.ps1
# Relies on the AWS CLI, which should be installed and configured to point to our CurrentGen account.
# 
# The following commands were run to create a secure text password file. The password and username
# used are for an account on the smtp server used. There are better ways to do this that don't require
# having a hashed password file somewhere on the system. This is just a proof of concept. 
#
#    $password = "********"
#    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force 
#    $securePassword | ConvertFrom-SecureString | Set-Content "C:\password.txt" 
#
# $securePasswordFilePath should be created using method above, and 
# the "********" should be the password for the $hancockUser profile 

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False)]
    [string[]]$Profiles = @("dev","support","qa","ps","ts","currentgen"),

    [Parameter(Mandatory=$False)]
    [string[]] $Regions = $Null
)

$hancockUser            = "hcarroll"
$securePasswordFilePath = "C:\password.txt"

# this is the SMTP server needed for the email, I used hancock
$hancockFQDN            = "hancock.sc.steeleye.com"
$toEmailAddress         = "heath.carroll@us.sios.com"

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

    $message = $message.Replace('`n','<br>')
    $htmlMessage = "<body><font face='consolas'> $message </font> </body>"

    Send-MailMessage -To $recipientEmail -Subject $subject -Body $htmlMessage -From ($username+"@"+$smtpServer) -SMTP $smtpServer -Credential $credential -BodyAsHtml
}


# BEGIN
# exit if password file for the smtp server (hancock) doesn't exist
if( -NOT (Test-Path -Path $securePasswordFilePath) ) {
    throw (New-Object System.Exception "PASSWORD FILE DOES NOT EXIST. (Read script header for details.)",$_.Exception)
}

$emailMessage = ""

# loop over regions looking for running instances and build the first part of the message along the way
$grandTotalRunningVMsFound = 0
$grandTotalVMsFound = 0
$finalTable = @{}
foreach ( $p in $Profiles ) {
    Write-Verbose ("Scanning the " + $p.ToUpper() + " profile")
    $emailMessage += $p.ToUpper() + "`n"

    if ($Regions -eq $Null) {
        $TargetRegions = $(aws ec2 describe-regions --profile $p --output json | ConvertFrom-Json).Regions.RegionName
    } else {
        $TargetRegions = $Regions
    }

    $totalRunningVMsFound = 0
    $totalVMsFound = 0
    $instanceTable = @{}
    foreach ( $region in $TargetRegions ) {
        $runningVMs = aws ec2 describe-instance-status --profile $p --region $region --filters "Name=instance-state-code,Values=16" --output json | ConvertFrom-Json
        $instances = aws ec2 describe-instances --profile $p --region $region --output json | ConvertFrom-Json

        $totalRunningVMsFound += $runningVMs.InstanceStatuses.Count
        $totalVMsFound += $instances.Reservations.Count

        $message = "Found " + $runningVMs.InstanceStatuses.Count + "/" + $instances.Reservations.Count + " running in " + $region + ".`n"
        $emailMessage += $message
        Write-Verbose $message

        $instanceTable.add($region, $runningVMs) > $null
    }

    [System.Collections.ArrayList]$customList = @()
    foreach ( $regionKey in $instanceTable.Keys ) {
        $instances = $instanceTable[$regionKey].InstanceStatuses

        for ( $i=0; $i -lt $instances.Length; $i+=1 ) {
            $instanceId = $instances[$i].InstanceId
            $instance = aws ec2 describe-instances --profile $p --region $regionKey --instance-id $instanceId | ConvertFrom-Json
            $instanceType = $instance.Reservations.Instances.InstanceType
            $instanceAMI = $instance.Reservations.Instances.ImageId
            $imageDescription = $(aws ec2 describe-images --profile currentgen --region ca-central-1 --filters "Name=image-id,Values=ami-042dc48bab9e693f9" --output json | ConvertFrom-Json).Images.Description

            $epochTime = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            $startTime = $epochTime - 3600
            if($instance.Reservations.Instances.Platform -eq "windows") {
                $costs = aws ec2 describe-spot-price-history --profile $p --region $regionKey --start-time $startTime --end-time $epochTime --product-descriptions="Windows (Amazon VPC)" --instance-types $instanceType --output json | ConvertFrom-Json
            } else {
                $costs = aws ec2 describe-spot-price-history --profile $p --region $regionKey --start-time $startTime --end-time $epochTime --product-descriptions="Linux/UNIX (Amazon VPC)" --instance-types $instanceType --output json | ConvertFrom-Json
            }
            $monthlyCost = [Math]::Round([float]($costs.SpotPriceHistory | Where-Object AvailabilityZone -eq $instances[$i].AvailabilityZone).SpotPrice * 3000, 2)

            $instanceTags = $(aws ec2 describe-tags --profile $p --region $regionKey --filters "Name=resource-id,Values=$instanceId" | ConvertFrom-Json).Tags
            if($instanceTags.Key.Contains("Name")) {
                $nameTag = ($instanceTags | Where-Object Key -eq "Name").Value
                $instances[$i] | Add-Member -NotePropertyName "NameTag" -NotePropertyValue $nameTag -Force
                $instances[$i] | Add-Member -NotePropertyName "Identifier" -NotePropertyValue $nameTag -Force
            } else {
                $instances[$i] | Add-Member -NotePropertyName "NameTag" -NotePropertyValue "Not defined" -Force
                $instances[$i] | Add-Member -NotePropertyName "Identifier" -NotePropertyValue $instanceId -Force
            }
            if($instanceTags.Key.Contains("ShutdownStrategy")) {
                $shutdownTag = ($instanceTags | Where-Object Key -eq "ShutdownStrategy").Value
                $instances[$i] | Add-Member -NotePropertyName "ShutdownStrategy" -NotePropertyValue $shutdownTag -Force
            }

            $instances[$i] | Add-Member -NotePropertyName "InstanceType" -NotePropertyValue $instanceType -Force
            $instances[$i] | Add-Member -NotePropertyName "AMI" -NotePropertyValue $instanceAMI -Force
            $instances[$i] | Add-Member -NotePropertyName "MonthlyCost" -NotePropertyValue $monthlyCost -Force

            $customList.Add($instances[$i]) > $Null
        }
    }

    $message = "Found a total of " + $totalRunningVMsFound + "(out of " + $totalVMsFound + ") VMs running across all " + $TargetRegions.Count + " regions in the " + $p.ToUpper() + " account.`n"
    $emailMessage += $message
    Write-Verbose $message
    #$message = $customList | Sort-Object MonthlyCost -Descending | Format-Table AvailabilityZone,Identifier,InstanceType,MonthlyCost,ShutdownStrategy | Out-String
    $message = $customList | Format-Table AvailabilityZone,Identifier,InstanceType,MonthlyCost,ShutdownStrategy | Out-String
    $emailMessage += $message
    $finalTable.add($p, $customList) > $null

    $grandTotalRunningVMsFound += $totalRunningVMsFound
    $grandTotalVMsFound += $totalVMsFound

    $emailMessage += "`n"
}

# send an email
$emailSubject = "$grandTotalRunningVMsFound/$grandTotalVMsFound EC2 INSTANCES ARE RUNNING"
Send-Email $hancockUser $hancockFQDN $toEmailAddress $emailMessage $emailSubject

if(-Not $?) {
    Write-Host "Email failed to send with error $LastExitCode"
    return $Null
}
return $finalTable
# END



