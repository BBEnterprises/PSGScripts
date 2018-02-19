function checkDirectories {
    param($dirList);

    foreach ($directory in $dirList) {
        $directory.newDir = $directory.newDir -replace 'E:\\', '\\hss-prod-svc01\'
        
        #Write-Host $directory.newDir;

        if ($directory.newDir -and -not (Test-Path -Path $directory.newDir)) {
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
        ,'Input_.+_InputDir value="(.+)"'
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
$clientConfigs = @(
    'fff.cfg'
    ,'hcpharm.cfg'
    ,'hdsmith.cfg'
    ,'kindray.cfg'
);

Get-ChildItem -Path '\\psg-file01\Shared\Public\EDIMultiThreading\Deployment\22400\deploy\svc01\' | ?{ $_.Name -notmatch '^prod' } | %{
    $_ | Get-ChildItem -Recurse | ?{ $_.Name -match '\.cfg$' -and $clientConfigs.Contains($_.Name) } | %{
        checkCfg $_;
    }
}