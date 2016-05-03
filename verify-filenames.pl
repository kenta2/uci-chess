#! perl -wl
# Verify that the filename of a log file matches the position evaluated in it.
use strict;
die unless defined(my$dir=$ARGV[0]);
die unless -d $dir;
my@logs;
for my$fn(<$dir/*.log>){
    my$canonical=&make_canonical($fn);
    #print"$i $canonical";
    open FI,$fn or die "cannot open $fn";
    my$moves;
    die if defined$moves;  #assuming undefined per scope

    while(<FI>){
        chomp;
        $moves=$1 if /^position startpos moves\s*(.*)/;
    }
    close FI;
    die unless defined($moves);
    $moves=~s/\s+$//;
    my$fen=`perl moves-to-fen.pl --fen $moves`;
    chomp$fen;
    die unless $fen=~/^fen (\S+)$/;
    $fen=$1;
    print "mismatch $fn" unless $canonical eq $fen;
}
sub make_canonical{
    my$canonical=shift;
    $canonical=~s/\.\d+\.log//;
    $canonical=~s!.*/!!;
    $canonical
}
