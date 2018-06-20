#!/bin/bash

LEN=`wc -l fasta.list | awk '{print $1}'`

if [ -z $1 ] || [ -z $2 ] || [ -z $3 ]; then
        echo "Usage: ./_classify_reads.sh <k> <dumpdb1> <dumpdb2>"
        echo -e "\tRequires fasta.list : list of fasta files to classify (Child's long read fofn file)"
        exit -1;
fi

k=$1
dumpdb1=$2
dumpdb2=$3

TOOLS=$PWD/script
mkdir -p logs

cpus=2
mem="8g"
partition=quick
name=count_mers_$dumpdb1
walltime="4:00:00"
script="$TOOLS/_count_mers.sh"
args="$k $dumpdb1"

echo "sbatch --partition=$partition --cpus-per-task=$cpus --job-name=$name --mem=$mem --time=$walltime --error=logs/${name}_%A_%a.log --output=logs/${name}_%A_%a.log $dependency --array=1-$LEN $script $args"
sbatch --partition=$partition --cpus-per-task=$cpus --job-name=$name --mem=$mem --time=$walltime --error=logs/${name}_%A_%a.log --output=logs/${name}_%A_%a.log $dependency --array=1-$LEN $script $args > ${dumpdb1}_jobid

name=count_mers_$dumpdb2
args="$k $dumpdb2"
echo "sbatch --partition=$partition --cpus-per-task=$cpus --job-name=$name --mem=$mem --time=$walltime --error=logs/${name}_%A_%a.log --output=logs/${name}_%A_%a.log $dependency --array=1-$LEN $script $args"
sbatch --partition=$partition --cpus-per-task=$cpus --job-name=$name --mem=$mem --time=$walltime --error=logs/${name}_%A_%a.log --output=logs/${name}_%A_%a.log $dependency --array=1-$LEN $script $args > ${dumpdb2}_jobid

jid1=`cat ${dumpdb1}_jobid`
jid2=`cat ${dumpdb2}_jobid`
dependency="--dependency=afterok:$jid1,$jid2"
#END

#dependency=""
cpus=2
mem="4g"
partition=quick
name=classify_read
walltime="4:00:00"
script="$TOOLS/_classify_read.sh"
args="$dumpdb1 $dumpdb2"

echo "sbatch --partition=$partition --cpus-per-task=$cpus --job-name=$name --mem=$mem --time=$walltime $dependency --error=logs/${name}_%A_%a.log --output=logs/${name}_%A_%a.log --array=1-$LEN $script $args"
sbatch --partition=$partition --cpus-per-task=$cpus --job-name=$name --mem=$mem --time=$walltime $dependency --error=logs/${name}_%A_%a.log --output=logs/${name}_%A_%a.log --array=1-$LEN $script $args
