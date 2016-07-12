:downNetAdapters
	netsh interface set interface name="LAN1 - Public" admin=disabled
	netsh interface set interface name="LAN2 - Public" admin=disabled
	netsh interface set interface name="LAN3 - Private" admin=disabled
	
timeout /t 10

:upNetAdapters
	netsh interface set interface name="LAN1 - Public" admin=enabled
	netsh interface set interface name="LAN2 - Public" admin=enabled
	netsh interface set interface name="LAN3 - Private" admin=enabled	

timeout /t 30
goto downNetAdapters
 