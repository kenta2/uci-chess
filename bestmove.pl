#!perl -w
# perl bestmove.pl --multipv --log=... --hash=5000 "nodes 10000000" startpos moves e2e4
use Expect;
use strict;
use Getopt::Long;
&main;

sub main {
    $::command = 'stockfish';
    $::TIMEOUT = 99;
    GetOptions('engine=s' => \$::command,
               'threads=i' => \$::threads,
               'verbose'=>\$::verbose,
               'log=s'=>\$::logfile,
               'multipv'=>\$::multipv,
               'chess960'=>\$::chess960,
               'hash=i'=>\$::hashsize
        );
    die unless @ARGV>0;
    my$timethink=shift@ARGV;
    #print $timethink;
    my$list = join ' ',@ARGV;
    unshift @ARGV,'--chess960' if $::chess960;
    #validate
    die $list if system('perl','moves-to-fen-stockfish.pl',@ARGV);
    #print $list;
    my$answer=&engine($list,$timethink);
    print "$answer\n";
}

sub start_engine {
    $::exp=Expect -> spawn($::command)
        or die;
    unless($::verbose){
        $::exp->log_stdout(0);
    }
    if($::logfile){
        $::exp->log_file($::logfile);
    }
    #getting these line endings wrong results in very confusing behavior
    #the line endings also depend on the -l switch to perl
    $::exp->expect($::TIMEOUT, ("\r\n")) or die;
    $::exp->send("uci\r");
    $::exp->expect($::TIMEOUT,("uciok\r\n")) or die;
    if($::threads){
        $::exp->send("setoption name Threads value $::threads\r");
    }
    if($::hashsize){
        $::exp->send("setoption name Hash value $::hashsize\r");
    }
    $::exp->send("setoption name Clear Hash\r");
    if($::multipv){
        $::exp->send("setoption name MultiPV value 400\r");
    }
    if($::chess960){
        $::exp->send("setoption name UCI_Chess960 value true\r");
    }
    $::exp->send("isready\r");
    #weirdly, stockfish occasionally dies here
    $::exp->expect($::TIMEOUT,("readyok\r\n")) or die;
    $::exp->send("ucinewgame\risready\r");
    $::exp->expect($::TIMEOUT,("readyok\r\n")) or die;
}

sub engine {
    my $movelist1=shift;
    my $timethink=shift;

    &start_engine;
    $::exp->send("position $movelist1\rd\reval\risready\r");
    $::exp->expect($::TIMEOUT,("readyok\r\n")) or die$movelist1;
    $::exp->send("go $timethink\r");
    my $successfully_matching_string;
    my%seen;
    my $largest=0;
    my $deepest=0;
    my $maxnodes=0;
    my%scores;
    for(;;){
        #($matched_pattern_position, $error, $successfully_matching_string, $before_match,       $after_match);
        #the ordering of the expect clauses matter.
        # sometimes the event loop sees the sum of two lines at once.
        # in which case, $after cycles to $current in the next cycle
        my@expect_result=$::exp->expect(undef,("-re",'info .*?\n',"-re",'^bestmove.*?\n')) or die $movelist1;
        #loop on all the info output to avoid filling the buffer
        $successfully_matching_string=$expect_result[2];
        #print STDERR "gotsms $successfully_matching_string\n";
        #print "($expect_result[0],error,$expect_result[2],$expect_result[3],$expect_result[4])\n";
        my($depth,$multipv,$score,$nodes,$pv);
        if(($depth,$multipv,$score,$nodes,$pv)=($successfully_matching_string =~ /^info depth (\d+) seldepth \d+ multipv (\d+) score (.+) nodes (\d+) nps \d+ (?:hashfull \d+ )?tbhits \d+ time \d+ pv (\S+)/)){
            if($multipv>$largest){
                $largest=$multipv;
            }
            if($depth>$deepest){
                $deepest=$depth;
            }
            #do we care if $score =~ /(lower|upper)bound/ ?
            $seen{"$depth $multipv"}=$pv;
            $scores{"$depth $multipv"}=$score;
            # could also store score
            die$movelist1 if $nodes<$maxnodes;
            $maxnodes=$nodes;
        }
        elsif (($depth,$multipv)=($successfully_matching_string=~/^info depth (\d+) currmove .+ currmovenumber (\d+)/)){
            if($multipv>$largest){
                $largest=$1;
            }
            if($depth>$deepest){
                $deepest=$depth;
            }
        }elsif (($nodes)=($successfully_matching_string =~ /^info nodes \d+ time \d+/)){
            # this happens once just at the end
            die$movelist1 if $nodes<$maxnodes;
            $maxnodes=$nodes;
        }elsif ($successfully_matching_string eq "info depth 0 score mate 0\r\n") {
            #when you give it a mate position
        }elsif ($successfully_matching_string =~ /^info depth 0 score cpx? 0/) {
            #stalemate position
        }elsif ($successfully_matching_string =~ /^bestmove/){
            last;
        }else {
            die "bad line $successfully_matching_string,$movelist1";
        }
    }
    die$movelist1 unless $successfully_matching_string=~/^bestmove (\S+)/;
    my $computermove=$1;
    $::exp->send("quit\r");
    $::exp->expect(undef); #not sure if the actually accomplishes waiting for the process to die, and how long it will wait
    if($::multipv){
        #we do not trust the "bestmove" output with multipv.
        #Instead, explicitly choose the highest ranked move of the last completed depth.
        if ($largest>0){
            unless(defined$seen{"$deepest $largest"}){
                $deepest--;
                #incomplete final depth
            }
            die$movelist1 unless $deepest>0;
            die$movelist1 unless defined $seen{"$deepest $largest"};
            die$movelist1 unless defined $seen{"$deepest 1"};
            $computermove=$seen{"$deepest 1"};
            if($::verbose){
                print"verbose deepest $deepest largest $largest score ",$scores{"$deepest 1"}," maxnodes $maxnodes\n";
            }

        } else {
            die$movelist1 unless $computermove eq '(none)'
        }
    }
    $computermove;
}
