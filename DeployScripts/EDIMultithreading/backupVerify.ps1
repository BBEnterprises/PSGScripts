function readCfg {
    param(
         [string]$cfgFile
        ,[ref]   $copyList
    );

    Get-Content -Path $cfgFile | ?{ $_ -notmatch '^\s*#'} | %{
        ($action, $sourceFile, $destFile) = $_ -split '\s*:\s*';
        
        $copyList.Value += New-Object -TypeName psobject -Property @{
            'sourceFile' = $sourceFile;
            'destFile'   = $destFile;
        }
    }

    return 1;
}

function verifyBackups {
    param([ref]$copyList);

    foreach ($copy in $copyList.Value) {
        
        if ( -not (Test-Path $copy.sourceFile) ) {
            Write-Host ("Missing File: {0}" -f $copy.sourceFile);
        }

        elseif ( -not (Test-Path $copy.destFile) ) {
            Write-Host ("Missing File: {0}" -f $copy.destFile);
        }
        elseif ( compareFiles $copy) {
            Write-Host ("Backup is different: {0} | {1}" -f $copy.sourceFile, $copy.destFile);
        }
    }
}

function compareFiles {
    param($copy);

    return (Compare-Object -ReferenceObject $(Get-Content $copy.sourceFile) -DifferenceObject $(Get-Content $copy.destFile));
}

############
#Main Block#
############
$rollbackCfgFile = 'C:\Users\cgamble\Documents\Code\PSGScripts\DeployScripts\22557\rollback.cfg'
$copyList        = @();

readCfg       $rollbackCfgFile ([ref]$copyList);
verifyBackups ([ref]$copyList);