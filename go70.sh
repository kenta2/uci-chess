#!/bin/bash
set -x
set -e
set -C
ls run/queue > run/startqueue
find run/queue -type f -print0 | xargs -0 cat > run/startpos
