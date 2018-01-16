#!/usr/bin/env perl

use Data::Dumper;

if( scalar(@ARGV) != 2 ) {
    print "\n";
    print "  Usage: file_analysis.pl <Analysis Type> <Path To Analyze>\n";
    print "\n";
    print "     Flag    Analysis Type\n";
    print "     -s      Breakdown by File Size\n";
    print "     -c      Breakdown by File Creation Days\n";
    print "     -m      Breakdown by File Modification Days\n";
    print "     -a      Breakdown by File Access Days\n";
    print "     -u      Breakdown by UID\n";
    print "     -g      Breakdown by GID\n";
    print "\n";
    exit 1;
}
else {
   $type = $ARGV[0];
   $analysis_path = $ARGV[1];
}

$PID=$$;;
$work_dir = "/tmp/policy.$PID";
$data_file = "$work_dir/list.all-files";

$onek = 1024;
$onem = 1024 ** 2;
$oneg = 1024 ** 3;

#
# Breakdown of the list.all-files fields.
#
# Field     Usage
# 1         Inode
# 2         Generation Number
# 3         Snapshot Id
# 4         KB Allocated
# 5         File Size
# 6         Creation Time in days from today
# 7         Change Time in days from today
# 8         Modification time in days from today
# 9         Acces time in days from today
# 10        GID
# 11        UID
# 12        Separator
# 13        Fully qualified File Name
#
# 20971520 116723052 0  256 6252 512 512 895 512 16568 48538 -- /gpfs01/iforge/projects/abv/DISCOVERY/ADME/tSNE_Network_Graph/igraph-0.6.5/optional/glpk/glprgr.c
#

$title{-u} = 'Breakdown by UID';
$title{-g} = 'Breakdown by GID';
$title{-s} = 'Breakdown by File Size';
$title{-a} = 'Breakdown by File Access Date';
$title{-m} = 'Breakdown by File Modification Date';
$title{-c} = 'Breakdown by File Creation Date';

sub addcomma {
    $_ = $_[0];
    if( $_ == 0 ) { return '0'; }
    1 while s/(.*\d)(\d\d\d)/$1,$2/;
    return $_;
}

sub print_by_gid {
    open(INFIL,"$data_file") || die("Unable to open file: $data_file $!\n");
    RECORD: while(<INFIL>) {
       chomp;
       @ara=split(/\s+/,$_);
       $hash{$ara[9]}{FILES} = $hash{$ara[9]}{FILES} + 1;
       $hash{$ara[9]}{BYTES} = $hash{$ara[9]}{BYTES} + $ara[4];
    }
    close(INFIL);
    print Dumper \%hash;
}

sub print_by_uid {
    open(INFIL,"$data_file") || die("Unable to open file: $data_file $!\n");
    RECORD: while(<INFIL>) {
       chomp;
       @ara=split(/\s+/,$_);
       $hash{$ara[10]}{FILES} = $hash{$ara[10]}{FILES} + 1;
       $hash{$ara[10]}{BYTES} = $hash{$ara[10]}{BYTES} + $ara[4];
    }
    close(INFIL);
    print Dumper \%hash;
}

sub init_size_buckets {
    $bidx = 0;
    $bucket[$bidx] = 0;            $header[$bibx] = 'Inode';       $bidx++;
    $bucket[$bidx] = 4 * $onek;    $header[$bidx] = '<4K';         $bidx++; 
    $bucket[$bidx] = 64 * $onek;   $header[$bidx] = '4K - 64K';    $bidx++;
    $bucket[$bidx] = 128 * $onek;  $header[$bidx] = '64K - 128K';  $bidx++;
    $bucket[$bidx] = 256 * $onek;  $header[$bidx] = '128K - 256K'; $bidx++;
    $bucket[$bidx] = 512 * $onek;  $header[$bidx] = '256K - 512K'; $bidx++;
    $bucket[$bidx] = 1 * $onem;    $header[$bidx] = '512K - 1M';   $bidx++; 
    $bucket[$bidx] = 2 * $onem;    $header[$bidx] = '1M - 2M';     $bidx++; 
    $bucket[$bidx] = 4 * $onem;    $header[$bidx] = '2M - 4M';     $bidx++; 
    $bucket[$bidx] = 8 * $onem;    $header[$bidx] = '4M - 8M';     $bidx++; 
    $bucket[$bidx] = 16 * $onem;   $header[$bidx] = '8M - 16M';    $bidx++; 
    $bucket[$bidx] = 100 * $onem;  $header[$bidx] = '16M - 100M';  $bidx++; 
    $bucket[$bidx] = 256 * $onem;  $header[$bidx] = '100M - 256M'; $bidx++; 
    $bucket[$bidx] = 512 * $onem;  $header[$bidx] = '256M - 512M'; $bidx++; 
    $bucket[$bidx] = 1 * $oneg;    $header[$bidx] = '512M - 1G';   $bidx++; 
    $bucket[$bidx] = 5 * $oneg;    $header[$bidx] = '1G - 5G';     $bidx++; 
    $header[$bidx] = '>5G';
    $max_buckets = $bidx - 1;
}

