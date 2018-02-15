function checkDirectories {
    param($dirList);

    foreach ($directory in $dirList) {
        $directory.newDir = $directory.newDir -replace 'E:\\', '\\hss-prod-svc01\'
        
        #Write-Host $directory.newDir;

        if ($directory.newDir -and -not (Test-Path -Path $directory.newDir)) {
            #'"{0}","{1}","{2}"' -f $directory.newDir, $directory.origLine, $directory.fileName | Out-File -FilePath C:\temp\temp.txt -Encoding ascii -Append
            Write-Host ('"{0}","{1}","{2}"' -f $directory.newDir, $directory.origLine, $directory.fileName);
        }
    }


}

function checkCfg {
    param($cfgFile);

    $keyList = @(
        '_InputDir'
        ,'_WorkingLocation" value="(.+)"'
        ,'_OutputLocation" value="(.+)"'
        ,'_BackupLocation" value="(.+)"'
        ,'_ExceptionLocation" value="(.+)"'
        ,'Output_.+_Folder" value="(.+)"'
    );

    $dirList = @();

    $cfgFile | Get-Content | %{
        foreach ($regEx in $keyList) {
            if ($_ -match $regEx) {
                $dirList += New-Object -TypeName PSObject -Property @{
                    'origLine' = $_;
                    'newDir'   = $matches[1]
                    'fileName' = $cfgFile.FullName;
                };
            }
        }
    }

    $dirList = $dirList | Sort-Object -Property 'newDir' -Unique
    

    checkDirectories $dirList;
}

############
#Main Block#
############

Get-ChildItem -Path '\\psg-file01\Shared\Public\EDIMultiThreading\Deployment\22400\deploy\svc01\' | ?{ $_.Name -notmatch '^prod' } | %{
    $_ | Get-ChildItem -Recurse | ?{ $_.Name -match '\.cfg$' -and ($_.Name -match 'fff' -or $_.Name -match 'hcpharm' -or $_.Name -match 'hdsmith' -or $_.Name -match 'kindray') } | %{
        checkCfg $_;
    }
}