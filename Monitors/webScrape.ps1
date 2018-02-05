function createCreds {
    $username = 'cgamble@psg340b.com'; #NEEDS Monitoring User
    $password = Get-Content C:\Users\cgamble\Documents\emailpass.txt | ConvertTo-SecureString;
    return New-Object -TypeName System.Management.Automation.PSCredential `
        -ArgumentList $userName, $password;
}

function alert {
    param($message);

    #$creds    = createCred
    $toMail   = 'cgamble@psg340b.com';
    $fromMail = 'WebPortalMonitor@psg340b.com';
    $subject  = 'Web Portal Error';
    $body     = $message;
    $smtp     = 'smtp.office365.com'

    Send-MailMessage `
        -To $toMail `
        -From $fromMail `
        -Subject $subject `
        -Body $body `
        -SmtpServer $smtp `
        -Credential $creds;

    Write-Host $message;
}

function scrapeURL {
    param($uri, $keyString);
    $page = '';
    try {
        $page = Invoke-WebRequest -Uri $uri -TimeoutSec 1;
    }
    catch {
        $errStr  = $_.Exception.Message;
        $errStr  = $errStr.subString(0, [System.Math]::Min(40, $errStr.Length));
        $message = '{0} threw error: {1}' -f $uri, $errStr;
        
        alert $errStr;
        return;
    }

    if (-not ($page.RawContent -cmatch $keyString)) {
        $message  = '{0} resolved with incorrect content!' -f $uri;
        alert $message;
    }
}

scrapeURL '10.255.255.1' 'Google has many special features';