sub init_date_buckets {
    $bidx = 0;
    $bucket[$bidx] = 0;            $header[$bidx] = 'Today';             $bidx++;
    $bucket[$bidx] = 7;            $header[$bidx] = '1 - 7 Days';        $bidx++;
    $bucket[$bidx] = 30;           $header[$bidx] = '7 - 30 Days';       $bidx++;
    $bucket[$bidx] = 60;           $header[$bidx] = '30 - 60 Days';      $bidx++;
    $bucket[$bidx] = 90;           $header[$bidx] = '60 - 90 Days';      $bidx++;
    $bucket[$bidx] = 120;          $header[$bidx] = '90 -120 Days';      $bidx++;
    $bucket[$bidx] = 180;          $header[$bidx] = '120 - 180 Days';    $bidx++;
    $bucket[$bidx] = 365;          $header[$bidx] = '180 Days - 1 Year'; $bidx++;
    $bucket[$bidx] = 730;          $header[$bidx] = '1 - 2 Years';       $bidx++;
    $bucket[$bidx] = 1095;         $header[$bidx] = '2 - 3 Years';       $bidx++;
    $bucket[$bidx] = 1460;         $header[$bidx] = '3 - 4 Years';       $bidx++;
    $bucket[$bidx] = 1825;         $header[$bidx] = '4 - 5 Years';       $bidx++;
    $header[$bidx] = '5+ Years';
    $max_buckets = $bidx - 1;
}


sub print_buckets {
    my $type = $_[0];

    if( $type eq '-a' )    { $cutoff = 8; }
    elsif( $type eq '-s' ) { $cutoff = 4; } 
    elsif( $type eq '-c' ) { $cutoff = 5; } 
    elsif( $type eq '-m' ) { $cutoff = 6; } 

    if( $type eq '-s' ) { init_size_buckets(); }
    else                { init_date_buckets(); }

    open(INFIL,"$data_file") || die("Unable to open file: $data_file $!\n");
    RECORD: while(<INFIL>) {
       chomp;
       @ara=split(/\s+/,$_);

       if( $ara[3] == 0 ) {
           $bytes[0] = $bytes[0] + $ara[4];
           $files[0] = $files[0] + 1;
           next RECORD;
       }

       for( $idx=0; $idx <= $max_buckets; $idx++ ) {
          if( $ara[$cutoff] <= $bucket[$idx] ) {
              $bytes[$idx] = $bytes[$idx] + $ara[4];
              $files[$idx] = $files[$idx] + 1;
              $idx = $max_buckets + 1;
          }
       }
       if( $ara[$cutoff] > $bucket[$max_buckets] ) {
           $bytes[$max_buckets+1] = $bytes[$max_buckets+1] + $ara[4];
           $files[$max_buckets+1] = $files[$max_buckets+1] + 1;
       }
    }
    close(INFIL);

    printf("%8s %s\n\n", '', $title{$type});
    if( $type eq '-s' ) {
        printf("%17s \t","Bucket Size");
        printf("%10s \t","# of Files");
        printf("%20s \n","# of Bytes");
    }
    else {
        printf("%17s \t","Bucket Days");
        printf("%10s \t","# of Files");
        printf("%20s \n","# of Bytes");
    }
    for( $idx=0; $idx <= $max_buckets+1; $idx++ ) {
        printf("%17s \t",$header[$idx]);
        printf("%10s \t",addcomma($files[$idx]));
        printf("%20s \n",addcomma($bytes[$idx]));
    }
}

sub setup_work_area() {
    `mkdir $work_dir &>/dev/null`;
    $policy_file = "$work_dir/policy.in";
    $log_file = "$work_dir/policy.out";

    open(POLFILE, ">$policy_file");
    print POLFILE <<"EOPOLICY";

RULE 'listall' list 'all-files'
   SHOW( varchar(kb_allocated) || ' ' ||
         varchar(file_size) || ' ' ||
         varchar( days(current_timestamp) - days(creation_time) ) || ' ' ||
         varchar( days(current_timestamp) - days(change_time) ) || ' ' ||
         varchar( days(current_timestamp) - days(modification_time) ) || ' ' ||
         varchar( days(current_timestamp) - days(access_time) ) || ' ' ||
         varchar(group_id) || ' ' ||
         varchar(user_id) )
   WHERE PATH_NAME like '$analysis_path/%'
EOPOLICY
    close(POLFILE);

    return;
}

# Main Code Block
{
   setup_work_area();

   `/usr/lpp/mmfs/bin/mmapplypolicy $analysis_path -f $work_dir -P $policy_file -I defer &>$log_file 2>&1`;

   if( $type eq '-u' )    { print_by_uid(); }
   elsif( $type eq '-g' ) { print_by_gid(); }
   else                   { print_buckets( $type ); }

   `rm -Rf $work_dir &>/dev/null`;
}
