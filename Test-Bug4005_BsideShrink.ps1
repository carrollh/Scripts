#########################################################################################################
# BUG 4005 Bside Shrink Volume
#########################################################################################################

# USER DEFINED PARAMS
$mirrorVol = "E"

$commands = @"
select volume $mirrorVol
shrink desired=1
exit
"@

$commands | diskpart 