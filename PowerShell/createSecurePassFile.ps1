$secString = '' | ConvertTo-SecureString -AsPlainText -Force;
$secString | ConvertFrom-SecureString | Out-File -FilePath D:\ScriptCfg\smtpPass
