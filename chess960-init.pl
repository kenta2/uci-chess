#! perl -nwl
# somewhat similar to mainline-init.pl and openings-prefix.pl
$command="perl moves-to-fen-stockfish.pl";
$startpos=$_;
open FI,"$command --fen --moves --chess960 fen $_|" or die;
while(<FI>){
    chomp;
    $fen=$1 if /^fen (\S+)$/;
    $moves=$1 if /^moves(.*)/;
}
die unless $fen;
die unless defined($moves);
$dir='run/queue';
die "already exists $fen" if -e "$dir/$fen";
open FO,">$dir/$fen" or die;
#need to provide empty moves for easy appending of more moves later
print FO "chess960 fen $startpos moves EOF" or die;
close FO or die;
exit;
@MOVES=split for($moves);
for$m(@MOVES){
    printf("%s ",$m);
    $fen=`$command --fen --chess960 fen $startpos moves $m`;
    chomp$fen;
    die unless $fen =~ s/^fen //;
    die unless $fen =~ /^(\S+)$/;
    open FO,">$dir/$fen" or die;
    print FO "chess960 fen $startpos moves $m EOF" or die;
    close FO or die;
}
print "";
