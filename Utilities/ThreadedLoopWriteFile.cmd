REM Script to loop over WriteFile indefinitely using %4 threads
 
REM %1 = targetvol    (F)
REM %2 = filename     (heathtest)
REM %3 = write amount (10000k, 100, 100M, etc)
REM %4 = number of threads to kick off (4)
REM Example call: ThreadedLoopWriteFile F heathtest 100M 4 

set count=0
:loop
	start .\LoopWriteFile.cmd %1 %2%count% %3 
	set /a count+=1
	if %count% lss %4 goto loop
:end
