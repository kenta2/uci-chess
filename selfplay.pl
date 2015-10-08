#! perl -w
use strict;
use Chess::Rep;
my$list='';
my$timethink="depth 6";
for(@ARGV){
    die unless /^\S+$/;
    $list.=" $_";
}
for(;;){
    #print $list,"\n";
    my$move=`perl bestmove.pl "$timethink" $list`;
    print$move;
    chomp$move;
    last if $move eq '(none)';
    $list .= " $move";
}
