#!/bin/bash

if ! [ -z $SLURM_ARRAY_TASK_ID ]; then
        i=$SLURM_ARRAY_TASK_ID
else
        i=$3
fi

if [ -z $1 ] || [ -z $2 ]; then
    echo "No haplotype information provided. Exit."
    echo "Usage: _classify_read.sh <hap1> <hap2> [line_num]"
    echo -e "\tRequires fasta.list in the same dir."
    exit -1;
fi

hapA=$1
hapB=$2

file=`sed -n ${i}p fasta.list`
prefix=`basename $file`
prefix=${prefix/.fa/}

mkdir -p classified

# This is how the join should look like
# m54158_170803_203753/4522600/0_3504 3484 227000131 7 3484 216075490 6
# m54158_170803_203753/4588072/0_3303 3283 227000131 111 3283 216075490 120
# m54158_170803_203753/4588093/0_3706 3686 227000131 35 3686 216075490 3

join $hapA/$prefix.count $hapB/$prefix.count | awk -v hapA=$hapA -v hapB=$hapB '{if ($4 == 0 && $7 == 0) {print $1"\tUnknown""\t0\t0\t"$2} else { a=$4/$3; b=$7/$6; if (a > b) {print $1"\t"hapA"\t"a"\t"b"\t"$2} else if (b > a) {print $1"\t"hapB"\t"a"\t"b"\t"$2} else {print $1"\tUnknown""\t"a"\t"b"\t"$2} }}' - > classified/$prefix.map

# Now, collect each hap reads
for hap in $hapA $hapB "Unknown"
do
    if ! [ -e classified/$hap/$prefix.fa ]; then
       mkdir -p classified/$hap
        mkdir -p tmp
        echo "extract reads classified as haplotype $hap"
        cat classified/$prefix.map | awk -v hap=$hap '$2==hap {print $1}' > tmp/$hap.$prefix.list
        echo "java -jar -Xmx2g fastaExtractFromList.jar $file tmp/$hap.$prefix.list classified/$hap/$prefix.fa"
        java -jar -Xmx2g fastaExtractFromList.jar $file tmp/$hap.$prefix.list classified/$hap/$prefix.fa
        rm tmp/$hap.$prefix.list
    fi
done

