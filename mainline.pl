#!perl -wl
use Chess::Rep;
die unless defined ($timethink=shift@ARGV);
print "timethink $timethink";
@queue=(<run/queue/*>);
unless(@queue){
    die "empty queue";
}
#randomization to somewhat soften race conditions
$i=int rand@queue;
$file=$queue[$i];
print "file $file";
die unless ($base)=($file=~m,run/queue/(.*),);
die unless ($fifty)=($base=~/(\d+$)/);
($dbdir="run/db/$timethink")=~s/ /_/g;;
mkdir $dbdir unless -e $dbdir;
$db="$dbdir/$base";
if(-e $db){
    print "already db";
} elsif($fifty>=2*50){
    open FO,">$db" or die;
    print FO "draw fifty" or die;
    close FO or die;
} else {
    open FO,">$db" or die;
    close FO or die; #empty file marks calculation in progress

    open FI,$file or die;
    die unless defined($_=<FI>);
    close FI;
    die unless ($list)=/^proof(.*)/;
    print"moves$list";
    for my$retries(1..10000){
        $_=`perl bestmove.pl "$timethink" $list`;
        chomp;
        last if /\S/;
        print " (retry)";
    }
    die unless /\S/; #too many retries
    open FO,">$db" or die;
    print FO "bestmove $_";
    close FO;
    if($_ eq '(none)'){
        die unless `perl moves-to-fen.pl --status $list` =~ /mate/;
    } else {
        $list.=" $_";
        open FI,"perl moves-to-fen.pl --fen $list |" or die;
        undef$fen;
        while(<FI>){
            chomp;
            $fen=$1 if /^fen (.*)/;
        }
        die unless $fen;
        $fen="run/queue/$fen";
        if (-e $fen){
            print "transposition"
        } else {
            open FO,">$fen" or die;
            print FO "proof$list";
            close FO or die;
        }
    }
}
unlink $file or die;
