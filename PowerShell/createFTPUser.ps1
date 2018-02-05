$userName = '';
$rootDir  = '\\HSS-PROD-DB07\ftp\';

New-Item -Path $rootDir -Name $userName -ItemType Directory;
New-Item -Path ($rootDir + $userName) -Name 'in' -ItemType Directory;
New-Item -Path ($rootDir + $userName) -Name 'out' -ItemType Directory;
New-Item -Path ($rootDir + $userName) -Name 'test' -ItemType Directory;
