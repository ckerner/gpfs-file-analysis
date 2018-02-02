#!/usr/bin/env perl
#===============================================================================
# Program: user_usage_analysis.pl
#  Author: Chad Kerner, Senior Storage Engineer
#          Storage Enabling Technologies
#          National Center for Supercomputing Applications
#  E-Mail: ckerner@illinois.edu
#-------------------------------------------------------------------------------
# This utility uses the IBM Spectrum Scale quota engine to generate a report
# about how many files / bytes a user is using in the specified file sets.
#===============================================================================

use Data::Dumper;

$verbose = 0;

if( scalar(@ARGV) < 2 ) {
    print "\n";
    print "  Usage: user_usage_analysis.pl <GPFS Device> FSET1 FSET2 ....\n";
    print "\n";
    print "  Example: user_usage_analysis.pl fs0 home scratch\n";
    print "\n";
    exit 1;
}
else {
    $gpfsdev = $ARGV[0]; shift @ARGV;
    @fsets = @ARGV;
}

sub get_fset_path($$) {
    $dev = $_[0];
    $fset = $_[1];

    open(INFSET, "/usr/lpp/mmfs/bin/mmlsfileset $dev $fset |") || die("Unable to execute: /usr/lpp/mmfs/bin/mmlsfileset $dev $fset: $!\n");
    NXTFSET: while(<INFSET>) {
       chomp;
       s/^\s+//g;
       s/\s+$//g;
       next NXTFSET if m/^$/;
       next NXTFSET if m/^Fileset/;
       next NXTFSET if m/^Name/;
       if( m/$fset\s+\w+\s+(.*)/ ) {
           $fset_path = $1;
       }
  
    }
    close(INFSET);
    return $fset_path;
}

sub addcomma {
    $_ = $_[0];
    if( $_ == 0 ) { return '0'; }
    1 while s/(.*\d)(\d\d\d)/$1,$2/;
    return $_;
}

# Given a GPFS device, find the mount path.
open(INFS, "/usr/lpp/mmfs/bin/mmlsfs $gpfsdev -T |") || die("Unable to execute: /usr/lpp/mmfs/bin/mmlsfs $gpfsdev -T : $!\n");
MMLSFS: while(<INFS>) {
   chomp;
   s/^\s+//g;
   s/\s+$//g;
   next if m/^$/;
   next MMLSFS if ! m/-T/;
   if( m/-T\s+ (.*) \s+.*/ ) { $mount_point = $1; }
}
close(INFS);

if( $verbose ) {
    print "DEV: $gpfsdev\n";
    print "Mount Point: $mount_point\n";
    print "File Sets:\n";
}

# Check to see if the UID list exists. If not, die.
$mount_point =~ s/\s+$//g;
$uid_file = $mount_point . '/.uids';
if( ! -f $uid_file ) {
    die("UID file not found: $uid_file\n");
}

# Read the UIDs into a hash for fast processing.
open(UIDS, "$uid_file");
NXTUID: while(<UIDS>) {
   chomp;
   @ara = split(/:/,$_);
   $uids{$ara[2]}{USER} = $ara[0];
   $uids{$ara[2]}{NAME} = $ara[4];
}
close(UIDS);

foreach $fset ( @fsets ) {
   $path = get_fset_path( $gpfsdev, $fset );
   if( $verbose ) {
       print "   $fset -> $path\n";
   }
   $output = $path . '/USAGE_BY_USER';
   open(OUTFIL, ">$output") || die("Unable to open: $output: $!\n");
   open(QUOTA, "/usr/lpp/mmfs/bin/mmrepquota -u -n --block-size 1g $gpfsdev:$fset |") || die("Unable to execute: /usr/lpp/mmfs/bin/mmrepquota -u --block-size 1g $gpfsdev:$fset : $!\n");
   printf OUTFIL "%-5s  %-10s  %-30s  %-9s  %15s\n", 'UID', 'Username', 'Full Name', 'Usage(GB)', '# Files';
   NXTQ: while(<QUOTA>) {
      chomp;
      s/^\s+//g;
      s/\s+$//g;
      next NXTQ if m/^$/;
      next NXTQ if m/^Block Limits/;
      next NXTQ if m/^Name/;
      next NXTQ if m/^root/;
      @ara = split(/\s+/,$_);
      $uid = $ara[0];
      $usage = $ara[3];
      $files = $ara[9];

      printf OUTFIL "%-5s  %-10s  %-30s  %9s  %15s\n", $uid, $uids{$uid}{USER}, substr($uids{$uid}{NAME},0,30), addcomma($usage), addcomma($files);
   }
   close(QUOTA);
   close(OUTFIL);
}

