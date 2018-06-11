
function InitializeNetwork() {
	Param(
		[Parameter(Mandatory=$True, Position=1)]
		[string]$vmname,
		
		[Parameter(Mandatory=$True, Position=2)]
		[string]$IPAddress,

		[Parameter(Mandatory=$True, Position=3)]
		[string]$NetMask,
		
		[Parameter(Mandatory=$True, Position=4)]
		[string]$DNSServer
		
	)
	
	#fail if not running as administrator
	if( -Not (CheckIfAdmin) ) {
		Write-Warning "This cmdlet must be run as administrator."
		return $False
	}
	
	$NetworkAdapter = Get-VMNetworkAdapter $vmname
	
	$VM = Get-WmiObject -Namespace 'root\virtualization\v2' -Class 'Msvm_ComputerSystem' | Where-Object { $_.ElementName -eq $NetworkAdapter.VMName } 
	$VMSettings = $VM.GetRelated('Msvm_VirtualSystemSettingData') | Where-Object { $_.VirtualSystemType -eq 'Microsoft:Hyper-V:System:Realized' }    
	$VMNetAdapters = $VMSettings.GetRelated('Msvm_SyntheticEthernetPortSettingData') 

	$NetworkSettings = @()
	foreach ($NetAdapter in $VMNetAdapters) {
		if ($NetAdapter.Address -eq $NetworkAdapter.MacAddress) {
			$NetworkSettings = $NetworkSettings + $NetAdapter.GetRelated("Msvm_GuestNetworkAdapterConfiguration")
		}
	}

	$NetworkSettings[0].IPAddresses = $IPAddress
	$NetworkSettings[0].DNSServers = $DNSServer
	$NetworkSettings[0].ProtocolIFType = 4096
	$NetworkSettings[0].Subnets = $NetMask
	$NetworkSettings[0].DHCPEnabled = $false

	$Service = Get-WmiObject -Class "Msvm_VirtualSystemManagementService" -Namespace "root\virtualization\v2"
    $SetIP = $Service.SetGuestNetworkAdapterConfiguration($VM, $NetworkSettings[0].GetText(1))
 
    if ($SetIP.ReturnValue -eq 4096) {
        $job=[WMI]$setip.job 
 
        while ($job.JobState -eq 3 -or $job.JobState -eq 4) {
            Start-Sleep 1
            $job=[WMI]$SetIP.job
        }
 
        if ($job.JobState -eq 7) {
            Write-Verbose "Guest OS Network Adapter Configured"
        }
        else {
            $job.GetError()
        }
    } elseif($SetIP.ReturnValue -eq 0) {
        Write-Verbose "Success"
    }
}

function JoinDomain() {
	Param(
		[Parameter(Mandatory=$True)]
		[string]$Server,

		[Parameter(Mandatory=$True)]
		[string]$Domain,

		[Parameter(Mandatory=$True)]
		[PSCredential]$DomainCred
	)

	Invoke-Command -ComputerName $Server -Credential $DomainCred { Add-Computer -DomainName $Domain -Credential $DomainCred }
}

function GetGuestOSComputerName() {
	Param(
		[Parameter(Mandatory=$True, Position=1)]
		[string]$IPAddress
	)

	return ([system.net.dns]::GetHostByAddress($IPAddress)).HostName
}

# TODO: Start here when coming back
function RenameVMComputerName() {
	Param(
		[Parameter(Mandatory=$True)]
		[string]$VMName
	)

	$VM = Get-WmiObject -Namespace 'root\virtualization\v2' -Class 'Msvm_ComputerSystem' | Where-Object { $_.ElementName -eq $VMName } 
	$GuestExchangeItemXml = ([XML]$VM).GetRelated('Msvm_KvpExchangeComponent').GuestIntrinsicExchangeItems.SelectSingleNode("/INSTANCE/PROPERTY[@NAME='Name']/VALUE[child::text()='FullyQualifiedDomainName']")
	if ($GuestExchangeItemXml -ne $null) 
    {
            $vmName = $GuestExchangeItemXml.SelectSingleNode("/INSTANCE/PROPERTY[@NAME='Data']/VALUE/child::text()").Value -replace '\W','_'
            $vmName = $vmName.Substring(0,[System.Math]::Min(15,$vmName.Length))

            #(Get-WmiObject Win32_Computersystem -ComputerName $oldName).Rename($VMName); shutdown -r -t 0 
            #Rename-Computer -ComputerName $oldName -NewName $VMName -Restart -Force -WhatIf 
			$vmName
	}
}

function InstallWSFC() {

}

function InitializeOS() {
	Param(
		[Parameter(Mandatory=$True, Posistion=1)]
		[string]$VMName,
		
		[Parameter(Mandatory=$True, Position=2)]
		[string]$IPAddress,
		
		[Parameter(Mandatory=$True, Position=3)]
		[string]$NetMask,

		[Parameter(Mandatory=$True, Position=4)]
		[string]$DNSServer
	)
	
	Write-Verbose("Verifying prerequisites...")
	
	InitializeNetwork $VMName $IPAddress $NetMask $DNSServer 

	$localCred = Get-Credentials
	
	
	$domainCred = Get-Credentials
	JoinDomain $ServerName $Domain $domainCred

	RenameComputer $VMName $localCred
	ChangeTimeZone $localCred
}

function WriteSecurePassword() {
	$password = "********"
	$securePassword = ConvertTo-SecureString $password -AsPlainText -Force 
	$securePassword | ConvertFrom-SecureString | Set-Content ".\password.txt" 
}

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
	$password = Get-Content ".\password.txt" | ConvertTo-SecureString
	$credential = New-Object System.Management.Automation.PSCredential $username,$password
	Send-MailMessage -To $recipientEmail -Subject $subject -Body $message -From ($username+"@"+$smtpServer) -SMTP $smtpServer -Credential $credential
}

