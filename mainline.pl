#!perl -wl
#perl mainline-init.pl (moves)
#time while perl mainline.pl "nodes 100000" ; do : ; done
use Chess::Rep;
use Time::HiRes;

#timethink ought to be initialized in mainline-init and stored in the queue
die unless defined ($timethink=shift@ARGV);
print "timethink $timethink";

for$i(1..100){
    @queue=(<run/queue/*>);
    last if @queue;
    print "waiting $i for queue";
    &nanopause;
}
unless(@queue){
    die "empty queue";
}
#randomization to somewhat soften race conditions
$i=int rand@queue;
$file=$queue[$i];
print "file $file";
die unless ($base)=($file=~m,run/queue/(.*),);
($fiftyfen)=($base=~/_(\d+$)/) or $fiftyfen=0;  #preserve ability to use fifty-move draw if we bring it back

#avoid race condition
unless (open FI,$file) {
    print "failed to open";
    &nanopause;
    exit;
}
unless(defined($_=<FI>)){
    print "failed to read a line";
    &nanopause;
    exit;
}
close FI;
unless (($list)=/^proof(.*)/){
    print "line has wrong format: $_";
    &nanopause;
    exit;
}
print"moves$list";
die unless `perl moves-to-fen.pl --fifty $list` =~ /fifty (\d+)/;
$fiftyproof=$1;

($dbdir="run/db/$timethink")=~s/ /_/g;;
mkdir $dbdir unless -e $dbdir;
$db="$dbdir/$base";
if($fiftyfen>=2*50){
    unless(-e $db){
        open FO,">$db" or die;
        print FO "draw fifty by fen" or die;
        close FO or die;
    }
} elsif($fiftyproof>=2*50){
    unless(-e $db){
        open FO,">$db" or die;
        print FO "draw fifty by proof game" or die;
        close FO or die;
    }
} elsif(-e $db) {
    print "already db";
} else {
    open FO,">$db" or die;
    close FO or die; #empty file marks calculation in progress
    for my$retries(1..10000){
        $logfile="$db.$$.log";
        $_=`perl bestmove.pl --log=$logfile "$timethink" $list`;
        system "bzip2",$logfile;
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
            print "transposition";
        } else {
            print "new $fen";
            open FO,">$fen" or die;
            print FO "proof$list";
            close FO or die;
        }
    }
}
#this can fail via race conditions but that is OK
unlink $file;

sub nanopause {
    Time::HiRes::nanosleep(100*rand 1000_000);
}
