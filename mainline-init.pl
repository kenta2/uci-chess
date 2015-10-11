#!perl -wl
$command='perl moves-to-fen.pl --fen --list';
for(@ARGV){
    $command.=" $_";
}
open FI,"$command|" or die;
while(<FI>){
    chomp;
    $fen=$1 if /^fen (.*)/;
    $list=$1 if /^list(.*)/;
}
die unless defined($list);
die unless $fen;
$fen=~s/\d+$//;
$fen=~s,/,.,g;
$fen=~s/ /_/g;
$fen="run/queue/$fen";
die if -e $fen;
open FO,">$fen" or die;
print FO "proof$list";
close FO;
