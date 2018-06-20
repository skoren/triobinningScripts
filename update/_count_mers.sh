#!/bin/bash

if ! [ -z $SLURM_ARRAY_TASK_ID ]; then
        i=$SLURM_ARRAY_TASK_ID
else
        i=$3
fi

if [ -z $1 ] || [ -z $2 ]; then
    echo "No haplotype information provided. Exit."
    echo "Usage: _count_mers.sh <mersize> <haplotype.only> [line_num]"
    echo -g "\tRequires fasta.list in the same dir."
    exit -1;
fi

### Edit this part
export PATH=/path/to/latest/canu/Linux-amd64/bin/:$PATH
###

mersize=$1
dumpdb=$2.only
out_dir=${dumpdb/.only/}
mkdir -p $out_dir

if ! [ -e fasta.list ]; then
        ls --color=none fasta/*.fa > fasta.list
fi
file=`sed -n ${i}p fasta.list`
prefix=`basename $file`
prefix=${prefix/.fa/} # Or prefix=${prefix/.fasta/}

if [ -e $out_dir/$prefix.count ]; then
        echo "$out_dir/$prefix.count already exists. exit."
        exit 0;
fi
echo "simple-dump -m $mersize -e $dumpdb -f $file > $out_dir/$prefix.count"
simple-dump -m $mersize -e $dumpdb -f $file > $out_dir/$prefix.count
echo "done!"
