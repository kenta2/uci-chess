#! perl -nwl
# somewhat similar to mainline-init.pl and openings-prefix.pl
$command="perl moves-to-fen-stockfish.pl";
$startpos=$_;
open FI,"$command --fen --moves --chess960 fen $_|" or die;
while(<FI>){
    chomp;
    $fen=$1 if /^fen (\S+)$/;
}
die unless $fen;
$dir='run/queue';
die "already exists $fen" if -e "$dir/$fen";
open FO,">$dir/$fen" or die;
#need to provide empty moves for easy appending of more moves later
print FO "chess960 fen $startpos moves EOF" or die;
close FO or die;
