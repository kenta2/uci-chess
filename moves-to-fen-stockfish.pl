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
    my($fen,$dolist,$moves,$dostatus,$dofifty);
    GetOptions('engine=s' => \$::command,
               'fen'=>\$fen,
               'list'=>\$dolist,
               'moves'=>\$moves,
               'status'=>\$dostatus,
               'fifty'=>\$dofifty,
        );
    #die unless @ARGV>0;
    my$list='';
    for(@ARGV){
        die unless /^([a-h][1-9]){2}[bnrq]?$/;
        $list.=" $_";
    }
    #print $list;
    my$ans=&engine($list);
    if($fen){
        for($ans->{fen}){
            s/\s+\d+$//; #discard move count
            s/\s+\d+$//; #discard halfmove count for 50-move draw
            s,/,.,g;
            s/ /_/g;
            print "fen $_\n";
        }
    }
    if($dolist){
        # no op;
        print "list";
        print " $_" for @ARGV;
        print"\n";
    }
    if($moves){
        print"moves";
        print " $_" for @{$ans->{moves}};
        print"\n";
    }
    if($dofifty){
        $_=$ans->{fen};
        my($rle,$color,$castle,$enpassant,$fifty,$movecount)=split;
        die unless $color eq 'w' or $color='b';
        die unless $fifty =~ /^\d+$/;
        die unless $movecount =~ /^\d+$/;
        print "fifty $fifty\n";
    }
    if($dostatus){
        if(0==@{$ans->{moves}}){
            if(0==$ans->{ischeck}){
                print"stalemate\n";
            }else{
                die unless 1==$ans->{ischeck};
                print "mate\n";
            }
        }
    }

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
    my%ans;
    #$::exp->send("ucinewgame\r");  #should do readyok after this
    $::exp->send("position startpos moves$movelist1\r");
    $::exp->send("d\r");
    my@expect_result=$::exp->expect(undef,'-re','Fen: .*?\n') or die;
    $ans{fen}=$expect_result[2];
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
    $ans{fen} =~ s/\s*$//;
    $ans{fen} =~ s/^Fen:\s*// or die;
    die unless @moves==$count;

    for($ischeck){
        s/^Checkers://;
    }
    if ($ischeck =~ /\S/) {
        $ans{ischeck}=1;
    } else {
        $ans{ischeck}=0;
    }
    $ans{moves}=\@moves;
    #print "$ans{fen} ";
    #print "ischeck $ans{ischeck} MOVES";
    #for(@moves){
    #    print " $_";
    #}
    #print"\n";
    \%ans;
}
