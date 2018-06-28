#!/bin/bash

echo "Usage: ./_meryl_diff.sh <k> <meryl-db-A> <meryl-db-B>"

k=$1
dbA=$2
dbB=$3
out=$dbA.no$dbB

if ! [ -e $out.mcdat ]; then
        echo "meryl -M difference -s $dbA -s $dbB -o $out"
        meryl -M difference -s $dbA -s $dbB -o $out
        echo "meryl -Dc -s $out"
        meryl -Dc -s $out
        echo ""
fi

echo "Generate QR db"
echo "\
simple-dump -s $out -e $dbA.only -m $k"
simple-dump -s $out -e $dbA.only -m $k
