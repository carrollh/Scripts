# New-SPSLResourceIIS.ps1
#
# Example: .\New-SPSLResourceIIS.ps1 -Nodes WSFCNode1,WSFCNode2 -CommPath1IPs '10.0.0.100','10.0.32.100' -CommPath2IPs '10.0.0.100','10.0.32.100' -VIP '10.1.0.100' -VIPNetMask '255.255.255.0' -LogFile 'C:\Users\siosadmin\Desktop\log.txt' -MACs 02-02-97-46-C8-70,06-85-D9-81-2C-84
#
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [String[]] $Nodes = @(),

    [Parameter(Mandatory=$True)]
    [String[]] $CommPath1IPs = @(),

    [Parameter(Mandatory=$True)]
    [String[]] $CommPath2IPs = @(),

    [Parameter(Mandatory=$True)]
    [String] $VIP = '',

    [Parameter(Mandatory=$True)]
    [String] $VIPNetMask = '',

    [Parameter(Mandatory=$True)]
    [String[]] $MACs = @(),

    [Parameter(Mandatory=$False)]
    [String] $LogFile = $Null
)

function Get-ScriptDetails {

    $CommandName = $PSCmdlet.MyInvocation.InvocationName
    Write-Host "Executing $CommandName"
    
    $ParameterList = (Get-Command -Name $CommandName).Parameters
    Write-Host "Parameters passed: "
    
    foreach ($parameter in $ParameterList) {
        Get-Variable -Name $parameter.Values.Name -ErrorAction SilentlyContinue | Format-Table -Property Name,Value
    }
}

function SIOS-Error {
    Param(
        [Parameter(Mandatory=$True)]
        [Object] $Error
    )
    
    foreach ($err in $Error) {
        $err
        Write-Error $err
    }
}

function SIOS-Command {
    Param(
        [Parameter(Mandatory=$True)]
        [String] $Node,

        [Parameter(Mandatory=$True)]
        [String] $Command
    )
    
    $outVar = ''
    $errVar = ''
    $retCode = 0

    Write-Host "Running `'$Command`' on $Node"
    $retVar = Invoke-Command -ComputerName $Node -ScriptBlock { $Command } -OutVariable outVar -ErrorVariable errVar
    $retCode = $LastExitCode

    if(-Not ($outVar -like '')) {
        $outVar
    }
    if(-Not ($errVar -like '')) {
        SIOS-Error $errVar
    }
    if($retCode -eq 0) {
        return $retVar
    }

    return $retCode
}

if(-Not ($LogFile -like '')) {
    Start-Transcript -Path $LogFile
    Get-Date
    Get-ScriptDetails
}

### Parameter Validation ###
$ErrorActionPreference = 'Continue'

$paramError = $False
if($env:LKBIN -like '') {
    SIOS-Error "LifeKeeper is not installed, or user does not have permission to use it."
    $paramError = $True
}

if($Nodes.Count -ne 2) {
    SIOS-Error "USAGE: This script only supports exactly 2 nodes."
    $paramError = $True
}

if($Nodes[0] -like $Nodes[1]) {
    SIOS-Error "USAGE: Must specify two separate nodes."
    $paramError = $True
}

$localhost = hostname
if($Nodes[0] -like '.') {
    $Nodes[0] = hostname
}
if($Nodes[1] -like '.') {
    $Nodes[1] = hostname
}
if(-Not ($Nodes[0] -like $localhost)) {
    if(-Not ($Nodes[1] -like $localhost)) {
        Write-Warning "The local system was not included in the -Nodes parameter. Break now (ctrl-C), or press enter to continue..."
        Read-Host
    }
}

$node1 = $Nodes[0].ToUpper()
$node2 = $Nodes[1].ToUpper()

Try {
    $lksvc = Invoke-Command -ComputerName $node1 -ScriptBlock { Get-Service 'LifeKeeper' }
    if($LastExitCode -ne 0) {
        SIOS-Error "The LifeKeeper service was not found on $node1."
        $paramError = $True
    }
    else {
        if(-Not ($lksvc.Status -like 'Running')) {
            SIOS-Error "The LifeKeeper service is not running on $node2."
            $paramError = $True
        }
    }
}
Catch [System.Management.Automation.RuntimeException] { #PSRemotingTransportException
    SIOS-Error "PSRemoting must be enabled to use this script. Please run 'winrm quickconfig' on $node1, and retry."
    $paramError = $True
}

