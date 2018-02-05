#!c:\Perl64\bin\perl.exe
use strict;
use warnings;

my $rootDir = 'C:\temp\queueREportLogs';
my $regEx    = qr'^(\d\d:\d\d:\d\d)\| ERROR: A network-related or instance-specific';

opendir my $ROOT, $rootDir
    or die "Could not open $rootDir! $!\n";

while (readdir $ROOT) {
    next if ($_ eq '.' or $_ eq '..');
    readLogFile($rootDir . '\\' . $_);
}
################
#Subs Below Here#
################
sub readLogFile {
    my $logFile = shift;
    my $date;
    
    if ($logFile =~ /(\d{4}-\d\d-\d\d)/) {
        $date = $1;
    }
    
    open my $LOG, '<', $logFile
      or die "Could not open $logFile! $!\n";
      
   while (<$LOG>) {
      my $dateTime;
      if ($_ =~ $regEx) {
          $dateTime = $date . '  ' . $1 . "\n";
          print $dateTime;
      }
      
      

   }
      
   close $LOG;
    
    return 1;
};