#!/bin/bash

k=$1
prefix=$2
filelist=$3

for file in $(grep $prefix $filelist);
do
name=${file/.fastq.gz/}
name=${name/.fq.gz/}
indb=$indb" -s $name.$k"
done

mrg=$prefix.k$k

echo "\
meryl -M add $indb -o $mrg"
meryl -M add $indb -o $mrg

echo "\
meryl -Dh -s $mrg > $mrg.hist"
meryl -Dh -s $mrg > $mrg.hist

echo "\
meryl -Dc -s $mrg > $mrg.count"
meryl -Dc -s $mrg > $mrg.count

echo "\
java -jar -Xmx512m kmerHistToPloidyDepth.jar $mrg.hist > $mrg.hist.ploidy"
java -jar -Xmx512m kmerHistToPloidyDepth.jar $mrg.hist > $mrg.hist.ploidy

x=`sed -n 2p $mrg.hist.ploidy | awk '{print $NF}'`

echo "\
meryl -M greaterthan $x -s $mrg -o $mrg.filt"
meryl -M greaterthan $x -s $mrg -o $mrg.filt

echo "\
meryl -Dc -s $mrg.filt"
meryl -Dc -s $mrg.filt

echo ""

echo "Ready to subtract"
