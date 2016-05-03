#! perl -w
# play through using only the database.  same input arguments as db-available, similar output as selfplay
use strict;
use Chess::Rep;

my$pos=Chess::Rep->new;
my$command='perl moves-to-fen.pl --list';
my $db=shift@ARGV;
die unless defined($db);
my$san="";
for(@ARGV){
    die unless /^\S+$/;
    die unless defined(my$details=$pos->go_move($_));
    $san.=$$details{san}." ";
    $command.=" ".$_;
}
my$list=`$command`;
chomp$list;
die unless ($list=~s/^list\s*//);
print "mainline $list";
print ' |';
$san.="|";
#not counting repetitions in the opening
my %repetitions;
my $outcome;
my $DRAW="1/2";
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
        die unless /^draw/;
        $outcome=$DRAW;
        last;
    }
    if($_ eq '(none)'){
        print "\n";
        if($pos->status->{mate}){
            #print $pos->dump_pos,"\n";
            print "mate";
            if($pos->to_move){
                $outcome="0-1";
            } else {
                $outcome="1-0";
            }
        } elsif($pos->status->{stalemate}){
            print "stalemate";
            $outcome=$DRAW;
        } else {
            die;
        }
        print"\n";
        last;
    }
    $list .= " $_";
    die unless defined(my$details=$pos->go_move($_));
    $san.=' '.$$details{san};
    $fen=$pos->get_fen;
    #print "$fen\n";
    #print $pos->dump_pos,"\n";
    my($rle,$color,$castle,$enpassant,$fifty,$movecount)=split ' ',$fen;
    die unless $color eq 'w' or $color='b';
    die unless $fifty =~ /^\d+$/;
    die unless $movecount =~ /^\d+$/;
    if($fifty>=(2*50)){ #halfmoves
        print "\nfifty move rule\n";
        $outcome=$DRAW;
        last;
    }
    my$state="$rle $color $castle $enpassant"; #tricky question as to whether castling and enpassant matter in three-fold repetition;
    $repetitions{$state}++;
    #print "repetitions $repetitions{$state}\n";
    if($repetitions{$state}>=3){
        print"\nthree-fold repetition\n";
        $outcome=$DRAW;
        last;
    }
}
die unless defined $outcome;
print "outcome $outcome\n";
print "san $san\n";
# perhaps try to detect insufficient material to checkmate
