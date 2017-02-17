#! perl -lw
# standalone parser of a log of a multipv run.
# not used in any pipeline.
$found=0;
while(<>){
    if(/^info depth/){
        $found=1;
        last
    }
}
die unless$found;
#this discards first item, but whatever.
$largest=0;
$deepest=0;
$maxnodes=0;
while(<>){
    #chomp;
    s/\r?\n//;
    #print "a $_";
    if(($depth,$multipv,$score,$nodes,$pv)=/^info depth (\d+) seldepth \d+ multipv (\d+) score (.+) nodes (\d+) nps \d+ (?:hashfull \d+ )?tbhits \d+ time \d+ pv (\S+)/){
        if($multipv>$largest){
            $largest=$multipv;
        }
        if($depth>$deepest){
            $deepest=$depth;
        }
        $seen{"$depth $multipv"}="$pv $score";
        die if $nodes<$maxnodes;
        $maxnodes=$nodes;
    }
    elsif (($depth,$multipv)=/^info depth (\d+) currmove .+ currmovenumber (\d+)$/){
        if($multipv>$largest){
            $largest=$1;
        }
        if($depth>$deepest){
            $deepest=$depth;
        }
    }elsif(/^info nodes (\d+) time \d+$/){
        $nodes=$1;
        $maxnodes=$nodes;;
    }elsif(/^bestmove/){
        print "loop exit via $_";
        last;
    }else{
        die;
    }
}
unless(defined$seen{"$deepest $largest"}){
    $deepest--;
    print "incomplete final depth";
}
die unless defined $seen{"$deepest $largest"};
die unless defined $seen{"$deepest 1"};
print "bestmove ",$seen{"$deepest 1"}," completed_depth $deepest maxnodes $maxnodes nummoves $largest";
