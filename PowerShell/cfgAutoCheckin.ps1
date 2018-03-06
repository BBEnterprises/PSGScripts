function compareFiles {
    param($file1, $file2);

    return (Compare-Object -ReferenceObject $(Get-Content $file1) -DifferenceObject $(Get-Content $file2));
}

function checkInChanges {
    param($cfgParams);

    $commitMessage = [datetime]::Now.ToString('MM/dd/yyyy') + ' Auto Commit';

    $status = (git status 2>&1) -join "`n";

    if ($status -notmatch 'nothing to commit') { 
        git checkout staging;

        if ($error[0] -match 'Aborting') {
            alert $error[0] '340b Cfg AutoCommit Failed!' $cfgParams;
            Write-Host 'Caught!';
            exit;
        }

        git add ./;
        $status = git status;
        $status = $status -replace "`n", "`r`n";
        git commit -m $commitMessage;

        $output = (git push 2>&1) -join "`n";
        

        if ($output -match 'error:') {
            alert ($output.Exception.Message -join "`n") '340b Cfg AutoCommit Failed!' $cfgParams;
        }
        else  {
            alert $status '340b Cfg AutoCommit Successful!' $cfgParams;
        }
    }   
}

function alert {
    param(
         [string]$message
        ,[string]$subject
        ,$cfgParams

    );

    $dateTime   = [DateTime]::Now;
    $toMail     = 'cgamble@psg340b.com';
    #$toMail     = 'PSG340BTechOps@psg340b.com';
    $fromMail   = 'amonitor@psgconsults.com';
    $smtp       = 'smtp.office365.com'
    $logMessage = '';
  
    $secPassWord = Get-Content $cfgParams.passFile | ConvertTo-SecureString
    $creds       = New-Object System.Management.Automation.PSCredential($fromMail, $secPassWord);
    
    try {
        Send-MailMessage `
            -To $toMail `
            -From $fromMail `
            -Subject $subject `
            -Body $message `
            -SmtpServer $smtp `
            -Credential $creds `
            -UseSsl `
            -Port 587 `
            -ErrorAction Stop;       
    }
    catch {
        "{0} : Failed to send email alert to {1} with exception:{2}`n" -f $dateTime, $toMail, $_.Exception.Message | Out-File -FilePath $cfgParams.alertLog -Encoding ascii -Append;
    }

}

function checkFiles {
    param($cfgParams);

    Get-ChildItem $cfgParams.localRepo -Recurse | ?{ -not $_.PSIsContainer }|%{
        $remotePath = '';
        
        if ($_.FullName -match $cfgParams.regEx) {
            $remotePath = '\\' + $matches[1];

            if (-not (Test-Path $remotePath)) {
                Remove-Item $_.FullName;
            }
            elseif (compareFiles $_.FullName $remotePath) {
                $checkInList += $remotePath;
                Copy-Item -Path $remotePath -Destination $_.FullName;
            }
        }
    }
}

############
#Main Block#
############
$localRepo  = 'C:\users\PSG340B_EDISVC\PSG340B_EDISVC_Configs\cfgFiles\';
$cfgParams  = @{
    'localRepo' = $localRepo;
    'regEx'     = [System.Text.RegularExpressions.Regex]::Escape($localRepo) + '(.+)$';
    'alertLog'  = 'D:\ScriptLogs\autoCheckInAlertLog';
    'passFile'  = 'D:\ScriptCfg\EDISVCsmtpPass';

}

Set-Location $cfgParams.localRepo;

checkFiles $cfgParams;

checkInChanges $cfgParams;


<#
TO DO:
    1 - Add runlog to script
         - record each run
         - record what it found (if anything)
#>

