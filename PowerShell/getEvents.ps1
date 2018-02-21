$computers = @(
    'HSS-PROD-APP02'
    ,'HSS-PROD-DB08'
    ,'HSS-PROD-DT01'
    ,'HSS-PROD-PW01'
    ,'HSS-PROD-DB07'
    ,'HSS-TEST-DB01'
    ,'HSS-PROD-DB02'
    ,'HSS-TEST-DB02'
    ,'HSS-PROD-DB03'
    ,'HSS-PROD-DB04'
    ,'HSS-PROD-DB05'
    ,'HSS-PROD-DB06'
    ,'HSS-PROD-DB01'
    ,'HSS-PROD-WEB01'
    ,'HSS-PROD-WEB03'
    ,'HSS-PROD-WEB02'
    ,'HSS-PROD-SVC02'
);

foreach ($computer in $computers) {
    #Write-Host $computer;
    #Get-EventLog -ComputerName $computer -EntryType Error -Message "*armor-supervisor.exe*" -LogName Application -After ([DateTime]::Today)
    if (Gwmi Win32_NTLogEvent -ComputerName $computer -filter "(Logfile='application') AND (EventIdentifier = '1000') and (Message LIKE '%Armor%')") {
        Write-Host $computer;
    }
}