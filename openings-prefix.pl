#!perl -nlwa
BEGIN{
    print "set -e";
    print "set -x";
}
next if /^\s*#/;
for$limit(0..@F){
    $_='';
    for($i=0;$i<$limit;++$i){
        $_.=" " if$i;
        $_.=$F[$i];
    }
    $s{$_}=1;
}
END{
    for(sort keys%s){
            print "perl mainline-init.pl $_";
    }
}
