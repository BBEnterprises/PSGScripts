function readCfg {
    param(
         [string]$cfgFile
        ,[ref]   $actionList
    );

    Get-Content -Path $cfgFile | ?{ $_ -notmatch '^\s*#'} | %{
        ($action, $sourceFile, $destFile) = $_ -split '\s*:\s*';
        
        $actionList.Value += New-Object -TypeName psobject -Property @{
            'sourceFile' = $sourceFile;
            'destFile'   = $destFile;
            'actionType' = $action;
        }
    }

    return 1;
}

function confirmCopies {
    param([ref]$actionList);

    #First make sure all your deploy files exist
    $missingFile = 0
    foreach ($action in $actionList.Value) {   
        if ( -not (Test-Path $action.sourceFile) ) {
            Write-Host ("Missing File: {0}" -f $action.sourceFile);
            $missingFile = 1;
        }
    }
    if ($missingFile) { exit }


    #IF all files are present prompt the user to review the copies that are about to happen
    $caption  = 'Review File Actions';
    $message  = "Carefully review the  actions listed in your terminal and confirm their accuracy`n";
    
    $actionList.Value | select action, sourceFile, destFile | ft -AutoSize
    
    $options  = [System.Management.Automation.Host.ChoiceDescription[]] @('Proceed', 'Halt');

    if ( $host.UI.PromptForChoice($caption, $message, $options, 1) ) {
        exit
    }

    return 1;
}

function runActions {
    param([ref]$actionList);

    $actionTypes = @{
        'copy'   = $function:copyFile;
        'rename' = $function:renameFile;
        'delete' = $function:deleteFile;
    }

    foreach ($action in $actionList.Value) {
        & $actionTypes.($action.actionType) $action;
    }

    return 1;
}

function copyFile {
    param($action);
    

    try {
        Copy-Item -Path $action.sourceFile -Destination $action.destFile -ErrorAction Stop
        Write-Host ("Copying: {0} to {1}" -f $action.sourceFile, $action.destFile);
    }
    catch {
        Write-Host ("COPY ERROR :{0}, {1}" -f $action.sourceFile, $_.Exception.Message);
    }

    return 1;
}

function renameFile {
    param($action);

    try {
        Rename-Item -Path $action.sourceFile -NewName $action.destFile -ErrorAction Stop;
        Write-Host ("Renaming: {0} to {1}" -f $action.sourceFile, $action.destFile);
    }
    catch {
        Write-Host ( "RENAME ERROR: {0} -> {1}" -f $action.sourceFile, $action.destFile);
    }

    return 1;
}

function deleteFile {
    param($action);

    try {
        Remove-Item -Path $action.sourceFile -ErrorAction Stop;
        Write-Host ("Deleting: {0}" -f $action.sourceFile);
    }
    catch {
        Write-Host ("DELETING ERROR: {0}" -f $action.sourceFile);
    }

    return 1;
}

############
#Main Block#
############
$cfgFile  = 'C:\Users\cgamble\Documents\Code\PSGScripts\DeployScripts\22557\deploy.cfg';
#$cfgFile  = 'C:\users\cgamble\Documents\Code\PSGScripts\DeployScripts\TestDeploy\rollback.cfg';
$actionList = @();

readCfg       $cfgFile ([ref]$actionList);
confirmCopies ([ref]$actionList);
runActions    ([ref]$actionList);



<#
TO DO:
1 - Rename and delete functionality
	- Adjust config to have a 'deploy action' column
	- First three actions will be 'rename', 'delete', and 'copy'

2 - Error handling on Copy-Item
	- Wrap Copy-Item in Try-Catch, log any failures
#>