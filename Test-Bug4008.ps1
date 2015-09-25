#########################################################################################################
# BUG 3998
#########################################################################################################

. .\Utilities_DK.ps1

# USER DEFINED PARAMS
$nodes = "logotest9","logotest10","logotest11" # DONT include the FQDN or names wont match cluster node names!
$domain = "qatest.com"
$nodeIPs = "10.2.1.215","10.2.1.216","10.2.1.217"
$netAdapters = "Public","Private"
$mirrorVol = "G"
