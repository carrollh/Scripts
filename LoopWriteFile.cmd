REM Script to loop over CallWriteFile indefinitely
 
REM %1 = targetvol    (F)
REM %2 = filename     (heathtest1)
REM %3 = write amount (10000k, 100, 100M, etc)
REM Example call: LoopWriteFile F heathtest1 100M 

:loop
	.\WriteFile.exe -t -r -n %1:\%2 %3
goto loop
