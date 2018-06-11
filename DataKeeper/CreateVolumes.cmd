REM Example call: CreateVolumes 1

if "%1"=="" (
echo Hey I need a disk number
goto done
)

set DISK=%1
echo select disk %DISK% > prep.scr
echo create partition extended >> prep.scr

REM Create partitions (400MB) and assign drive letters J=R, U-W
for %%l in (F H J L N P R T V X Z) do (
REM for %%l in (B E G I K M O Q S U W Y) do (
	echo create partition logical size=400 >> prep.scr
	echo assign letter=%%l >> prep.scr
	echo format FS=NTFS QUICK >> prep.scr
)

echo exit >> prep.scr

REM Now make it happen
diskpart /s prep.scr

:done
