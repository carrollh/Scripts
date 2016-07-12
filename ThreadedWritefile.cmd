set count=0
:loop
  start C:\Users\administrator.QAGROUP\Desktop\CallWriteFile.cmd %count%
  set /a count+=1
  if %count% lss %1 goto loop

:end
