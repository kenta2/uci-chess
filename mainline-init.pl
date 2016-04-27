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
$fen="run/queue/$fen";
die "already exists $fen" if -e $fen;
open FO,">$fen" or die "cannot open $fen for writing";
print FO "proof$list";
close FO;
