#!perl -w
use Chess::Rep;
use Getopt::Long;
GetOptions('fen'=>\$fen,
           'list'=>\$dolist,
           'moves'=>\$moves,
    );
$list='';
$pos=Chess::Rep->new;
for(@ARGV){
    die unless /^\S+$/;
    my$details;
    die unless defined($details=$pos->go_move($_));
    my$construct=lc($details->{from}.$details->{to});
    $list.=" $construct";
}
print "fen ",$pos->get_fen,"\n" if $fen;
print "list",$list,"\n" if $dolist;
if($moves){
    print"moves";
    $status=$pos->status;
    $moves=$status->{moves};
    for(@$moves){
        print " ",lc(Chess::Rep::get_field_id($$_{from})),lc(Chess::Rep::get_field_id($$_{to}));
    }
    print"\n";
}
