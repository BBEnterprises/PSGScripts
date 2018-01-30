function alert {
    param($message);

    Write-Host $message;
}

function scrapeURL {
    param($uri, $keyString);
    $page = '';
    try {
        $page = Invoke-WebRequest -Uri $uri -TimeoutSec 1;
    }
    catch {
        $errStr = $_.Exception.Message;
        $errStr = $errStr.subString(0, [System.Math]::Min(40, $errStr.Length));
        alert $errStr;
        return;
    }

    if (-not ($page.RawContent -cmatch $keyString)) {
        $message  = '{0} resolved with incorrect content!' -f $uri;
        alert $message;
    }
}

scrapeURL '10.255.255.1' 'Google has many special features';
