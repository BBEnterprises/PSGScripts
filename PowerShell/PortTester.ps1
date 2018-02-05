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
  catch {
    write-host "`tUnknown!";
    write-host $_.Exception.Message
  }
}
#######################
#Main Block Below Here#
#######################
$computers = @(
    ,'mem-pr-ap-52'
    ,'mem-pr-ap-56'
    ,'mem-pr-ap-58'
    ,'chi-pr-ap-51'
    ,'chi-pr-ap-53'
    ,'chi-pr-ap-57'
);

$remoteHosts = @(
  '192.60.73.1'
);

$remotePorts = @(
    '6218'
);


foreach ($computer in $computers) {
  foreach ($remoteHost in $remoteHosts) {
    foreach ($remotePort in $remotePorts) {
      testConnection $computer $remoteHost $remotePort;
    }
  }
}