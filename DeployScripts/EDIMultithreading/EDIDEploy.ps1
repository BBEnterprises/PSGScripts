function readCfg {
    param(
         [string]$cfgFile
        ,[ref]   $actionList
    );

    Get-Content -Path $cfgFile | ?{ $_ -notmatch '^\s*#'} | %{
        ($action, $col1, $col2) = $_ -split '\s*:\s*';
        
        $actionList.Value += New-Object -TypeName psobject -Property @{
            'actionType' = $action;
            'col1'       = $col1;
            'col2'       = $col2;
            'col3'       = $col3;
            'col4'       = $col4;
        }
    }
}

function confirmCopies {
    param([ref]$actionList);

    #First make sure all your deploy files exist
    $missingFile = 0
    foreach ($action in $actionList.Value) {   
        #Continue if it's a setSvc since there isn't a file to verify
        if ($action.actionType -eq 'setSvc') {
            continue;
        }

        if ( -not (Test-Path $action.col1) ) {
            Write-Host ("Missing File: {0}" -f $action.col1);
            $missingFile = 1;
        }
    }
    if ($missingFile) { exit }


    #IF all files are present prompt the user to review the copies that are about to happen
    $caption  = 'Review File Actions';
    $message  = "Carefully review the  actions listed in your terminal and confirm their accuracy`n";
    
    $actionList.Value | select action, col1, col2, col3, col4 | ft -AutoSize
    
    $options  = [System.Management.Automation.Host.ChoiceDescription[]] @('Proceed', 'Halt');

    if ( $host.UI.PromptForChoice($caption, $message, $options, 1) ) {
        exit
    }
}

function runActions {
    param([ref]$actionList);

    $actionTypes = @{
        'copy'   = $function:copyFile;
        'rename' = $function:renameFile;
        'delete' = $function:deleteFile;
        'setSvc' = $function:setSvc;
    }

    foreach ($action in $actionList.Value) {
        & $actionTypes.($action.actionType) $action;
    }
}

function copyFile {
    param($action);
    

    try {
        Copy-Item -Path $action.col1 -Destination $action.col2 -ErrorAction Stop
        Write-Host ("Copying: {0} to {1}" -f $action.col1, $action.col2);
    }
    catch {
        Write-Host ("COPY ERROR :{0}, {1}" -f $action.col1, $_.Exception.Message);
    }
}

function renameFile {
    param($action);

    try {
        Rename-Item -Path $action.col1 -NewName $action.col2 -ErrorAction Stop;
        Write-Host ("Renaming: {0} to {1}" -f $action.col1, $action.col2);
    }
    catch {
        Write-Host ( "RENAME ERROR: {0} -> {1}" -f $action.col1, $action.col2);
    }
}

function deleteFile {
    param($action);

    try {
        Remove-Item -Path $action.col1 -ErrorAction Stop;
        Write-Host ("Deleting: {0}" -f $action.col1);
    }
    catch {
        Write-Host ("DELETING ERROR: {0}" -f $action.col1);
    }
}

function setSvc {
    param($action);

    Get-Service -ComputerName $action.col1 -Name $action.col2 | %{
        $_ | Set-Service -Status $action.col3 -StartupType $action.col4;
    }
}

############
#Main Block#
############
$cfgFile  = 'C:\Users\cgamble\Documents\Code\PSGScripts\DeployScripts\22759\deploy.cfg';
#$cfgFile  = 'C:\users\cgamble\Documents\Code\PSGScripts\DeployScripts\TestDeploy\rollback.cfg';
$actionList = @();

readCfg       $cfgFile ([ref]$actionList);
confirmCopies ([ref]$actionList);
runActions    ([ref]$actionList);

<#
TO DO:

#>