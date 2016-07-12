set index=0 

:writeContinuously
	for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c-%%a-%%b)
	for /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set mytime=%%a%%b)
	echo %index%: %mydate%_%mytime% >> C:\ReproduceBug4137.log
	set /A index=index+1
	start "" "C:\Users\Administrator.QAGROUP\Desktop\Utilities\WriteFile.exe" -r E:\768M.file 768

:checkNotMirroringState
	timeout /t 5
	for /f "delims=" %%i in ('emcmd . getmirrorvolinfo e') do set output=%%i
	set state=%output:~-1%
	if %state% NEQ 1 (
		TASKKILL /F /IM "WriteFile.exe"
		emcmd . continuemirror e
		goto checkNotMirroringState
	) 

timeout /t 120
goto writeContinuously
