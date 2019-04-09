#!/usr/bin/perl
#Backuppc Monitor
#Elly 2014-01-23

use 5.010;
use strict;
use warnings;
use Time::Piece;

use lib "/usr/share/backuppc/lib";
use BackupPC::Lib;
use Data::Dumper;
no utf8;

my @cmd = ("status","hosts");

die("BackupPC::Lib->new failed\n") if ( !(my $bpc = BackupPC::Lib->new) );
#my $TopDir = $bpc->TopDir();
#my $BinDir = $bpc->BinDir();
my %Conf = $bpc->Conf();

$bpc->ChildInit();

my $err = $bpc->ServerConnect($Conf{ServerHost}, $Conf{ServerPort});
if ( $err ) {
        print $err;
        exit(1);
}

my $reply = $bpc->ServerMesg(join(" ", @cmd));

my %Status = ("dummy" => {"data1" => "data2"});

#say scalar(%Status);
eval $reply;
#say scalar(%Status);

# From backuppc, we only care about last successful backup.

#Set up current date & time
my $now = localtime;
my $warn = 3;
my $crit = 4;

# Loop through the servers
foreach my $k1 (keys %Status){
        # Only look for last good backup time
        if ($Status{$k1}{"lastGoodBackupTime"}) {
                # Format last good backup time 
                my $lgb =  localtime($Status{$k1}{"lastGoodBackupTime"});
                # Calculate days between now and then
                my $diff = ($now - $lgb)->days;
                my $nag = 3;
                my $nice = "";

                #Determin Warn/Crit level
                if ($diff < $warn) {
                        $nag = 0;
                        $nice = "OK";
                } elsif ($diff < $crit) {
                        $nag = 1;
                        $nice = "WARN";
                } elsif ($diff >= $crit) {
                        $nag = 2;
                        $nice = "CRIT";
                }

                #Print Warn/Crit level
                print $nag." ";
                #Print the server name
                print "backup-$k1 ";

                print "age=";
                #Print number of days since last backup
                printf("%.0f", $diff);
                #Print warn & crit values
                print(";$warn;$crit ");

                #Print nice output
                print "$nice - Last backup was ";
                printf("%.0f", $diff);
                print " days ago.";
                print "\n";
        }
}
