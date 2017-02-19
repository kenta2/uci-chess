#!/bin/bash
set -x
set -e
if [ -e stop ]
then exit 1
fi
if [ -z "$1" ]
then exit 1
else numthreads=$1
fi
unset BZIP2
. setpath.sh
stockfish quit || exit 1
set +x
set +e
for ((i=1;i<=$numthreads;i++))
do echo $i
    while nice -19 perl mainline.pl $i
    do if [ -e stop ]
        then echo stop $i
            break
        fi
    done &
    sleep 1
    #need to sleep or else simultaneous attempts at creating Env would be a problem
done
time wait
