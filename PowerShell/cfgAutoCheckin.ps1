function compareFiles {
    param($file1, $file2);

    return (Compare-Object -ReferenceObject $(Get-Content $file1) -DifferenceObject $(Get-Content $file2));
}

function checkInFiles {
    $commitMessage = [datetime]::Now.ToString('MM/dd/yyyy') + ' Auto Commit';

    git checkout staging;
    git add ./;
    git commit -m $commitMessage;

    $output = git push 2>&1;

    if ($output -match 'error:') {
        alert ($output.Exception.Message -join "`n");
    }
}

function alert {
    param(
        $message
    );

    $dateTime   = [DateTime]::Now;
    $toMail     = 'cgamble@psg340b.com';
    #$toMail     = 'PSG340BTechOps@psg340b.com';
    $fromMail   = 'amonitor@psgconsults.com';
    $subject    = '340b Cfg AutoCommit Failed!';
    $body       = $message;
    $smtp       = 'smtp.office365.com'
    $logMessage = '';
  
    $secPassWord = Get-Content $global:passFile | ConvertTo-SecureString
    $creds       = New-Object System.Management.Automation.PSCredential($fromMail, $secPassWord);
    
    try {
        Send-MailMessage `
            -To $toMail `
            -From $fromMail `
            -Subject $subject `
            -Body $body `
            -SmtpServer $smtp `
            -Credential $creds `
            -UseSsl `
            -Port 587 `
            -ErrorAction Stop;       
    }
    catch {
        "{0} : Failed to send email alert to {1} with exception:{2}`n" -f $dateTime, $toMail, $_.Exception.Message | Out-File -FilePath $global:alertLog -Encoding ascii -Append;
    }

}

############
#Main Block#
############
$localRepo   = 'C:\users\cgamble\Documents\code\PSG340B_EDISVC_Configs\cfgFiles\';
$regEx       = [System.Text.RegularExpressions.Regex]::Escape($localRepo) + '(.+)$';
$alertLog    = 'C:\temp\autoCheckInAlertLog';
$passFile    = 'C:\Temp\smtpPass';
$checkInList = @();
$localList   = @();
$remoteList  = @();

<#
Build local list
Build remote list
Compare all files that exist in both, checkin changes
look for any files missing from local list, add them, check in
look for any files missing from remote list, remove them, check in 
push

#>


Set-Location $localRepo;

Get-ChildItem $localRepo -Recurse | ?{ -not $_.PSIsContainer }|%{
    $remotePath = '';


    if ($_.FullName -match $regEx) {
        $remotePath = '\\' + $matches[1];

        
        <#
        if (compareFiles $_.FullName $remotePath) {
            $checkInList += $remotePath;
            Copy-Item -Path $remotePath -Destination $_.FullName;
        }
        #>
    }
}

if ($checkInList) {
    checkInFiles;
}

