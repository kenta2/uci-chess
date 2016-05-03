#! perl -lw
# pipe from  output of no-parent.pl | sort
die unless defined ($dir=$ARGV[0]);
while(<STDIN>){
    chomp;
    next if /^skipping/;
    die unless /(.*) ~ /;
    $command="perl dbplay.pl $dir $1 | perl make-html.pl";
    print $command;
}
