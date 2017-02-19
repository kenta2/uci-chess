#! perl -wl
use BerkeleyDB;

die unless defined$ARGV[0];

#test whether database corruption happens when running without transactions or locks
$env = new BerkeleyDB::Env (
    -Home => $ARGV[0],
    -Flags => DB_INIT_CDB | DB_INIT_MPOOL ) or die "cannot env: $BerkeleyDB::Error";

$db=BerkeleyDB::Btree->new ( -Flags => DB_RDONLY , -Filename => 'positions.db', -Env => $env ) or die "$BerkeleyDB::Error";
my$v;
$k=""; #needs to be initialized or else "uninitialized value";
my $cursor = $db-> db_cursor();
while($cursor->c_get($k,$v,DB_NEXT)==0){
    print "$k -> $v";
}