Try {
    $lksvc = Invoke-Command -ComputerName $node2 -ScriptBlock { Get-Service 'LifeKeeper' }
    if($LastExitCode -ne 0) {
        SIOS-Error "The LifeKeeper service was not found on $node2."
        $paramError = $True
    }
    else {
        if(-Not ($lksvc.Status -like 'Running')) {
            SIOS-Error "The LifeKeeper service is not running on $node2."
            $paramError = $True
        }
    }
}
Catch [System.Management.Automation.RuntimeException] { #PSRemotingTransportException
    SIOS-Error "PSRemoting must be enabled to use this script. Please run 'winrm quickconfig' on $node2, and retry."
    $paramError = $True
}

if($CommPath1IPs.Count -ne 2) {
    SIOS-Error "USAGE: This script only supports exactly 2 IP addresses for each commpath."
    $paramError = $True
}

if($CommPath2IPs.Count -ne 2) {
    SIOS-Error "USAGE: This script only supports exactly 2 IP addresses for each commpath."
    $paramError = $True
}

if($paramError) {
    if(-Not ($LogFile -like '')) {
        Stop-Transcript
    }
    Exit $False
}

### START

###[commpath１つめ作成]
Write-Host "Creating Cluster"
Invoke-Command $node1 -scriptblock { param($arg1,$arg2) &$env:LKBIN\sys_create -d $arg1 -s $arg2 } -ArgumentList ($node1,$node2) 
Invoke-Command $node2 -scriptblock { param($arg1,$arg2) &$env:LKBIN\sys_create -d $arg1 -s $arg2 } -ArgumentList ($node2,$node1) 

Write-Host "Creating Commpath 1"
###[$node1]
Invoke-Command $node1 -scriptblock { param($arg1,$arg2,$arg3,$arg4) &$env:LKBIN\net_create -d $arg1 -s $arg2 -D TCPIP:1500 -n TLI -b 9600 -r $arg3 -l $arg4 -p 3 -i 6 -k 5 } -ArgumentList ($node1,$node2,$CommPath1IPs[1],$CommPath1IPs[0])
Invoke-Command $node1 -scriptblock { param($arg1) &$env:LKBIN\lcdsync -d $arg1 } -ArgumentList ($node1)
Invoke-Command $node1 -scriptblock { &netsh advfirewall firewall add rule name='LifeKeeper CommPath.1500' dir=in action=allow protocol=TCP localport=1500 }
###[$node2]
Invoke-Command $node2 -scriptblock { param($arg1,$arg2,$arg3,$arg4) &$env:LKBIN\net_create -d $arg1 -s $arg2 -D TCPIP:1500 -n TLI -b 9600 -r $arg3 -l $arg4 -p 3 -i 6 -k 5 } -ArgumentList ($node2,$node1,$CommPath1IPs[0],$CommPath1IPs[1])
Invoke-Command $node2 -scriptblock { param($arg1) &$env:LKBIN\lcdsync -d $arg1 } -ArgumentList ($node2)
Invoke-Command $node2 -scriptblock { &netsh advfirewall firewall add rule name="LifeKeeper CommPath.1500" dir=in action=allow protocol=TCP localport=1500 }

###[commpath２つめ作成]
Write-Host "Creating Commpath 2"
###[$node1]
Invoke-Command $node1 -scriptblock { param($arg1,$arg2,$arg3,$arg4) &$env:LKBIN\net_create -d $arg1 -s $arg2 -D TCPIP:1510 -n TLI -b 9600 -r  $arg3 -l  $arg4 -p 3 -i 6 -k 5} -ArgumentList ($node1,$node2,$CommPath2IPs[1],$CommPath2IPs[0])
Invoke-Command $node1 -scriptblock { param($arg1) &$env:LKBIN\lcdsync -d $arg1} -ArgumentList ($node1)
Invoke-Command $node1 -scriptblock { &netsh advfirewall firewall add rule name="LifeKeeper CommPath.1510" dir=in action=allow protocol=TCP localport=1510}

