#! perl -wl
use Chess::Rep;
die unless defined ($timethink=shift@ARGV);
for$file(<queue/*>){
    die unless ($base)=($file=~m,queue/(.*),);
    die if -e ("db/$base");
    open FI,$file or die;
    die unless defined($_=<FI>);    chomp;
    die unless ($proof)=/^proof(.*)/; #proof game to that position
    $proofs{$base}=$proof;
    die unless defined($_=<FI>);    chomp;
    if($_ eq 'main'){ #mainline
        push @main,$base;
    }elsif($_ eq 'side'){ #sideline
        push @side,$base;
    }
    close FI;
}
if(@main){
    $subject=shift@main;
} else {
    $doing_side=1;
    die unless @side; #no more work
    $subject=shift@side;
}
unlink "queue/$subject" or die;
#test for various conditions eg fifty move
#need to check for successful execution, etc.
system "perl chess/bestmove.pl \"$timethink\" $proofs{$subject} > db/$subject";

