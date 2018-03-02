function readCfg {
    param(
         [string]$cfgFile
        ,[ref]   $actionList
    );

    Get-Content -Path $cfgFile | ?{ $_ -notmatch '^\s*#'} | %{
        ($action, $col1, $col2, $col3, $col4) = $_ -split '\s*:\s*';
        
        $actionList.Value += New-Object -TypeName psobject -Property @{
            'actionType' = $action;
            'col1'       = $col1;
            'col2'       = $col2;
            'col3'       = $col3;
            'col4'       = $col4;
        }
    }
}

function confirmActions {
    param([ref]$actionList);

    $actionTypes = @{
        'copy'   = $function:checkCopy;
        'rename' = $function:checkFile;
        'delete' = $function:checkFile;
        'setSvc' = $function:checkSvc;
    }

    $problemFound = 0;

    foreach ($action in $actionList.Value) {
        if(& $actionTypes.($action.actionType) $action) {
            $problemFound = 1;
        }
    }
    if ($problemFound) { exit }

    #IF all files are present prompt the user to review the copies that are about to happen
    $caption  = 'Review File Actions';
    $message  = "Carefully review the  actions listed in your terminal and confirm their accuracy`n";
    
    $actionList.Value | select actionType, col1, col2, col3, col4 | ft -AutoSize
    
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

    try {
        Get-Service -ComputerName $action.col1 -Name $action.col2 | %{
            $_ | Set-Service -Status $action.col3 -StartupType $action.col4;
        }
        Write-Host ("Stopping Service: {0} - {1}" -f $action.col1, $action.col2);
    }
    catch {
        Write-Host ("SVC STOP ERROR: {0} - {1}" -f $action.col1, $action.col2);
        Write-Host $_.Exception.Message;
    }
}

function checkCopy {
    param($action);

    $missingFile = 0;
    if ( -not (Test-Path $action.col1) ) {
        Write-Host ("Missing copy source file: {0}" -f $action.col1);
        $missingFile = 1;
    }

    $destDir = '';
    if ($action.col2 -match '^(.+\\)[^\\]+$') {
        $destDir = $matches[1];
    }

    if ( -not (Test-Path $destDir) ) {
        Write-Host ("Missing copy dest dir: {0}" -f $action.col2);
        $missingFile = 1;
    }

    if ($missingFile) {
        return 1;
    }

    return 0;
}

function checkFile {
    param($action);

    if (-not (Test-Path $action.col1) ) {
        Write-Host ("Missing file for action {0}: {1}" -f $action.actionType, $action.col1);
        return 1;
    }

    return 0;
}

function checkSvc {
    param($action);

    if (-not (Get-Service -ComputerName $action.col1 -Name $action.col2 -ErrorAction SilentlyContinue) ) {
        Write-Host ("Missing service: {0} - {1}" -f $action.col1, $action.col2);
        return 1;
    }

    return 0;
}
############
#Main Block#
############
$cfgFile  = 'C:\Users\cgamble\Documents\Code\PSGScripts\DeployScripts\22759\deploy.cfg';
#$cfgFile  = 'C:\users\cgamble\Documents\Code\PSGScripts\DeployScripts\TestDeploy\deploy.cfg';
$actionList = @();

readCfg        $cfgFile ([ref]$actionList);
confirmActions ([ref]$actionList);
runActions     ([ref]$actionList);

<#
TO DO:

#>