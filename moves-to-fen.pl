#!perl -w
use Chess::Rep;
use Getopt::Long;
GetOptions('fen'=>\$fen,
           'list'=>\$dolist,
           'moves'=>\$moves,
           'dump'=>\$dodump,
           'status'=>\$dostatus,
           'fifty'=>\$dofifty,
    );
$list='';
$pos=Chess::Rep->new;
for(@ARGV){
    die unless /^\S+$/;
    my$details;
    die unless defined($details=$pos->go_move($_));
    my$construct=$details->{from}.$details->{to};
    if(defined$details->{promote}){
        $construct.=$details->{promote};
    }
    $list.=" ".lc$construct;
}
if($fen){
    $_=$pos->get_fen;
    s/\s+\d+$//; #discard move count
    s/\s+\d+$//; #discard halfmove count for 50-move draw
    s,/,.,g;
    s/ /_/g;
    print "fen $_\n";
}
print "list",$list,"\n" if $dolist;
if($moves){
    print"moves";
    $status=$pos->status;
    $moves=$status->{moves};
    for(@$moves){
        $base=lc(Chess::Rep::get_field_id($$_{from}).Chess::Rep::get_field_id($$_{to}));
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
if($dostatus){
    print "mate\n" if $pos->status->{mate};
    print "stalemate\n" if $pos->status->{stalemate};
    #perl moves-to-fen.pl --status c4 h5 h4 a5 Qa4 Ra6 Qxa5 Rah6 Qxc7 f6 Qxd7+ Kf7 Qxb7 Qd3 Qxb8 Qh7 Qxc8 Kg6 Qe6

}
if($dofifty){
    $_=$pos->get_fen;
    my($rle,$color,$castle,$enpassant,$fifty,$movecount)=split;
    die unless $color eq 'w' or $color='b';
    die unless $fifty =~ /^\d+$/;
    die unless $movecount =~ /^\d+$/;
    print "fifty $fifty\n";
}
