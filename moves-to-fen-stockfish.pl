#!perl -w

#this does calculations via stockfish instead of Chess::Rep.
# good = Chess960
# bad = no SAN

#things needed: is it checkmate or stalemate?
# a way to get them all in long algebraic notation.  easy if you never leave it.
# fen after a giving sequence of moves
# is it fifty move draw?
# somewhat uselessly, we can get the available moves in SAN, though maybe patching can avoid that. seems to be removed? now in the perft 1 command which does not do SAN
# we can also get whether the king is in check via the "Checkers:" line
# perft gives number of moves available, so combined with above, will give us stalemate

# sadly Chess::Rep and Stockfish differ on the en passant square in FEN.
# Chess::Rep always prints the square (agreeing with Wikipedia FWIW)
# Stockfish prints the square only if a capture is actually possible (but probably ignoring pins against the king).
# They differ as quickly as after 1.e2e4

use Expect;
use strict;
use Getopt::Long;
&main;

sub main {
    $::command = 'stockfish';
    $::TIMEOUT = 99;
    my($fen,$dolist,$moves,$dostatus,$dofifty);
    GetOptions('engine=s' => \$::command,
               'fen'=>\$fen,
               'list'=>\$dolist,
               'moves'=>\$moves,
               'status'=>\$dostatus,
               'fifty'=>\$dofifty,
               'verbose'=>\$::verbose,
               'chess960'=>\$::chess960
        );
    my$list;
    unless(@ARGV){
        $list='startpos';
    } else {
        # stockfish parser does not validate much, so we do some validation here.
        $list=shift@ARGV;
        if($list eq 'startpos'){
            die if $::chess960;
            # ready to parse moves
        } elsif($list eq 'fen'){
            # a little bit more powerful than we need.  we need only to parse Chess960 start positions (as done in an old version of bestmove.pl)
            my @F=split '/',$ARGV[0];
            die unless @F==8;
            my$white_kings;
            my$black_kings;
            for(@F){
                die unless &fen_rank_ok($_);
                $white_kings+=&count_char('K',$_);
                $black_kings+=&count_char('k',$_);
            }
            die unless 1==$white_kings;
            die unless 1==$black_kings;
            $list.=' '.shift@ARGV;

            die unless $ARGV[0] =~ /^[wb]$/;
            $list.=' '.shift@ARGV;

            # Shredder-FEN
            die unless $ARGV[0] eq '-' or
                (length$ARGV[0] > 0 and ($ARGV[0] =~ /^[A-H]{0,2}[a-h]{0,2}$/ or $ARGV[0] =~ /^K?Q?k?q?$/));
            die if $::chess960 and $ARGV[0]=~/[kq]/i;
            # other tools (namely bestmove.pl) need to know in advance whether a position is chess960
            die if !$::chess960 and $ARGV[0]=~/[a-h]/i;
            $list.=' '.shift@ARGV;

            die unless $ARGV[0] eq '-' or $ARGV[0] =~ /^[a-h][1-8]$/;
            $list.=' '.shift@ARGV;

            die unless $ARGV[0] =~ /^\d+$/;
            $list.=' '.shift@ARGV;

            die unless $ARGV[0] =~ /^\d+$/;
            $list.=' '.shift@ARGV;
        } else {
            die;
        }
        if(@ARGV){
            die unless $ARGV[0] eq 'moves';
            $list.=' '.shift@ARGV;
        }
        for(@ARGV){
            die unless /^([a-h][1-8]){2}[nbrq]?$/;
            $list.=' '.$_;
        }
    }
    #print "start $list\n";
    my$ans=&engine($list);
    if($fen){
        for($ans->{fen}){
            s/\s+\d+$// or die; #discard move count
            s/\s+\d+$// or die; #discard halfmove count for 50-move draw
            s/\s+\S+$// or die; #discard en passant square
            # this is somewhat of a hack to work around Chess::Rep and Stockfish disagreeing on en passant square in FEN
            s,/,.,g;
            s/ /_/g;
            print "fen $_\n";
        }
    }
    if($dolist){
        #designed for converting SAN
        die;
        # no op;
        #print "list $list\n";
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
    $::exp->log_stdout(0) unless $::verbose;

    #getting these line endings wrong results in very confusing behavior
    #the line endings also depend on the -l switch to perl
    $::exp->expect($::TIMEOUT, ("\r\n")) or die;
    $::exp->send("uci\r");
    $::exp->expect($::TIMEOUT,("uciok\r\n")) or die;
    $::exp->send("setoption name UCI_Chess960 value true\r") if $::chess960;
    $::exp->send("ucinewgame\risready\r");
    $::exp->expect($::TIMEOUT,("readyok\r\n")) or die;
}

sub engine {
    my $movelist1=shift;

    &start_engine;
    my%ans;
    $::exp->send("position $movelist1\r");
    $::exp->send("d\r");
    my@expect_result=$::exp->expect($::TIMEOUT,'-re','Fen: .*?\n') or die;
    $ans{fen}=$expect_result[2];
    @expect_result=$::exp->expect($::TIMEOUT,'-re','Checkers:.*?\n') or die;
    my $ischeck=$expect_result[2]; #this will get cleaned up below
    $::exp->send("perft 1\r");
    #benchmark.cpp
    $::exp->expect($::TIMEOUT,'Position: 1/1')or die;
    my@moves;
    for(;;){
        @expect_result=$::exp->expect($::TIMEOUT,'-re','\S+?: 1\r\n','-re','={27}.*\n') or die;
        my $item=$expect_result[2];
        if($item =~/(.*): 1/){
            push@moves,$1;
        } elsif($item =~ /^={27}/){
            last;
        } else {
            die;
        }
    }
    @expect_result=$::exp->expect($::TIMEOUT,'-re','Nodes searched\s*:\s*\d+\r\n') or die;
    die unless $expect_result[2]=~/Nodes searched\s*:\s*(\d+)/;
    my$count=$1;
    $::exp->expect($::TIMEOUT,'-re','Nodes/second\s*:\s*\d+\s*\r\n') or die;
    $::exp->send("quit\r");
    $::exp->expect(undef);
    $ans{fen} =~ s/\s*$//;
    $ans{fen} =~ s/^Fen:\s*// or die;
    die unless @moves==$count;

    $ischeck =~ s/^Checkers:// or die;
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
sub fen_rank_ok {
    die unless 1==@_;
    my$width=0;
    for(split //,$_[0]){
        if(/[1-8]/){
            $width+=$_;
        }elsif(/[pnbrqk]/i){
            $width++;
        }else{
            #bad character
            return 0;
        }
    }
    8==$width;
}

sub count_char {
    die unless @_==2;
    my$a=shift;
    die unless 1==length$a;
    my$count=0;
    for(split //,$_[0]){
        $count++ if $a eq $_;
    }
    $count;
}
