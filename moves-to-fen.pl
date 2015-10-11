#!perl -w
use Chess::Rep;
use Getopt::Long;
GetOptions('fen'=>\$fen,
           'list'=>\$dolist,
           'moves'=>\$moves,
           'dump'=>\$dodump,
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
        $base=lc(Chess::Rep::get_field_id($$_{from})).lc(Chess::Rep::get_field_id($$_{to}));
        $finished=0;
        if($$_{piece}&1){ #pawn
            @rc=Chess::Rep::get_row_col($$_{to});
            die unless @rc==2;
            die unless defined($rank=$rc[0]);

            if((Chess::Rep::piece_color($$_{piece})and$rank==7)or
               (!Chess::Rep::piece_color($$_{piece})and$rank==0)){
                for(qw(q r n b)){
                    print " ",$base,$_;
                }
                $finished=1;
            }}
        print" ",$base unless $finished;
    }
    print"\n";
}
print $pos->dump_pos,"\n" if $dodump;
