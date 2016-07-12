netsh interface set interface name="LAN1 - Public" admin=disabled
netsh interface set interface name="LAN2 - Public" admin=disabled
netsh interface set interface name="LAN3 - Private" admin=disabled
netsh interface set interface name="LAN4 - Private" admin=disabled

timeout /nobreak /t 600

netsh interface set interface name="LAN1 - Public" admin=enabled
netsh interface set interface name="LAN2 - Public" admin=enabled
netsh interface set interface name="LAN3 - Private" admin=enabled
netsh interface set interface name="LAN4 - Private" admin=enabled