#!perl -wl
use BerkeleyDB;
#mkdir run/.. bdb log queue
#perl mainline-init.pl (moves)

#time while nice -19 perl mainline.pl [1...] ; do if [ -e stop ] ; then break ; fi ; done

#Warning: it is fairly easy to exceed the maximum number of inodes (df -i).
#Future: consider BerkeleyDB or sqlite.

use Chess::Rep;
use Time::HiRes;

die unless defined ($tartag=shift@ARGV);
$timethink='nodes 30000'; #hard code this so that sits in version control
#print "timethink $timethink";

$env = new BerkeleyDB::Env (
    -Home => 'run/bdb', # add timethink later?
    -Flags => DB_CREATE | DB_INIT_CDB | DB_INIT_MPOOL
    ) or die "cannot env: $BerkeleyDB::Error";

die unless defined($env);

# The number of tips, i.e., queue entries, is likely to remain in the
# thousands at most so no need to do BerkeleyDB, though the Recno
# database type looks promising, with DB_APPEND and compact

for$i(1..100){
    @queue=(<run/queue/*>);
    last if @queue;
    #print "waiting $i for queue";
    &nanopause;
}
unless(@queue){
    die "empty queue";
}
#randomization to somewhat soften race conditions
$i=int rand@queue;
$file=$queue[$i];
#print "file $file";
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
{
    @F=split for($list);
    for(@F){
        die "bad move $_" unless /^([a-h][1-8]){2}[nbrq]?$/;
    }
}
#print"moves$list";
die unless `perl moves-to-fen.pl --fifty $list` =~ /fifty (\d+)/;
$fiftyproof=$1;

my $db=BerkeleyDB::Btree->new (
    -Filename => 'positions.db',
    -Flags => DB_CREATE,
    -Env => $env
) or die "cannot open it $BerkeleyDB::Error";

# key=$base
if($fiftyfen>=2*50){
    $status=$db->db_put($base,"draw fifty by fen",DB_NOOVERWRITE);
    die "fiftyfen $status" unless ($status==0 or $status==DB_KEYEXIST);
    print "fiftyfen already" if$status;
} elsif($fiftyproof>=2*50){
    $status=$db->db_put($base,"draw fifty by proof game",DB_NOOVERWRITE);
    die "fiftyproof $status" unless ($status==0 or $status==DB_KEYEXIST);
    print "fiftyproof already" if$status;
} elsif($db->db_get($base,$value)==0){
    print "already db $base $value." if 0;
} else {
    $status=$db->db_put($base,""); #empty file marks calculation in progress
    die "empty put $status" unless $status==0;
    for my$retries(1..1){
        $logfile="run/log/$base.$$.log";
        $command=qq(perl bestmove.pl --multipv --log=$logfile "$timethink" $list);
        #print "command =$command";
        $_=`$command`;
        system "bzip2",$logfile;
        $logfile.='.bz2';
        ($slog=$logfile)=~s,^run/,, or die;
        unless(system 'tar','rf',"run/log/$tartag.tar",'-C','run',$slog){
            unlink "$logfile";
        } else {
            print "tar error $?";
        }
        # xxx add to tar
        chomp;
        last if /\S/;
        print " (retry)";
    }
    #print "bestmove=$_";
    die unless /\S/; #too many retries
    $status=$db->db_put($base,"$_");
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
            #print "transposition";
        } else {
            #print "new $fen";
            #race condition possible here...
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
