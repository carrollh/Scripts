set scriptdir=%CD%
cd %extmirrbase%

REM Deleting all jobs
PowerShell.exe -Command "& '%scriptdir%\Remove-AllDataKeeperJobs.ps1'

set node0=cae-qa-v200
set node1=cae-qa-v201
set node2=cae-qa-v202
set ip0=10.200.8.200
set ip1=10.200.8.201
set ip2=10.200.8.202
set vol0=E
set vol1=F

REM Deleting potential Mirrors on %vol0% from all nodes
emcmd %node0% unlockvolume %vol0%
emcmd %node0% deletelocalmirroronly %vol0%
emcmd %node0% clearswitchover %vol0%
emcmd %node0% updatevolumeinfo %vol0%

emcmd %node1% unlockvolume %vol0%
emcmd %node1% deletelocalmirroronly %vol0%
emcmd %node1% clearswitchover %vol0%
emcmd %node1% updatevolumeinfo %vol0%

emcmd %node2% unlockvolume %vol0%
emcmd %node2% deletelocalmirroronly %vol0%
emcmd %node2% clearswitchover %vol0%
emcmd %node2% updatevolumeinfo %vol0%

REM creating initial jobs and mirrors
REM simple 1x1 async mirror on E from %node0% to %node1%
emcmd %node0% createjob vol.%vol0% test %node0% %vol0% %ip0% %node1% %vol0% %ip1% A %node0% %vol0% %ip0% %node2% %vol0% %ip2% A %node1% %vol0% %ip1% %node2% %vol0% %ip2% A
emcmd %ip0% createmirror %vol0% %ip1% A

REM ****** ALL OF THE FOLLOWING SHOULD FAIL ******
REM 1 - invalid number of arguments
emcmd %node0% CHANGEMIRRORTYPE %vol0% %ip1%

REM 2 - invalid mirror type
emcmd %node0% CHANGEMIRRORTYPE %vol0% %ip1% D

REM 3 - word used as mirrortype instead of letter
emcmd %node0% CHANGEMIRRORTYPE %vol0% %ip1% Sync

REM 4 - volume used exists but not mirrored currently (Status = 15)
emcmd %node0% CHANGEMIRRORTYPE %vol1% %ip1% S

REM 5 - volume used does not exist (Status = 15)
emcmd %node0% CHANGEMIRRORTYPE Z %ip1% S

REM 6 - volume used is not a letter
emcmd %node0% CHANGEMIRRORTYPE ? %ip1% S

REM 7 - mirror already has passed in mirror type (Status = 87)
emcmd %node0% CHANGEMIRRORTYPE %vol0% %ip1% A

REM 8 - mirror used is a word (not letter) but starts with valid volume / mirror letter
emcmd %node0% CHANGEMIRRORTYPE %vol0%lephant %ip1% A

REM 9 - ip passed in is not in use in a mirror, but is assigned on this node
emcmd %node0% CHANGEMIRRORTYPE %vol0% 172.17.205.200 S

REM 10 - ip passed in is not in use in a mirror, nor does it exist on this node0
emcmd %node0% CHANGEMIRRORTYPE %vol0% 172.17.205.200 S

REM 11 - ip passed in IS in use for this mirror, but does not match the node passed in
emcmd %node0% CHANGEMIRRORTYPE %vol0% %ip1% S

REM 12 - node passed in does not exist
emcmd cae-qa-vXYZ CHANGEMIRRORTYPE %vol0% %ip0% S

REM 13 - node passed in exists, but not in any job associated with vol0 or ip0
emcmd cae-qa-v204 CHANGEMIRRORTYPE %vol0% %ip0% S


REM ****** ALL OF THE FOLLOWING SHOULD SUCCEED ******
REM 1 - Change single mirror from Async to Sync, visually check 



cd %scriptdir%


