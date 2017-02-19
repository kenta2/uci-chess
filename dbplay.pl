#! perl -w
# play through using only the database.  same input arguments as db-available, similar output as selfplay
use strict;
use Chess::Rep;
use BerkeleyDB;

my$pos=Chess::Rep->new;
my$command='perl moves-to-fen.pl --list';
my $envdir=shift@ARGV;
die unless defined($envdir);
my$env = new BerkeleyDB::Env (
    -Home => $envdir,
    -Flags => DB_INIT_CDB | DB_INIT_MPOOL ) or die "cannot env: $BerkeleyDB::Error";

my$db=BerkeleyDB::Btree->new ( -Flags => DB_RDONLY , -Filename => 'positions.db', -Env => $env ) or die "$BerkeleyDB::Error";


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
    $fen=~s/\s+\S+$// or die; #discard en passant square
    # this is somewhat of a hack to work around Chess::Rep and Stockfish disagreeing on en passant square in FEN

    $fen=~s,/,.,g;
    $fen=~s/ /_/g;
    my$status=$db->db_get($fen,$_);
    die "failed $fen,$status" if $status;
    if(/^[a-h][1-8][a-h][1-8][nbrq]?$/){
        print " $_";
    }
    elsif($_ eq '(none)'){
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
    } else {
        # this branch tends never to be taken because it
        # will get caught by the internal check for the 50-move rule first.
        print "\n$_\n";
        die "bad $_" unless /^draw/;
        $outcome=$DRAW;
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
