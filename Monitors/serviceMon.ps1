﻿function readConfig {
    param($cfgFile);

    $services = @();

    Get-Content -Path $cfgFile | ?{ $_ -notmatch '^\s*#'} | %{
        ($serverName, $serviceName, $monitored) = $_ -split '\s*:\s*';
        $services += New-Object -TypeName PSObject -Property @{
            'serverName'  = $serverName;
            'serviceName' = $serviceName;
            'monitored'   = $monitored;
            'Status'      = 'unknown';
        }
    }

    return $services;
}

function checkService {
    param([ref]$service);
    $serviceObj = 0;

    <#$job = Start-Job -ArgumentList($service) -ScriptBlock {
        param($service);
        Get-Service -ComputerName $service.value.serverName -Name $service.value.serviceName -ErrorAction SilentlyContinue;
    }#>

    $job = Start-Job -ArgumentList($service) -ScriptBlock {
        param($service);
        Invoke-Command -ComputerName $service.value.serverName -ArgumentList($service.value.serviceName) -ScriptBlock {
            param($serviceName);
            Get-Service -Name $serviceName -ErrorAction SilentlyContinue;
        }
    }

    if (Wait-Job -Job $job -Timeout 15) {
        $serviceObj = Receive-Job $job;
        Remove-Job $job;
    }
    else {
        Stop-Job $job;
        Remove-Job $job;
        $logMessage = "Get-Service remote invocation failed against {0}!" -f $service.value.serverName;
        $logMessage | Out-File -FilePath $global:baseLog -Encoding ascii -Append;
    }

    if ($serviceObj) {
        $service.value.Status = $serviceObj.Status.ToString();    
    }

    $dateTime = [DateTime]::Now;
    ('{0} : {1} : {2} : {3}' -f $dateTime, $service.value.serverName, $service.value.serviceName, $service.value.Status) |
    Out-File -FilePath $global:baseLog -Encoding ascii -Append;

    if ($service.value.Status -ne 'Running')  {
        return 1;
    }

    return 0;
}

function generateAlertText {
    param($services);

    $classArr = @('even', 'odd');

    $message = '
    <!DOCTYPE html>
    <html>
	    <head>
            <style>
                tr.even {
                    background-color:lightblue;
                }
                tr.odd {
                    background-color:lightgrey;
                }
            </style>
	    </head>
	    <body>
            <h3>Service Down Alert</h3>
            <p>The following services are not currently running. Please check the status of each one and bring it online if necessary.</p>

		    <table cellspacing="0" style="width:100%">
			    <th align="left">Server Name</th>			    
			    <th align="left">Service Name</th>
                <th align="left">Executable</th>
';
    $counter = 1;
    foreach ($service in $services) {
        $execPath = getExecutable $service;

        $message += ('
        <tr class="{0}">
            <td>{1}</td>
            <td>{2}</td>
            <td>{3}</td>
        </tr>' -f $classArr[($counter % 2)], $service.serverName, $service.serviceName, $execPath);

        $counter++
    }
    
    $message += '
        </table>
        <h3>Service Start Instructions</h3>
        <p>To bring a service online, RDP to the server in question and open the "Services Manager" window. This can be done by typing "Services" into the run bar. Find the service in the list, right-click, and select "Start"</p>
        <p>If the service does not come online, and stay online, check the event log ("Event Viewer" in the run bar" for any relevant errors or clues, you may also need to check whatever logs are generated by the service in question</p>
        </body>
    </html>
    ';

    return $message;
}

function getExecutable {
    param($service);

    if ($service.Status -eq 'unknown') {
        return 'unknown';
    }

    $execPath = Get-WmiObject win32_service -ComputerName $service.serverName | 
        ?{ $_.Name -like $service.serviceName } | 
        select PathName

    return $execPath.PathName;
}

function alert {
    param(
        $message
        ,$downServices
    );

    $dateTime   = [DateTime]::Now;
    $toMail     = 'cgamble@psg340b.com';
    #$toMail     = 'PSG340BTechOps@psg340b.com';
    $fromMail   = 'amonitor@psgconsults.com';
    $subject    = 'Production Services Down!';
    $body       = $message;
    $smtp       = 'smtp.office365.com'
    $logMessage = '';
    
    $secPassWord = Get-Content $global:passFile | ConvertTo-SecureString
    $creds       = New-Object System.Management.Automation.PSCredential($fromMail, $secPassWord);

    foreach ($service in $downServices) {
        $logMessage += ("{0} : {1} : {2} : {3} : Email notification sent to {4}`n" -f `
            $dateTime `
            ,$service.serverName `
            ,$service.serviceName `
            ,$service.Status `
            ,$toMail
        );
    }
    
    try {
        Send-MailMessage `
            -To $toMail `
            -From $fromMail `
            -Subject $subject `
            -Body $body `
            -SmtpServer $smtp `
            -Credential $creds `
            -UseSsl `
            -BodyAsHtml `
            -Port 587 `
            -ErrorAction Stop;
        
        $logMessage | Out-File -FilePath $global:alertLog -Encoding ascii -Append;
    }
    catch {
        "{0} : Failed to send email alert to {1} with exception:{2}`n" -f $dateTime, $toMail, $_.Exception.Message | Out-File -FilePath $global:alertLog -Encoding ascii -Append;
    }

}

#######################
#Main Block Below Here#
#######################
#$cfgFile      = 'C:\users\cgamble\documents\betaServiceMon.cfg';
$cfgFile      = 'C:\users\cgamble\documents\code\PSGScripts\scriptCfg\serviceMon.cfg';
$baseLog      = 'C:\temp\serviceMon.log';
$alertLog     = 'C:\temp\serviceMonAlert.log';
$passFile     = 'C:\temp\smtpPass';
$services     = readConfig $cfgFile;
$downServices = @();


foreach ($service in $services) {
    if (checkService ([ref]$service)) {
        $downServices += $service;
    }
}


<#
1 - Make script output to log even when it finds no problems
#>


if ($downServices) {
    $message = generateAlertText $downServices
    alert $message $downServices;
}
