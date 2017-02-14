#!perl -w

#things needed: is it checkmate or stalemate?
# a way to get them all in long algebraic notation.  easy if you never leave it.
# fen after a giving sequence of moves
# is it fifty move draw?
# somewhat uselessly, we can get the available moves in SAN, though maybe patching can avoid that. seems to be removed? now in the perft 1 command which does not do SAN
# we can also get whether the king is in check via the "Checkers:" line
# perft gives number of moves available, so combined with above, will give us stalemate

use Expect;
use strict;
use Getopt::Long;
&main;

sub main {
    $::command = 'stockfish';
    GetOptions('engine=s' => \$::command,
        );
    #die unless @ARGV>0;
    my$list='';
    for(@ARGV){
        die unless /^\S+$/;
        $list.=" $_";
    }
    #print $list;
    &engine($list);
}

sub start_engine {
    $::exp=Expect -> spawn($::command)
        or die;
    $::exp->log_stdout(0);

    #getting these line endings wrong results in very confusing behavior
    #the line endings also depend on the -l switch to perl
    $::exp->expect(15, ("\r\n")) or die;
    $::exp->send("uci\r");
    $::exp->expect(5,("uciok\r\n")) or die;
    $::exp->send("ucinewgame\risready\r");
    $::exp->expect(undef,("readyok\r\n")) or die;
}

sub engine {
    my $movelist1=shift;

    &start_engine;
    #$::exp->send("ucinewgame\r");  #should do readyok after this
    $::exp->send("position startpos moves$movelist1\r");
    $::exp->send("d\r");
    my@expect_result=$::exp->expect(undef,'-re','Fen: .*?\n') or die;
    my $fen=$expect_result[2];
    @expect_result=$::exp->expect(undef,'-re','Checkers:.*?\n') or die;
    my $ischeck=$expect_result[2];
    $::exp->send("perft 1\r");
    #benchmark.cpp
    $::exp->expect(undef,'Position: 1/1')or die;
    my@moves;
    for(;;){
        @expect_result=$::exp->expect(undef,'-re','\S+?: 1\r\n','-re','={27}.*\n') or die;
        my $item=$expect_result[2];
        if($item =~/(.*): 1/){
            push@moves,$1;
        } elsif($item =~ /^={27}/){
            last;
        } else {
            die;
        }
    }
    @expect_result=$::exp->expect(00,'-re','Nodes searched\s*:\s*\d+\r\n') or die;
    die unless $expect_result[2]=~/Nodes searched\s*:\s*(\d+)/;
    my$count=$1;
    $::exp->expect(undef,'-re','Nodes/second\s*:\s*\d+\s*\r\n') or die;
    $::exp->send("quit\r");
    $::exp->expect(undef);
    $fen =~ s/\s*$//;
    die unless @moves==$count;

    for($ischeck){
        s/^Checkers://;
    }
    if ($ischeck =~ /\S/) {
        $ischeck=1;
    } else {
        $ischeck=0;
    }
    print "$fen ";
    print "ischeck $ischeck MOVES";
    for(@moves){
        print " $_";
    }
    print"\n";
}
