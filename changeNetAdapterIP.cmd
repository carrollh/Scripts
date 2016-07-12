set index=0
echo %index% > C:\runs.log
:loop
	netsh interface ip set address "LAN3 - Private" static 10.200.8.153 255.255.255.0 
	timeout /nobreak /t 60
	netsh interface ip set address "LAN3 - Private" static 10.200.8.53 255.255.255.0  
	timeout /nobreak /t 60
	
	set /A index=index+1
	echo %index% >> C:\runs.log
	
	goto loop
