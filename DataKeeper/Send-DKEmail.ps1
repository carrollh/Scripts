# The following commands were run to create a secure text password file. The password and username
# used are for an account on the smtp server used. There are better ways to do this that don't require
# having a hashed password file somewhere on the system. This is just a proof of concept. 
#
#	$password = "********"
#	$securePassword = ConvertTo-SecureString $password -AsPlainText -Force 
#	$securePassword | ConvertFrom-SecureString | Set-Content "C:\password.txt" 

function Send-DKEmail() {
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
	$password = Get-Content "C:\password.txt" | ConvertTo-SecureString
	$credential = New-Object System.Management.Automation.PSCredential $username,$password
	Send-MailMessage -To $recipientEmail -Subject $subject -Body $message -From ($username+"@"+$smtpServer) -SMTP $smtpServer -Credential $credential
}

Send-DKEmail "hcarroll" "hancock.sc.steeleye.com" "heath.carroll@us.sios.com" "Secured Password Email Test" "Test Email"