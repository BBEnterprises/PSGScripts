$computers = @(
'mem-pr-ap-20',
'mem-pr-ap-32',
'mem-pr-ap-50',
'mem-pr-ap-52',
'mem-pr-ap-54',
'mem-pr-ap-56',
'mem-pr-ap-58',
'chi-pr-ap-51',
'chi-pr-ap-53',
'chi-pr-ap-55',
'chi-pr-ap-57',
'chi-pr-ap-19'
);

$results = @();
foreach ($computer in $computers) {
    
    $ips = [System.Net.Dns]::GetHostAddresses($computer).IPAddressToString;
    foreach ($ip in $ips) {
      $results += New-Object -TypeName psobject -Property @{ hostName=$computer; IP=$ip};
    }
}

$results | ft -Property hostName,IP -AutoSize
