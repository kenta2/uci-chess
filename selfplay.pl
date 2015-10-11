#! perl -w
#chesslog=/tmp/stockfish-$(date +%s).log nice time perl selfplay.pl -o '--threads=4 --hash=500' d4 Nf6

# detect stalemate, threefold repetition, fifty move rule.
# not perpetual check.
use strict;
use Chess::Rep;
use Getopt::Long;

die unless defined $ENV{chesslog};
die if -e $ENV{chesslog};
print "chesslog=$ENV{chesslog}\n";

my$nodes_per_minute=36_000_000*10.;
my$nodes_per_hour=$nodes_per_minute*60;
my$total_hours=0.5/60;
my$total_nodes=$total_hours*$nodes_per_hour;
my$total_moves=80;
my$nodes=int($total_nodes/$total_moves);

my$opts='';
GetOptions('o=s' => \$opts,
           'nodes=i' => \$nodes
    );

my$timethink="nodes $nodes";
#6.25s per million x 10 moves

my$pos=Chess::Rep->new;
my$command='perl moves-to-fen.pl --list';
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
    for my$retries(1..10000){
        $_=`perl bestmove.pl --log=$ENV{chesslog} $opts "$timethink" $list`;
        chomp;
        last if /\S/;
        print " (retry)";
    }
    die unless /\S/; #too many retries
    print" $_";

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
    my$fen=$pos->get_fen;
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
