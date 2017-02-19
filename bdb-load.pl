#!perl -wl
use BerkeleyDB;
$env = new BerkeleyDB::Env (
    -Home => 'run/bdb',
    -Flags => DB_INIT_TXN | DB_INIT_LOCK | DB_INIT_LOG | DB_INIT_MPOOL,
    -TxMax => 40 # default 20 is just on the edge
    ) or die "cannot env: $BerkeleyDB::Error";

die unless defined($env);
my $db=BerkeleyDB::Btree->new (
    -Filename => 'positions.db',
    -Flags => DB_AUTO_COMMIT,
    -Env => $env
) or die "cannot open it $BerkeleyDB::Error";
while(<>){
    die unless ($k,$v) =/^(.+) -> (.*)$/;
    unless($v){
        print "skipping $k because empty key";
        next;
    }
    $status=$db->db_put($k,$v);
    die $status unless $status==0;
}
undef $db
