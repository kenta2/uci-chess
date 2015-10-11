#!perl -wl
use Chess::Rep;
#die unless defined ($timethink=shift@ARGV);

#print&randomize_list(1,2,3,4) for (1..2400000);

@queue=&randomize_list(<queue/*>);
unless(@queue){
    print STDERR "empty queue.";
    exit;
}

sub randomize_list {
    my@l=@_;
    for($i=$#l;$i>=0;$i--){
        $j=int rand (1+$i);
        my$t=$l[$i];
        $l[$i]=$l[$j];
        $l[$j]=$t;
    }
    @l;
}