###[$node2]
Invoke-Command $node2 -scriptblock { param($arg1,$arg2,$arg3,$arg4) &$env:LKBIN\net_create -d $arg1 -s $arg2 -D TCPIP:1510 -n TLI -b 9600 -r  $arg3 -l  $arg4 -p 3 -i 6 -k 5 } -ArgumentList ($node2,$node1,$CommPath2IPs[0],$CommPath2IPs[1])
Invoke-Command $node2 -scriptblock { param($arg1) &$env:LKBIN\lcdsync -d $arg1 } -ArgumentList ($node2)
Invoke-Command $node2 -scriptblock { &netsh advfirewall firewall add rule name="LifeKeeper CommPath.1510" dir=in action=allow protocol=TCP localport=1510 }

###[ipリソース作成]
Write-Host "Creating IP Resource"
###[$node1]
Invoke-Command $node1 -scriptblock { param($arg1,$arg2) &$env:LKBIN\ins_create -I SEC_ISP -d $arg1 -a comm -r ip -t "$arg2" -i "$arg2" -l N -Q 180 -D 300 -s INTELLIGENT } -ArgumentList ($node1,$VIP)
Invoke-Command $node1 -scriptblock { param($arg1,$arg2,$arg3,$arg4) &$env:LKBIN\ins_setin -d $arg1 -t "$arg2" -v "{$arg3}$arg4NNULL$arg2" } -ArgumentList ($node1,$VIP,$MACs[0],$VIPNetMask)
Invoke-Command $node1 -scriptblock { param($arg1,$arg2) &$env:LKBIN\ins_setst -d $arg1 -S OSU -t "$arg2" } -ArgumentList ($node1,$VIP)
Invoke-Command $node1 -scriptblock { param($arg1) &$env:LKBIN\perform_action -b -t "$arg1" -a restore -- -R } -ArgumentList ($VIP)

###[$node2]
Invoke-Command $node2 -scriptblock { param($arg1,$arg2) &$env:LKBIN\ins_create -I SEC_ISP -d $arg1 -a comm -r ip -t "$arg2" -i "$arg2" -l N -Q 180 -D 300 -s INTELLIGENT } -ArgumentList ($node2,$VIP)
Invoke-Command $node2 -scriptblock { param($arg1,$arg2,$arg3,$arg4) &$env:LKBIN\ins_setin -d $arg1 -t "$arg2" -v "{$arg3}$arg4NNULL$arg2" } -ArgumentList ($node2,$VIP,$MACs[1],$VIPNetMask)
Invoke-Command $node2 -scriptblock { param($arg1,$arg2,$arg3) &$env:LKBIN\eqv_create -d $arg1 -s $arg1 -t "$arg2" -S $arg3 -o "$arg2" -e SHARED -p 10 -r 1 } -ArgumentList ($node2,$VIP,$node1)


###[iisリソース作成]
Write-Host "Creating IIS Resource"
###[$node1]
Invoke-Command $node1 -scriptblock { param($arg1) &$env:LKBIN\ins_create -d $arg1 -a WEBServer -r webapp -I SEC_ISP -t IIS.testwebsite -i IIS.testwebsite -D 300 -Q 180 -l Y -s INTELLIGENT -v "8.6.1testwebsiteW3SVC"} -ArgumentList ($node1)
Invoke-Command $node1 -scriptblock { param($arg1,$arg2) &$env:LKBIN\dep_create -d $arg1 -p IIS.testwebsite -c $arg2} -ArgumentList ($node1,$VIP)
Invoke-Command $node1 -scriptblock { &$env:LKBIN\lcdrecover -G restore -- -m}
Invoke-Command $node1 -scriptblock { &$env:LKBIN\perform_action -b -t IIS.testwebsite -a restore -- -R}

###[$node2]
Invoke-Command $node2 -scriptblock { param($arg1) &$env:LKBIN\ins_create -d $arg1 -a WEBServer -r webapp -I SEC_ISP -t IIS.testwebsite -i IIS.testwebsite -v "8.6.1testwebsiteW3SVC" -D 300 -Q 180 -l Y -s INTELLIGENT } -ArgumentList ($node2)
Invoke-Command $node2 -scriptblock { param($arg1,$arg2) &$env:LKBIN\eqv_create -d $arg1 -s $arg1 -t IIS.testwebsite -S $arg2 -o IIS.testwebsite -e SHARED -p 10 -r 1 } -ArgumentList ($node2,$node1)
Invoke-Command $node2 -scriptblock { param($arg1,$arg2) &$env:LKBIN\dep_create -d $arg1 -p IIS.testwebsite -c $arg2 } -ArgumentList ($node2,$VIP)

if(-Not ($LogFile -like '')) {
    Stop-Transcript
}
Exit $True