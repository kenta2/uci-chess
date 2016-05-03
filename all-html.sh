#!/bin/bash
set -e
set -x
if [ -z "$1" ]
then exit 1
fi
perl no-parents.pl $1 | perl run-dbplay-on-no-parent.pl $1 | bash | sort | perl -nlwe 's/^.*:://;print"<p>$_</p>"'
