#! perl -w
while(<>){
    chomp;
# pipe from  output run-dbplay-on-no-parent.pl
    if(/^mainline (.*)/){
        $mainline=$1;
    } elsif($_ eq 'three-fold repetition'){
        $draw_reason=$_;
    } elsif(/^outcome (.*)/){
        $outcome=$1;
    } elsif(/^san (.*)/){
        $san=$1;
    } elsif ($_ eq 'fifty move rule'){
        $draw_reason=$_;
    } elsif ($_ eq 'mate') {
        #ignore
    } else {
        die "weird '$_'";
    }
}
$mainline=~s!\s*\|\s*! !;
$mainline =~s/^\s*//;
print "$mainline ::"; #for sorting;
@F=split for($san);
$out=0;
$seen_bar=0;
for(@F){
    if($_ eq '|'){
        $seen_bar=1;
        next;
    }
    print " " unless ($out==0);
    unless($seen_bar){
        print "<b>";
    }
    if($out%2==0){
        print $out/2+1,".";
    }
    print$_;
    $out++;
    unless($seen_bar){
        print "</b>";
    }
}
print " ";
if($outcome eq '1/2'){
    print "1/2-1/2 {$draw_reason}";
} else {
    print $outcome;
}
print "\n";
