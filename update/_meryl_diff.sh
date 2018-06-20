#!/bin/bash

echo "Usage: ./_meryl_diff.sh <k> <meryl-db-A> <meryl-db-B>"

k=$1
dbA=$2
dbB=$3
out=$dbA.no$dbB

if ! [ -e $out.mcdat ]; then
        echo "/path/to/canu-1.7/Linux-amd64/bin/meryl -M difference -s $dbA -s $dbB -o $out"
        /path/to/canu-1.7/Linux-amd64/bin/meryl -M difference -s $dbA -s $dbB -o $out
        echo "/path/to/canu-1.7/Linux-amd64/bin/meryl -Dc -s $out"
        /path/to/canu-1.7/Linux-amd64/bin/meryl -Dc -s $out
        echo ""
fi

echo "Generate QR db"
echo "/path/to/canu-1.7/canu/Linux-amd64/bin/simple-dump -s $out -e $dbA.only -m $k"
/path/to/canu-1.7/canu/Linux-amd64/bin/simple-dump -s $out -e $dbA.only -m $k
