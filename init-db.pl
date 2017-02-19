#!perl -wl
use BerkeleyDB;
$env = new BerkeleyDB::Env (
    -Home => 'run/bdb',
    # use transactions to be able to recover from hardware failure
    -Flags => DB_CREATE | DB_INIT_TXN | DB_INIT_LOCK | DB_INIT_LOG | DB_INIT_MPOOL,
    -TxMax => 40 # default 20 is just on the edge
    ) or die "cannot env: $BerkeleyDB::Error";

my $db=BerkeleyDB::Btree->new (
    -Filename => 'positions.db',
    -Flags => DB_CREATE | DB_AUTO_COMMIT,
    -Env => $env
) or die "cannot open it $BerkeleyDB::Error";

undef $db
