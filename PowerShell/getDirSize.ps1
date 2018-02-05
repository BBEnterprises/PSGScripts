param($rootDir, $outFile)

function getDirSize ($curDir) {
  [long]$curDirSize = 0;
  Get-ChildItem $curDir | %{
    if ( $_.PSIsContainer ) {
      [long]$chdDirSize = getDirSize $_.FullName;
      $curDirSize      += $chdDirSize;
    }
    else {
      $curDirSize += $_.length;
    }
  }
  
  $readableSize = getReadable $curDirSize;
  '{0,-9} | {1} ' -f $readableSize, $_.FullName | Out-File $outFile -append -encoding ASCII;
  return $curDirSize;
}

function getReadable ([long]$size) {
  switch ($size) {
    {$_ -gt 1tb }
      { return "{0,-6:n2} TB" -f ($_ / 1tb) }
    {$_ -gt 1gb }
      { return "{0,-6:n2} GB" -f ($_ / 1gb) }
    {$_ -gt 1mb }
      { return "{0,-6:n2} MB" -f ($_ / 1mb) }
    {$_ -gt 1kb }
      { return "{0,-6:n2} KB" -f ($_ / 1kb) }
    default
      { return "{0,-6} B" -f $_ }
  }
}
#######################
#Main Block Below Here#
#######################
$rootDir = 'C:\Documents';
$outFile = 'C:\temp\getDirSize.log';
if (! $rootDir) {
  Write-Host 'Provide directory as first arg!';
  exit;
}
if (! $outFile ) {
  Write-Host 'Provide output file as second arg!';
  exit;
}
getDirSize $rootDir;