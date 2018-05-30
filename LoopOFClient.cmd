REM Script to loop over OFClient

set VOLS=B E F G H I J K L M N O P Q R S T U V W X Y Z
:loop
    for %%v in (%VOLS%) do (
    	OFClient.exe -w %%v 
    )
    goto loop
:end
