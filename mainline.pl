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
    -Home => 'run/bdb',
    -Flags => DB_INIT_TXN | DB_INIT_LOCK | DB_INIT_LOG | DB_INIT_MPOOL,
    -TxMax => 40 # default 20 is just on the edge
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
    exit 1; # this exit status is needed to kill the event loop
    #die "empty queue";
}
#randomization to somewhat soften race conditions
$i=int rand@queue;
$file=$queue[$i];
#print "file $file";
die $file unless ($base)=($file=~m,run/queue/(.*),);
#currently the following is not used
($fiftyfen)=($base=~/_(\d+$)/) or $fiftyfen=0;  #preserve ability to use fifty-move draw if we bring it back

#avoid race condition
unless (open FI,$file) {
    print "failed to open $file";
    &nanopause;
    exit;
}
unless(defined($_=<FI>)){
    print "failed to read a line $file";
    &nanopause;
    exit;
}
close FI;
chomp;
unless (s/ EOF$//){
    #guard against partially written files.
    &nanopause;
    exit;
}
if (/^chess960 (.+)/){
    $list = $1;
    $chess960='--chess960';
}else {
    $list=$_;
    $chess960='';
}
#print"moves$list";
$moves_to_fen="perl moves-to-fen-stockfish.pl $chess960";
if(`$moves_to_fen --fifty $list` =~ /fifty (\d+)/){
    $fiftyproof=$1;
} else {
    # perhaps race condition of a file being half written
    &nanopause;
    exit;
}

my $db=BerkeleyDB::Btree->new (
    -Filename => 'positions.db',
    -Flags => DB_AUTO_COMMIT,
    -Env => $env
) or die "cannot open it ($tartag) $BerkeleyDB::Error";

# key=$base
if($fiftyfen>=2*50){
    $status=$db->db_put($base,"draw fifty by fen",DB_NOOVERWRITE);
    die "fiftyfen $base $status" unless ($status==0 or $status==DB_KEYEXIST);
    print "fiftyfen already" if$status;
} elsif($fiftyproof>=2*50){
    $status=$db->db_put($base,"draw fifty by proof game",DB_NOOVERWRITE);
    die "fiftyproof $base $status" unless ($status==0 or $status==DB_KEYEXIST);
    #print "fiftyproof already" if$status;
} elsif($db->db_get($base,$value)==0){
    print "already db $base $value." if 0;
} else {
    $status=$db->db_put($base,""); #empty file marks calculation in progress
    die "empty put $base $status" unless $status==0;
    for my$retries(1..10){
        $logfile="run/log/$base.$$.log";
        $command=qq(perl bestmove.pl --multipv --log=$logfile $chess960 "$timethink" $list);
        #print "command =$command";
        $_=`$command`;
        system "bzip2",$logfile;
        $logfile.='.bz2';
        ($slog=$logfile)=~s,^run/,, or die $base;
        unless(system 'tar','rf',"run/log/$tartag.tar",'-C','run',$slog){
            unlink "$logfile";
        } else {
            print "tar error $?";
        }
        # xxx add to tar
        chomp;
        last if /\S/;
        print "$tartag $base (retry)";
    }
    #print "bestmove=$_";
    die $base unless /\S/; #too many retries
    $status=$db->db_put($base,$_);
    if($_ eq '(none)'){
        die $base unless `$moves_to_fen --status $list` =~ /mate/;
    } else {
        $list.=" $_";
        #print STDERR $list;
        $fen=`$moves_to_fen --fen $list`;
        chomp$fen;
        $fen=~ s/^fen // or die;
        die $base unless $fen;
        $fen="run/queue/$fen";
        if (-e $fen){
            #print "transposition";
        } else {
            #print "new $fen";
            #race condition possible here...
            #open FO,">$fen" or die $base;
            #$list="chess960 $list" if $chess960;
            #print FO "$list EOF" or die $base;
            #close FO or die$base;
        }
    }
}
#this can fail via race conditions but that is OK
undef $db;
unlink $file;

sub nanopause {
    Time::HiRes::nanosleep(100*rand 1000_000);
}
