#!perl -wl
use Chess::Rep;
my$pos=Chess::Rep->new;
for(@ARGV){
    die unless /^\S+$/;
    die unless defined($pos->go_move($_));
}
print$pos->get_fen;
