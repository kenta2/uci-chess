#!/bin/bash
set -x
set -e
set -C
mkdir run/snapshot
cp * run/snapshot || true
# true is necessary because omitting directories causes error status
git describe --always > run/snapshot/git-describe
git diff > run/snapshot/git-diff
