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
) or die "cannot open db $BerkeleyDB::Error";

$k='r1bQkb1r.ppp2ppp.2p5.4Pn2.8.5N2.PPP2PPP.RNB2RK1_b_kq';
$status=$db->db_del($k);
print "status=$status";

