#!perl -w
# perl bestmove.pl --multipv --log=... --hash=5000 "nodes 10000000" e2e4
use Expect;
use strict;
use Getopt::Long;
&main;

sub main {
    $::command = 'stockfish';
    GetOptions('engine=s' => \$::command,
               'threads=i' => \$::threads,
               'verbose'=>\$::verbose,
               'log=s'=>\$::logfile,
               'multipv'=>\$::multipv,
               'hash=i'=>\$::hashsize
        );
    die unless @ARGV>0;
    my$timethink=shift@ARGV;
    #print $timethink;
    my$list='';
    for(@ARGV){
        die unless /^\S+$/;
        $list.=" $_";
    }
    #print $list;
    print &engine($list,$timethink),"\n";
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
    $::exp->expect(15, ("\r\n")) or die;
    $::exp->send("uci\r");
    $::exp->expect(5,("uciok\r\n")) or die;
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
    $::exp->send("isready\r");
    #weirdly, stockfish occasionally dies here
    $::exp->expect(undef,("readyok\r\n")) or die;
    $::exp->send("ucinewgame\risready\r");
    $::exp->expect(undef,("readyok\r\n")) or die;
}

sub engine {
    my $movelist1=shift;
    my $timethink=shift;

    &start_engine;
    #$::exp->send("ucinewgame\r");  #should do readyok after this
    $::exp->send("position startpos moves$movelist1\rd\reval\risready\r");
    $::exp->expect(undef,("readyok\r\n")) or die;
    $::exp->send("go $timethink\r");
    my $successfully_matching_string;
    my %running;
    my %completed;
    my $depth;
    for(;;){
        #($matched_pattern_position, $error, $successfully_matching_string, $before_match,       $after_match);
        #the ordering of the expect clauses matter.
        # sometimes the event loop sees the sum of two lines at once.
        # in which case, $after cycles to $current in the next cycle
        my@expect_result=$::exp->expect(undef,("-re",'info .*?\n',"-re",'^bestmove.*?\n')) or die;
        #loop on all the info output to avoid filling the buffer
        $successfully_matching_string=$expect_result[2];
        #print STDERR "gotsms $successfully_matching_string\n";
        #print "($expect_result[0],error,$expect_result[2],$expect_result[3],$expect_result[4])\n";
        if($successfully_matching_string =~ /^info depth (?<depth>\d+) seldepth \d+ multipv (?<multipv>\d+) score (?<score>.+) nodes (?<nodes>\d+) nps \d+ (?:hashfull \d+ )?tbhits \d+ time \d+ pv (?<pv>\S+)/){
            #$running{$+{multipv}}="$+{pv} and $+{depth} $+{score}";
            $running{$+{multipv}}=$+{pv};
            $depth=$+{depth};
            #$nodes=$+{nodes};
            #print "found pv $+{depth} $+{pv} ",scalar(%running);
        }
        elsif ($successfully_matching_string =~ /^info depth (?<depth>\d+) currmove .+ currmovenumber (?<num>\d+)/){
            my $num=$+{num};
            my $new=$+{depth};
            if($num==1 and %running){
                #sometimes the 1 appears twice
                die unless $depth==($new-1);
                #$cdepth=$depth;
                %completed=%running;
                undef%running;
                #for(sort {$a<=>$b} keys %completed){ print"$_ $completed{$_}"; "reset $new";
            }
        }elsif ($successfully_matching_string =~ /^info nodes \d+ time \d+/){
            # this happens once just at the end
        }elsif ($successfully_matching_string eq "info depth 0 score mate 0\r\n") {
            #when you give it a mate position
        }else {
            #print "last $successfully_matching_string";
            die unless $successfully_matching_string =~ /^bestmove/;
            last
        }
    }
    die unless $successfully_matching_string=~/^bestmove (\S+)/;
    my $computermove=$1;
    $::exp->send("quit\r");
    $::exp->expect(undef);
    if($::multipv){
        #print "got here\n";
        if(defined$completed{1}){
            $computermove=$completed{1}
        } else {
            die unless $computermove eq '(none)'
        }
    }
    $computermove;
}
