'CHANGE THE DATA SOURCE AND LOGIN BELOW
'ADJUST THE COUNTER AND SLEEP VARIABLES AS NECESSARY
'I.E.-COUNTER 60 AND SLEEP 1000=1 WRITE TO DB EVERY SECOND=60 SECONDS OF WRITES
'I.E.-COUNTER 60 AND SLEEP 250=1 WRITE TO DB EVERY .25 SECONDS=15 SECONDS OF WRITES

Const adOpenStatic = 3
Const adLockOptimistic = 3

Set objConnection = CreateObject("ADODB.Connection")
Set objRecordSet = CreateObject("ADODB.Recordset")
Set objRecordGet = CreateObject("ADODB.Recordset")

Dim Counter 

objConnection.Open _
    "Provider=SQLOLEDB;Data Source=10.200.8.98;" & _
        "Trusted_Connection=Yes;Initial Catalog=QA_SQL_DB_VOL1;" & _
             "User ID=qagroup\administrator;Password=frs.123;"

Do until Counter=10000



objRecordSet.Open "INSERT INTO QA_SQL_STRESS_VOL1 VALUES (GETDATE(),CURRENT_TIMESTAMP)", _
        objConnection, adOpenStatic, adLockOptimistic



'WScript.Sleep 500'1000=1 second
counter=Counter+1

Loop

msgbox ("Writes completed")