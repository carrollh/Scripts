setlocal enabledelayedexpansion

set NODE1=CAE-QA-V200.QAGROUP.COM
set NODE2=CAE-QA-V201.QAGROUP.COM

set IP1=10.200.8.200
set IP2=10.200.8.201

set VOLS=B E F G H I J K L M N O P Q R S T U V W X Y Z

for %%v in (%VOLS%) do (
	emcmd %IP1% createmirror %%v %IP2% a
	if not %errorlevel%==0 goto done

	emcmd %NODE1% createjob %%v "" %NODE1% %%v %IP1% %NODE2% %%v %IP2% A
	if not %errorlevel%==0 goto done
)


:done
