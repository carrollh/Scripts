set scriptdir=%CD%
cd %extmirrbase%
PowerShell.exe -Command "& '%scriptdir%\Remove-AllDataKeeperJobs.ps1'

REM the following should succeed
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 E 10.200.8.201 A
PowerShell.exe -Command "& '%scriptdir%\Remove-AllDataKeeperJobs.ps1'
emcmd . createjob vol.F test cae-qa-v200 F 10.200.8.200 cae-qa-v201 F 10.200.8.201 a
PowerShell.exe -Command "& '%scriptdir%\Remove-AllDataKeeperJobs.ps1'
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 E 10.200.8.201 "A"
PowerShell.exe -Command "& '%scriptdir%\Remove-AllDataKeeperJobs.ps1'
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 E 10.200.8.201 S
PowerShell.exe -Command "& '%scriptdir%\Remove-AllDataKeeperJobs.ps1'
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 E 10.200.8.201 s
PowerShell.exe -Command "& '%scriptdir%\Remove-AllDataKeeperJobs.ps1'
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 E 10.200.8.201 "S"
PowerShell.exe -Command "& '%scriptdir%\Remove-AllDataKeeperJobs.ps1'
emcmd . createjob vol.F test cae-qa-v200 F 10.200.8.200 cae-qa-v201 F 10.200.8.201 D
PowerShell.exe -Command "& '%scriptdir%\Remove-AllDataKeeperJobs.ps1'
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 E 10.200.8.201 d
PowerShell.exe -Command "& '%scriptdir%\Remove-AllDataKeeperJobs.ps1'
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 E 10.200.8.201 "D"
PowerShell.exe -Command "& '%scriptdir%\Remove-AllDataKeeperJobs.ps1'
emcmd . createjob vol.F test cae-qa-v200 F 10.200.8.200 cae-qa-v202 F 10.200.8.202 A cae-qa-v200 F 10.200.8.200 cae-qa-v203 F 10.200.8.203 S cae-qa-v202 F 10.200.8.202 cae-qa-v203 F 10.200.8.203 D
PowerShell.exe -Command "& '%scriptdir%\Remove-AllDataKeeperJobs.ps1'

REM all of the following should fail
emcmd . createjob vol.F test cae-qa-v200 F 10.200.8.200 cae-qa-v202 F 10.200.8.202 Async cae-qa-v200 F 10.200.8.200 cae-qa-v203 F 10.200.8.203 A cae-qa-v202 F 10.200.8.202 cae-qa-v203 F 10.200.8.203 A
emcmd . createjob vol.F test cae-qa-v200 F 10.200.8.200 cae-qa-v202 F 10.200.8.202 A cae-qa-v200 F 10.200.8.200 cae-qa-v203 F 10.200.8.203 Sync cae-qa-v202 F 10.200.8.202 cae-qa-v203 F 10.200.8.203 A
emcmd . createjob vol.F test cae-qa-v200 F 10.200.8.200 cae-qa-v202 F 10.200.8.202 A cae-qa-v200 F 10.200.8.200 cae-qa-v203 F 10.200.8.203 A cae-qa-v202 F 10.200.8.202 cae-qa-v203 F 10.200.8.203 Disk
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 E 10.200.8.201 Async
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 E 10.200.8.201 async
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 E 10.200.8.201 Sync
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 E 10.200.8.201 sync
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 E 10.200.8.201 Disk
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 E 10.200.8.201 disk
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 E 10.200.8.201 'A'
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 E 10.200.8.201 'a'
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 E 10.200.8.201 P
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 E 10.200.8.201 p
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 E 10.200.8.201 $
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 E 10.200.8.201 .
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 E 10.200.8.201 " "
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 E 10.200.8.201 ""
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 E 10.200.8.201 ' '

