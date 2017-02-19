#!/bin/bash
set -x
set -e
set -o pipefail
. setpath.sh
#while read -r code
#do perl chess960-fen.pl $code
#done < chess960-starts | time perl chess960-init-1ply.pl
if [ -z "$1" ]
then exit 1
else numthreads=$1
fi
nice time xargs -n 1 -P $numthreads bash chess960-1ply-single.sh < chess960-starts
