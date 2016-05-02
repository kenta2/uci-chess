#! perl -wl
# Find nodes that were specified as part of an opening book, and not found by calculation.
use strict;
die unless defined(my$dir=$ARGV[0]);
die unless -d $dir;
my@logs;
for(<$dir/*.log>){
    push @logs,$_;
}
my%seen;
my%parent;
my%store_moves;
for(my$i=0;$i<@logs;++$i){
    my$fn=$logs[$i];
    my$canonical=&make_canonical($fn);
    print"$i $canonical";
    if(defined$seen{canonical}){
        print STDERR "duplicate $fn $seen{$fn}";
        next;
    }
    $seen{$canonical}=$fn;
    open FI,$fn or die "cannot open $fn";
    my$moves;
    die if defined$moves;  #assuming undefined per scope

    while(<FI>){
        chomp;
        $moves=$1 if /^position startpos moves\s*(.*)/;
    }
    close FI;
    die unless defined($moves);
    $store_moves{$canonical}=$moves;
    open FI,"$dir/$canonical" or die;
    my$bestmove;
    die if defined($bestmove);
    while(<FI>){
        next if /bestmove\s+\(none\)/;
        $bestmove=$1 if /bestmove\s+(\S+)/;
    }
    close FI;
    unless(defined$bestmove){
        print "skipping $canonical";
    }else{
        #this call is slow
        my$child=`perl moves-to-fen.pl --fen $moves $bestmove`;
        die unless $child;
        $parent{$child}.=" $child";
    }
}
for my$fn(sort@logs){
    my$canonical=&make_canonical($fn);
    unless(defined$parent{$canonical}){
        print"$store_moves{$canonical} = $canonical";
    }
}
sub make_canonical{
    my$canonical=shift;
    $canonical=~s/\.\d+\.log//;
    $canonical=~s!.*/!!;
    $canonical
}
