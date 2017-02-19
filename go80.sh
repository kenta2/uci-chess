#!/bin/bash
set -x
set -e
mkdir run/snapshot
cp * run/snapshot || true
# true is necessary because omitting directories causes error status
ls run/queue > run/startqueue
#maybe gitclone
find run/queue -type f -print0 | xargs -0 cat > run/startpos
