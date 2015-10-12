#!perl -wl
# which moves in a database (1st argument) have been evaluated:
# perl db-available.pl run/db/nodes_500000 d4 Nf6 c4
die unless defined($dir=shift@ARGV);
die unless -e $dir;
$list='';
for(@ARGV){
    $list.=" $_";
}
die unless `perl moves-to-fen.pl --moves $list` =~ /moves(.*)/;
@moves=split for($1);
for(@moves) {
    die unless `perl moves-to-fen.pl --fen $list $_` =~ /fen (.*)/;
    print if -e "$dir/$1";
}
