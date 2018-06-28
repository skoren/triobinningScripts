#!/bin/bash

echo "Usage: ./_meryl_filt.sh <meryl-db>"

if [ -z $1 ]; then
	echo "No <meryl-db> provided."
	exit -1;
fi

if ! [ -e $1.hist ]; then
	echo "meryl -Dh -s $1 > $1.hist"
	meryl -Dh -s $1 > $1.hist
fi

echo "\
java -jar -Xmx512m kmerHistToPloidyDepth.jar $1.hist > $1.hist.ploidy"
java -jar -Xmx512m kmerHistToPloidyDepth.jar $1.hist > $1.hist.ploidy

x=`sed -n 2p $1.hist.ploidy | awk '{print $NF}'`

echo "\
meryl -M greaterthan $x -s $1 -o $1.filt"
meryl -M greaterthan $x -s $1 -o $1.filt

echo "\
meryl -Dc -s $1.filt > $1.filt.count"
meryl -Dc -s $1.filt > $1.filt.count
