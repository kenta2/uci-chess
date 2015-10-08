#!perl -w
use Chess::Rep;
use Expect;
use strict;
# stalemate, threefold repetition, fifty move rule
$::command = "$ENV{HOME}/bin/stockfish";
$::killswitch = "/tmp/killswitch";
&main;
sub test1 {
    my$rep=Chess::Rep->new;
    print $rep->get_fen;
    for(1..0){
        foreach(qw/Nf3 Nf6 Ng1 Ng8/){
            $rep->go_move($_);
            print $rep->get_fen;
        }
    }
    $rep->go_move('e4');
    print $rep->get_fen;
    $rep->go_move('e5');
    print $rep->get_fen;
    foreach(qw/Nf3 Nf6 Ng1 Ng8/){
        $rep->go_move($_);
        print $rep->get_fen;
    }
}

sub main {
    die unless @ARGV>0;
    my$depth=shift@ARGV;
    #print $depth;
    my$list='';
    for(@ARGV){
        die unless /^\S+$/;
        $list.=" $_";
    }
    #print $list;
    print &engine($list,$depth),"\n";
}

sub start_engine {
    $::exp=Expect -> spawn($::command)
	or die;
    $::exp->log_stdout(0);
    #$::exp->log_file("/tmp/glauxz12.log");
    #getting these line endings wrong results in very confusing behavior
    #the line endings also depend on the -l switch to perl
    $::exp->expect(15, ("Kiiski\r\n")) or die;
    $::exp->send("uci\r");
    $::exp->expect(5,("uciok\r\n")) or die;
    $::exp->send("setoption name Threads value 4\r");
    $::exp->send("setoption name Hash value 900\r");
    $::exp->send("setoption name Clear Hash\r");
#    $::exp->send("setoption name MultiPV value 400\r");
    $::exp->send("isready\r");
    $::exp->expect(undef,("readyok\r\n")) or die;
}

sub engine {
    my $movelist1=shift;
    #print "--$movelist1--\n";
    my $timethink=shift;
    #print "movelist1 $movelist1\n";


    &start_engine;
    #$::exp->send("ucinewgame\r");  #should do readok after this
    $::exp->send("position startpos moves$movelist1\rgo $timethink\r");
    my $successfully_matching_string;
    for(;;){
	if (-e $::killswitch) {
	    unlink $::killswitch;
	    die "killswitch internal";
	}
	#($matched_pattern_position, $error, $successfully_matching_string, $before_match,       $after_match);
        #the ordering of the expect clauses matter.
        # sometimes the event loop sees the sum of two lines at once.
        # in which case, $after cycles to $current in the next cycle
	my@expect_result=$::exp->expect(undef,("-re",'info .*?\n',"-re",'^bestmove.*?\n')) or die;
        #loop on all the info output to avoid filling the buffer
	$successfully_matching_string=$expect_result[2];
	#print STDERR "gotsms $successfully_matching_string\n";
        #print "($expect_result[0],error,$expect_result[2],$expect_result[3],$expect_result[4])\n";
	if ($successfully_matching_string =~ /^info /){

	} else {
            die unless $successfully_matching_string =~ /^bestmove/;
            last
        }
    }
    die unless $successfully_matching_string=~/^bestmove (\S+)/;
    my $computermove=$1;
    #print "$computermove: score $score, pv $pv\n";
    $::exp->send("quit\r");
    $::exp->expect(undef);
    $computermove;
}
