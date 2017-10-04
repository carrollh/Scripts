set scriptdir=%CD%
cd %extmirrbase%

:loop
	emcmd 10.200.8.200 createmirror E 10.200.8.202 A
	emcmd . updatejob cb23a281-0b8a-497c-a4ee-357b41bb8ddc vol.E "" cae-qa-v200.qagroup.com E 10.200.8.200 cae-qa-v201.qagroup.com E 10.200.8.201 A cae-qa-v200.qagroup.com E 10.200.8.200 cae-qa-v202.qagroup.com E 10.200.8.202 A cae-qa-v201.qagroup.com E 10.200.8.201 cae-qa-v202.qagroup.com E 10.200.8.202 A

	emcmd . deletemirror E 10.200.8.202
	emcmd . updatejob cb23a281-0b8a-497c-a4ee-357b41bb8ddc vol.E "" cae-qa-v200.qagroup.com E 10.200.8.200 cae-qa-v201.qagroup.com E 10.200.8.201 A
goto loop

:end 
	cd %scriptdir%



