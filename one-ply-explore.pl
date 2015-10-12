#! perl -lw
for(;;){
    &single(@ARGV);
    last unless @ARGV;
    pop@ARGV;
}
sub single {
    my$l=join ' ',@_;
    #print$l;
    my$moves;
    die unless ($moves)=(`perl moves-to-fen.pl --moves $l` =~ /^moves(.*)/);
    #print$moves;
    #my@m=split for($moves);
    my@m=split ' ',$moves;
    #print scalar@m;
    for(@m){
        print "perl mainline-init.pl $l $_";
    }
}
