#!c:\Perl64\bin\perl.exe
use strict;
use warnings;

my @directories = (
    '\\\\hss-prod-db04\PSG_Services\DROS_QueueReport\Logs'
    ,'\\\\HSS-PROD-WEB01\PSG_Services\QueueReport\Logs'
    ,'\\\\hss-prod-web02\Applications\Psg.WebService.OrderIngest\logs'
    ,'\\\\hss-prod-db01\e$\ActivityMonitor\logs'
    ,'\\\\hss-prod-db01\e$\ClaimProcessing\LOGS'
    ,'\\\\hss-prod-db01\e$\EDIInputProcessing\LOGS'
    ,'\\\\hss-prod-db01\e$\EDIInputProcessing_Catalog\LOGS'
    ,'\\\\hss-prod-db01\e$\EncounterProcessing\LOGS'
    ,'\\\\hss-prod-db01\e$\FileLogistics\LOGS'
    ,'\\\\hss-prod-db01\e$\FileLogistics_Catalog\LOGS'
    ,'\\\\hss-prod-db01\e$\OutputProcessing\LOGS'
);
my %errorList;

for my $logDir (@directories) {
    processDir($logDir);
}

recordErrors();

################
#Subs Below Here#
################
sub recordErrors {

    my $format = '"%s","%s"' . "\n";

    open my $LOG, '>>', 'c:\temp\errors.csv'
      or die "Could not open errors.txt! $!\n";

    for my $logDir (keys %errorList) {
       foreach my $string ( sort keys %{ $errorList{$logDir} }) {
            printf $LOG $format, $logDir, $string;
       }
    }
    
    close $LOG;
}

sub processDir {
    my $logDir = shift;
    
    opendir my $DH, $logDir
      or die "Could not open $logDir for reading: $!\n";
    for (readdir $DH) {
        next if $_ eq '.' || $_ eq '..' || $_ !~ /^2018/;
        processFile($logDir . '\\' . $_, $logDir);
    }
    closedir $DH;
    
    return 1;
}

sub processFile {
    my $file = shift;
    my $logDir = shift;
    
    print "Working $file\n";
    
    open my $LOG, '<', $file
      or die "Could not open $file for reading: $!\n";
   while (<$LOG>) {
       if ( $_ =~ /\| ERROR:(.+$)/ ) {
            chomp(my $string = $1);
            $errorList{$logDir}{$string} = 1;
       }
   }
   close $LOG;
   
   return 1;
}