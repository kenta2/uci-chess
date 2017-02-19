#!/bin/bash
set -x
set -e
set -o pipefail
. setpath.sh
while read -r code
do perl chess960-fen.pl $code
done < chess960-starts | time perl chess960-init.pl
# 2 to 3 minutes
