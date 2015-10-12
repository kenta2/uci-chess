#! perl -w
# play through using only the database.  same input arguments as db-available, similar output as selfplay
use strict;
use Chess::Rep;

my$pos=Chess::Rep->new;
my$command='perl moves-to-fen.pl --list';
my $db=shift@ARGV;
die unless defined($db);
for(@ARGV){
    die unless /^\S+$/;
    die unless defined($pos->go_move($_));
    $command.=" ".$_;
}
my$list=`$command`;
chomp$list;
die unless ($list=~s/^list\s*//);
print $list;
print ' |';
#not counting repetitions in the opening
my %repetitions;
for(my$i=0;;++$i){
    #print $list,"\n";
    #my$fen=`perl moves-to-fen.pl --fen $list`;

    #do fen inline instead of script because it is much faster
    my$fen=$pos->get_fen;
    $fen=~s/\s+\d+$//; #discard move count
    $fen=~s/\s+\d+$//; #discard halfmove count for 50-move draw
    $fen=~s,/,.,g;
    $fen=~s/ /_/g;
    open FI,"$db/$fen" or die;
    die unless defined($_=<FI>);
    chomp;
    if(/^bestmove (.*)/){
        $_=$1;
        print " $_";
    } else {
        # this branch tends never to be taken because it
        # will get caught by the internal check for the 50-move rule first.
        print "\n$_\n";
        last;
    }
    if($_ eq '(none)'){
        print "\n";
        if($pos->status->{mate}){
            print "mate";
        } elsif($pos->status->{stalemate}){
            print "stalemate";
        } else {
            die;
        }
        print"\n";
        last;
    }
    $list .= " $_";
    die unless defined($pos->go_move($_));
    $fen=$pos->get_fen;
    #print "$fen\n";
    #print $pos->dump_pos,"\n";
    my($rle,$color,$castle,$enpassant,$fifty,$movecount)=split ' ',$fen;
    die unless $color eq 'w' or $color='b';
    die unless $fifty =~ /^\d+$/;
    die unless $movecount =~ /^\d+$/;
    if($fifty>=(2*50)){ #halfmoves
        print "\nfifty move rule\n";
        last;
    }
    my$state="$rle $color $castle $enpassant"; #tricky question as to whether castling and enpassant matter in three-fold repetition;
    $repetitions{$state}++;
    #print "repetitions $repetitions{$state}\n";
    if($repetitions{$state}>=3){
        print"\nthree-fold repetition\n";
        last;
    }
}
# perhaps try to detect insufficient material to checkmate
