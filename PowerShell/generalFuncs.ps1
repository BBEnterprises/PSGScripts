function Invoke-Sqlcmd2 
{ 
    [CmdletBinding()] 
    param( 
    [Parameter(Position=0, Mandatory=$true)] [string]$ServerInstance, 
    [Parameter(Position=1, Mandatory=$false)] [string]$Database, 
    [Parameter(Position=2, Mandatory=$false)] [string]$Query, 
    [Parameter(Position=3, Mandatory=$false)] [string]$Username, 
    [Parameter(Position=4, Mandatory=$false)] [string]$Password, 
    [Parameter(Position=5, Mandatory=$false)] [Int32]$QueryTimeout=600, 
    [Parameter(Position=6, Mandatory=$false)] [Int32]$ConnectionTimeout=15, 
    [Parameter(Position=7, Mandatory=$false)] [ValidateScript({test-path $_})] [string]$InputFile, 
    [Parameter(Position=8, Mandatory=$false)] [ValidateSet("DataSet", "DataTable", "DataRow")] [string]$As="DataRow",
    [Parameter(Position=9, Mandatory=$false)] [string]$ApplicationName='Powershell'

    ) 
 
    if ($InputFile) 
    { 
        $filePath = $(resolve-path $InputFile).path 
        $Query =  [System.IO.File]::ReadAllText("$filePath") 
    } 
 
    $conn=new-object System.Data.SqlClient.SQLConnection 
      
    if ($Username) 
    { $ConnectionString = "Server={0};Database={1};User ID={2};Password={3};Application Name={5};Trusted_Connection=False;Connect Timeout={4}" -f $ServerInstance,$Database,$Username,$Password,$ConnectionTimeout,$ApplicationName } 
    else 
    { $ConnectionString = "Server={0};Database={1};Integrated Security=True;Application Name={3};Connect Timeout={2}" -f $ServerInstance,$Database,$ConnectionTimeout,$ApplicationName } 
 
    $conn.ConnectionString=$ConnectionString 
     
    #Following EventHandler is used for PRINT and RAISERROR T-SQL statements. Executed when -Verbose parameter specified by caller 
    if ($PSBoundParameters.Verbose) 
    { 
        $conn.FireInfoMessageEventOnUserErrors=$true 
        $handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {Write-Verbose "$($_)"} 
        $conn.add_InfoMessage($handler) 
    } 
     
    $conn.Open() 
    $cmd=new-object system.Data.SqlClient.SqlCommand($Query,$conn) 
    $cmd.CommandTimeout=$QueryTimeout 
    $ds=New-Object system.Data.DataSet 
    $da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd) 
    [void]$da.fill($ds) 
    $conn.Close() 
    switch ($As) 
    { 
        'DataSet'   { Write-Output ($ds) } 
        'DataTable' { Write-Output ($ds.Tables) } 
        'DataRow'   { Write-Output ($ds.Tables[0]) } 
    }
 
}

function slurpCfg ($file) {
  $cfg = '';
  foreach ($line in Get-Content $file) {
    if ($line -match '^#' -or $line -match '^\s+#' -or $line -match '^$') {
      continue;
    }
    $cfg += $line;
  }
  return $cfg;
}

function tailFiles ($computers, $filePath) {
  invoke-command -computername $computers -ArgumentList $filePath {
    param($filePath);
    tail -f $filePath | %{ "$env:computername|$_" }
  }
}

function grepStr ($dir, $string, $fileRegEx) {
  
  Get-ChildItem $dir | foreach-object {
    if ( $_.PSIsContainer ) {
      grepStr $_.FullName $string $fileRegEx;
    }
    elseif ( $fileRegEx ) {
      if ( $_.Name -match $fileRegEx ) {
        readFile $_ $string;
      }
    }
    else {
      readFile $_ $string;
    }
  }
}

function readFile ($file, $string) {
  $content = [IO.File]::ReadAllText($file.FullName);
  
  if ($content -match $string) {
    foreach ($line in $content.split("`n")) {
      if ($line -match $string) {
        $returnString = "{0}`n{1}`n----" -f $file.FullName, $line;
        #Write-Host $file.FullName;
        #Write-Host $line;
        #Write-Host '----';
        return $returnString;
      }
    }
  }
}

function checkForExceptions {
    param(
        $customers
        ,$monthCutOff = 1
    );    

    $cutOffDate = ([DateTime]::Today).AddMonths($monthCutOff * -1);

    $rootDirs   = @(
        '\\HSS-PROD-SVC01\Source_Backup\EXCEPTIONS\',
        '\\HSS-PROD-DB01\Source_Backup\EXCEPTIONS\'
    );

    foreach ($rootDir in $rootDirs) {
        if (-not $customers) {
            Get-ChildItem -LiteralPath $rootDir -Recurse | ?{ -not $_.PSIsContainer -and $_.LastWriteTime -ge $cutOffDate} | %{
                Write-Host $_.FullName
            }
        }

        foreach ($customer in $customers) {
            $directory = $rootDir + $customer + '\';

            Get-ChildItem -LiteralPath $directory -Recurse | ?{ -not $_.PSIsContainer -and $_.LastWriteTime -ge $cutOffDate} | %{
                Write-Host $_.FullName
            }

        }
    }
}