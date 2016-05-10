#! perl -lw
# standalone parser of a log of a multipv run.
# not used in any pipeline.

while(<>){
    last if /^info depth/;
}
while(<>){
    #chomp;
    s/\r?\n//;
    if(/^info depth (?<depth>\d+) seldepth \d+ multipv (?<multipv>\d+) score (?<score>.+) nodes (?<nodes>\d+) nps \d+ (?:hashfull \d+ )?tbhits \d+ time \d+ pv (?<pv>\S+)/){
        $running{$+{multipv}}="$+{pv} $+{depth} $+{score}";
        $depth=$+{depth};
        $nodes=$+{nodes}
        #print "found pv $+{depth} $+{pv} ",scalar(%running);
    }
    elsif (/^info depth (?<depth>\d+) currmove .+ currmovenumber (?<num>\d+)$/){
        $num=$+{num};
        $new=$+{depth};
        if($num==1 and %running){
            #sometimes the 1 appears twice
            die unless $depth==($new-1);
            $cdepth=$depth;
            %completed=%running;
            undef%running;
            for(sort {$a<=>$b} keys %completed){
                print"$_ $completed{$_}";
            }
            print "starting depth $new nodes $nodes";
        }
    }elsif(/^info nodes (\d+) time \d+$/){
        $nodes=$1
    }elsif(/^bestmove/){
        print "loop exit via $_";
        last;
    }else{
        print;
    }
}
#for(sort {$a<=>$b} keys %completed){    print"$_ $completed{$_}";}
die unless defined $completed{1};
print "best multipv $completed{1}";
print "completed depth $cdepth";
print "final nodes $nodes";
