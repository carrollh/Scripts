set file="E:\512M.file"
set maxSize=536870912
:loop
	"C:\Users\administrator.QAGROUP\Desktop\Utilities\WriteFile.exe" -t -r -n %file% 512
	FOR /F "usebackq" %%A IN ('%file%') DO set size=%%~zA
	if %size% LSS %maxSize% (
		goto exit
	)
	goto loop

:exit 
	Exit
