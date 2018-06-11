set scriptdir=%CD%
cd %extmirrbase%
PowerShell.exe -Command "& '%scriptdir%\Remove-AllDataKeeperJobs.ps1'

REM the following should succeed
emcmd . createjob vol.E test cae-qa-v200 e 10.200.8.200 cae-qa-v201 E 10.200.8.201 A
PowerShell.exe -Command "& '%scriptdir%\Remove-AllDataKeeperJobs.ps1'
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 e 10.200.8.201 A
PowerShell.exe -Command "& '%scriptdir%\Remove-AllDataKeeperJobs.ps1'
emcmd . createjob vol.E test cae-qa-v200 "E" 10.200.8.200 cae-qa-v201 E 10.200.8.201 A
PowerShell.exe -Command "& '%scriptdir%\Remove-AllDataKeeperJobs.ps1'
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 "E" 10.200.8.201 A
PowerShell.exe -Command "& '%scriptdir%\Remove-AllDataKeeperJobs.ps1'
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 E 10.200.8.201 A
PowerShell.exe -Command "& '%scriptdir%\Remove-AllDataKeeperJobs.ps1'
emcmd . createjob vol.F test cae-qa-v200 F 10.200.8.200 cae-qa-v201 F 10.200.8.201 S
PowerShell.exe -Command "& '%scriptdir%\Remove-AllDataKeeperJobs.ps1'
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v202 E 10.200.8.202 D
PowerShell.exe -Command "& '%scriptdir%\Remove-AllDataKeeperJobs.ps1'
emcmd . createjob vol.F test cae-qa-v200 F 10.200.8.200 cae-qa-v202 F 10.200.8.202 A cae-qa-v200 F 10.200.8.200 cae-qa-v203 F 10.200.8.203 A cae-qa-v202 F 10.200.8.202 cae-qa-v203 F 10.200.8.203 A
PowerShell.exe -Command "& '%scriptdir%\Remove-AllDataKeeperJobs.ps1'

REM all of the following should fail
emcmd . createjob vol.F test cae-qa-v200 F 10.200.8.200 cae-qa-v202 F 10.200.8.202 A cae-qa-v200 F 10.200.8.200 cae-qa-v203 F 10.200.8.203 A cae-qa-v202 . 10.200.8.202 cae-qa-v203 F 10.200.8.203 A
emcmd . createjob vol.F test cae-qa-v200 F 10.200.8.200 cae-qa-v202 F 10.200.8.202 A cae-qa-v200 F 10.200.8.200 cae-qa-v203 F 10.200.8.203 A cae-qa-v202 F 10.200.8.202 cae-qa-v203 . 10.200.8.203 A

REM testing DrvLetter1
emcmd . createjob vol.E test cae-qa-v200 'E' 10.200.8.200 cae-qa-v201 E 10.200.8.201 A
emcmd . createjob vol.E test cae-qa-v200 . 10.200.8.200 cae-qa-v201 E 10.200.8.201 A
emcmd . createjob vol.E test cae-qa-v200 $ 10.200.8.200 cae-qa-v201 E 10.200.8.201 A
emcmd . createjob vol.E test cae-qa-v200 - 10.200.8.200 cae-qa-v201 E 10.200.8.201 A
emcmd . createjob vol.E test cae-qa-v200 " " 10.200.8.200 cae-qa-v201 E 10.200.8.201 A
emcmd . createjob vol.E test cae-qa-v200 "" 10.200.8.200 cae-qa-v201 E 10.200.8.201 A
emcmd . createjob vol.E test cae-qa-v200 ear 10.200.8.200 cae-qa-v201 E 10.200.8.201 A

REM testing DrvLetter2
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 'E' 10.200.8.201 A
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 . 10.200.8.201 A
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 $ 10.200.8.201 A
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 - 10.200.8.201 A
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 " " 10.200.8.201 A
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 "" 10.200.8.201 A
emcmd . createjob vol.E test cae-qa-v200 E 10.200.8.200 cae-qa-v201 ear 10.200.8.201 A 