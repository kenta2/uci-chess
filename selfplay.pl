#! perl -w
use strict;
use Chess::Rep;
die unless defined $ENV{chesslog};
die if -e $ENV{chesslog};
my$list='';
my$nodes_per_minute=36_000_000*10.;
my$nodes_per_hour=$nodes_per_minute*60;
my$total_hours=0.5/60;
my$total_nodes=$total_hours*$nodes_per_hour;
my$total_moves=80;
my$nodes=int($total_nodes/$total_moves);
my$timethink="nodes $nodes";
#6.25s per million x 10 moves
my$pos=Chess::Rep->new;
for(@ARGV){
    die unless /^\S+$/;
    print"$_ ";
    $list.=" $_";
    die unless defined($pos->go_move($_));
}
print '|';
#not counting repetitions in the opening
my %repetitions;
for(my$i=0;;++$i){
    #print $list,"\n";
    $_=`perl bestmove.pl "$timethink" $list`;
    chomp;
    print" $_";

    if($_ eq '(none)'){
        print "\n";
        print "mate\n" if $pos->status->{mate};
        print "stalemate\n" if $pos->status->{stalemate};
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
    if($fifty>=50){
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
