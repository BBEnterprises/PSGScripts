$testPortFunc = {
  param($myhost, $myport);
   
  $tcp     = New-Object System.Net.Sockets.TcpClient;
  $connect = $tcp.BeginConnect($myhost, $myport, $null, $null);
  $wait    = $connect.AsyncWaitHandle.WaitOne(5000,$false);
  if (!$Wait) {
    $tcp.close();
    return 0;
  }
  else {
    $error.clear();
    $tcp.EndConnect($connect) | Out-Null;
    $result = 0;
    if ($error[0]) {
      $result = 0;
    }
    else {
      $result = 1;
    };
    $tcp.close();

    return $result;
  }
};

function testConnection ($computer, $remoteHost, $remotePort) {
  Write-Host -NoNewLine $computer ' ' $remoteHost ':' $remotePort;
  try {
    $job = Start-Job -ArgumentList($computer, $remoteHost, $remotePort, $testPortFunc) -ScriptBlock {
        param(
             [string]     $computer
            ,[string]     $remoteHost
            ,[string]     $remotePort
            ,$testPortFunc
        );
        Invoke-Command -ErrorAction Stop -ComputerName $computer -ArgumentList ($remoteHost, $remotePort, $testPortFunc) -ScriptBlock {
          param($remoteHost, $remotePort, $testPortFunc);  
      
          if( & ([scriptblock]::Create($testPortFunc)) -myhost $remoteHost -myport $remotePort ) {
              Write-Host "`tSuccess!";
          }
          else {
              Write-Host "`tFailure!";
          }
        }
    }
    if (-not (Wait-Job -Job $job -Timeout 15) ) {
        $errorMessage = 'Command invocation failed against {0}!' -f $computer;
        Stop-Job   $job;
        Remove-Job $job;
        throw $errorMessage;
    }
    Receive-Job $job;
    Remove-Job  $job;
  }
  catch {
    write-host "`tUnknown!";
    write-host $_.Exception.Message
  }
}
#######################
#Main Block Below Here#
#######################
$computers = @(
    #'HSS-PROD-APP01',
    'HSS-PROD-DB01',
    <#'HSS-PROD-DB02',
    'HSS-PROD-DB03',
    'HSS-PROD-DB04',
    'HSS-PROD-DB05',
    'HSS-PROD-DB06',
    'HSS-PROD-DT01',
    'HSS-PROD-FTP01',
    'HSS-PROD-PWS01',
    'HSS-PROD-SVC01'#>,
    'HSS-PROD-WEB01'
    #'HSS-PROD-WEB02'
);

$remoteHosts = @(
  'HSS-PROD-DB06'
);

$remotePorts = @(
    '5985'
);


foreach ($computer in $computers) {
  foreach ($remoteHost in $remoteHosts) {
    foreach ($remotePort in $remotePorts) {
      testConnection $computer $remoteHost $remotePort;
    }
  }
}