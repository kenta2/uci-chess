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
my%store_fen;
for(my$i=0;$i<@logs;++$i){
    my$fn=$logs[$i];
    my$canonical=&make_canonical($fn);
    #print"$i $canonical";
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
    $moves=~s/\s+$//;
    $store_moves{$canonical}=$moves;
    $store_fen{$moves}=$canonical;
}
for my$fn(@logs){
    my$canonical=&make_canonical($fn);
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
        die unless defined(my$moves=$store_moves{$canonical});
        my$query="$moves $bestmove";
        $query =~ s/^ //;
        my$child=$store_fen{"$query"};
        if($child){
            $parent{$child}.=" $child";
        } else {
            $child=`perl moves-to-fen.pl --fen $query`;
            chomp$child;
            die unless $child=~/^fen (\S+)$/;
            $child=$1;
            #print "Cannot find '$query'";
        }
    }
}
for my$fn(sort@logs){
    my$canonical=&make_canonical($fn);
    die unless defined($store_moves{$canonical});
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
