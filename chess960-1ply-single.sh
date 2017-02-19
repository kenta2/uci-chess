#!/bin/bash
#useful for feeding into xargs -P
#set -x
set -e
set -o pipefail
if [ -z "$1" ]
then echo need rank code
    exit 1
fi
# assume path is set for speed
#. setpath.sh
perl chess960-fen.pl $1 | perl chess960-init-1ply.pl
