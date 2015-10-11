#!perl -wl
use Chess::Rep;
#die unless defined ($timethink=shift@ARGV);

@queue=(<queue/*>);
unless(@queue){
    print STDERR "empty queue.";
    exit;
}
#randomization to somewhat soften race conditions
$i=int rand@queue;
$file=$queue[$i];
print $file;

