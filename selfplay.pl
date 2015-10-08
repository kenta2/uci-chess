#! perl -w
use strict;
use Chess::Rep;
my$list='';
my$timethink="depth 6";
my$pos=Chess::Rep->new;
for(@ARGV){
    die unless /^\S+$/;
    print" $_";
    $list.=" $_";
    die unless defined($pos->go_move($_));
}
for(;;){
    #print $list,"\n";
    $_=`perl bestmove.pl "$timethink" $list`;
    chomp;
    print" $_";

    last if $_ eq '(none)';
    $list .= " $_";
    die unless defined($pos->go_move($_));
}
print "\n";
