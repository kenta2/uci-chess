#!perl -lw
die unless defined($_=$ARGV[0]);
$black=lc$_;
$white=uc$_;
die unless 8==length$_;

for($i=7;$i>=0;$i--){
    if ('r' eq substr$black,$i,1){
        $castling.=chr(ord('a')+$i);
    }
}
$castling=(uc$castling).$castling;
$fen=$black.'/'.('p'x8).'/8/8/8/8/'.('P'x8).'/'.$white.' w '.$castling.' - 0 1';
print $fen;
