#!perl -wl
use Chess::Rep;
$list='';
$pos=Chess::Rep->new;
for(@ARGV){
    die unless /^\S+$/;
    die unless defined($details=$pos->go_move($_));
    $construct=lc($details->{from}.$details->{to});
    $list.=" $construct";
}
$fen=$pos->get_fen;
$fen=~s/\d+$//g;
$fen=~s,/,.,g;
$fen=~s/ /_/g;
$fen="queue/$fen";
die if -e "$fen";
open FO,">$fen" or die;
print FO "proof$list";
print FO "main";
