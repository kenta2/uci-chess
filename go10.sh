#!/bin/bash
set -x
set -e
perl openings-prefix.pl openings.short | nice time bash
