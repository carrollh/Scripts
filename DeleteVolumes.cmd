if "%1"=="" (
	echo Hey I need a starting volume index
	goto done
)

if %1 LSS 3 (
	echo Sorry, you can't delete volumes 0, 1, or 2. Nope nope nope.
	goto done
)

if "%2"=="" (
	echo Hey I need an ending volume index
	goto done
)

echo list vol > prep.scr
for /l %%i in (%1,1,%2) do (
	echo select vol %%i >> prep.scr
	echo delete vol OVERRIDE >> prep.scr
)

echo exit >> prep.scr

diskpart /s prep.scr

:done
