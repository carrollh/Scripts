#########################################################################################################
# BUG 4005 Bside Extend Volume
#########################################################################################################

# USER DEFINED PARAMS
$mirrorVol = "E"

$commands = @"
select volume $mirrorVol
extend size=1
exit
"@

$commands | diskpart 