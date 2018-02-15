function readCfg {
    param(
         [string]$cfgFile
        ,[ref]   $copyList
    );

    Get-Content -Path $cfgFile | ?{ $_ -notmatch '^\s*#'} | %{
        ($sourceFile, $destFile) = $_ -split '\s*:\s*';
        
        $copyList.Value += New-Object -TypeName psobject -Property @{
            'sourceFile' = $sourceFile;
            'destFile'   = $destFile;
        }
    }

    return 1;
}

function confirmCopies {
    param([ref]$copyList);

    #First make sure all your deploy files exist
    $missingFile = 0
    foreach ($copy in $copyList.Value) {   
        if ( -not (Test-Path $copy.sourceFile) ) {
            Write-Host ("Missing File: {0}" -f $copy.sourceFile);
            $missingFile = 1;
        }
    }
    if ($missingFile) { exit }


    #IF all files are present prompt the user to review the copies that are about to happen
    $caption  = 'Review File Copies';
    $message  = "Carefully review the  file copies listed in your terminal and confirm their accuracy`n";
    
    $copyList.Value | ft -AutoSiz
    
    $options  = [System.Management.Automation.Host.ChoiceDescription[]] @('Proceed', 'Halt');

    if ( $host.UI.PromptForChoice($caption, $message, $options, 1) ) {
        exit
    }

    return 1;
}

function copyFiles {
    param([ref]$copyList);
    
    foreach ($copy in $copyList.Value) {
        Copy-Item -Path $copy.sourceFile -Destination $copy.destFile;
    }
}

############
#Main Block#
############
$cfgFile  = 'C:\users\cgamble\Documents\Code\PSGScripts\DeployScripts\22400\deploy.cfg';
$copyList = @();

readCfg       $cfgFile ([ref]$copyList);
confirmCopies ([ref]$copyList);
#copyFiles     ([ref]$copyList);