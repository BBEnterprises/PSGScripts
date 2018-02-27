class server {
    [string]$name;
    [string]$armorName;

    static [hashtable]$armorNames = @{
        'HSS-PROD-APP01' = 'PHAR06VMA03';
        'HSS-PROD-FTP02' = 'PHAR06VMA04';
        'HSS-PROD-DB08'  = 'PHAR06VMA05';
        'HSS-PROD-DT01'  = 'PHAR06VMA06';
        'HSS-PROD-PW01'  = 'PHAR06VMA07';
        'HSS-PROD-DB07'  = 'PHAR06VMD01';
        'HSS-TEST-DB01'  = 'PHAR06VMD06';
        'HSS-PROD-DB02'  = 'PHAR06VMD07';
        'HSS-TEST-DB02'  = 'PHAR06VMD08';
        'HSS-PROD-DB03'  = 'PHAR06VMD09';
        'HSS-PROD-DB04'  = 'PHAR06VMD10';
        'HSS-PROD-DB05'  = 'PHAR06VMD11';
        'HSS-PROD-DB06'  = 'PHAR06VMD12';
        'HSS-PROD-DB01'  = 'PHAR06VMD13';
        'HSS-TEST-WEB01' = 'PHAR06VMW03';
        'HSS-PROD-WEB01' = 'PHAR06VMW04';
        'HSS-PROD-WEB03' = 'PHAR06VMW05';
        'HSS-PROD-WEB02' = 'PHAR06VMW06';
        'HSS-PROD-SVC01' = 'PHAR06VMA09';
    };

    server([string]$serverName) {
        $this.name      = $serverName;
        
        if ([server]::armorNames.$serverName) {
            $this.armorName = [server]::armorNames.$serverName;
        }
    }

    [bool]testRPC () {
        $job = Start-Job -ArgumentList($this.name) -ScriptBlock {
            param([string]$serverName);

            Invoke-Command -ComputerName $serverName -ScriptBlock { return 1 }
        }

        Wait-Job -Job $job -Timeout 30 | Out-Null;

        if ($job.State -eq 'Completed') {
            $result = Receive-Job -Job $job;
            Remove-Job -Job $job;
            return $result;
        }
        else {
            Stop-Job   -Job $job;
            Remove-Job -Job $job
            return 0;
        }
    }
}

function readConfig {
    param(
        [hashtable]$params,
        [ref]      $servers
    );

    Get-Content -Path $params.cfgFile | ?{ $_ -notmatch '^\s*#'} | %{
        $servers.Value += [server]::new($_);
    }
}

function checkServers {
    param(
         [hashtable]$params
        ,[array]    $servers
    );
    
    [array]$downServers = @();

    foreach ($server in $servers) {
        Write-Host $server.Name $server.armorName;
        if(-not $server.testRPC()) {
            $downServers += $server;
        }
    }

    if ($downServers) {
        alert $params $downServers;
    }
}

function alert {
    param(
         [hashtable]$params
        ,[array]    $downServers
    );

    [string]  $body       = generateAlertText $downServers;
    [DateTime]$dateTime   = [DateTime]::Now;
    [string]  $toMail     = 'cgamble@psg340b.com';
    #[string]  $toMail     = 'PSG340BTechOps@psg340b.com';
    [string]  $fromMail   = 'amonitor@psgconsults.com';
    [string]  $subject    = 'Server RPC Unavailable!';
    [string]  $smtp       = 'smtp.office365.com'
    [string]  $logMessage = '';
    
    [securestring]$secPassWord = Get-Content $params.passFile | ConvertTo-SecureString
                  $creds       = New-Object System.Management.Automation.PSCredential($fromMail, $secPassWord);

    foreach ($server in $downServers) {
        $logMessage += ("{0} : {1} : {2} : Email notification sent to {3}`n" -f `
            $dateTime `
            ,$server.name `
            ,$server.armorName `
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
        
        $logMessage | Out-File -FilePath $params.alertLog -Encoding ascii -Append;
    }
    catch {
        "{0} : Failed to send email alert to {1} with exception:{2}`n" -f $dateTime, $toMail, $_.Exception.Message | Out-File -FilePath $params.alertLog -Encoding ascii -Append;
    }


}

function generateAlertText {
    param($servers);

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
            <h3>ALERT - SERVER RPC UNAVAILABLE</h3>
            <p>The following servers are inaccessible via RPC. Make sure you can RDP to each one and verify all services are healthy. If all services are healthy and you cannot get an RDP session you may need to schedule an after-hours reboot</p>

		    <table cellspacing="0" style="width:100%">
			    <th align="left">Server Name</th>			    
			    <th align="left">Armor Name</th>
';
    $counter = 1;
    foreach ($server in $servers) {

        $message += ('
        <tr class="{0}">
            <td>{1}</td>
            <td>{2}</td>
        </tr>' -f $classArr[($counter % 2)], $server.name, $server.armorName);

        $counter++
    }
    
    $message += '
        </table>
        </body>
    </html>
    ';

    return $message;
}

############
#Main Block#
############
[hashtable]$params = @{
    'cfgFile'  = 'C:\users\cgamble\Documents\code\psgscripts\scriptCfg\rpcMonitor.cfg';
    'baseLog'  = 'C:\temp\rpcMonitor.base.log';
    'alertLog' = 'C:\temp\rpcMonitor.alert.log';
    'passFile' = 'C:\temp\smtpPass';
}

[array]$servers = @();

readConfig   $params ([ref]$servers);
checkServers $params $servers;