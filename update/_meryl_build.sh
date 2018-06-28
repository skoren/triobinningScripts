#!/bin/bash

num_line=$SLURM_ARRAY_TASK_ID 
if [ -z "$num_line" ] ; then
	num_line=$3
fi

k=$1
fastq=`sed -n ${num_line}p $2 | awk '{print $1}'`
name=${fastq/.fastq.gz/}
name=${name/.fq.gz/}

if [ -e "$name.$k.mcdat" ]; then
	echo "$name.$k.mcdat already exists. skip building."
	return 0;
fi

## Add Ns to each fastq read and make a fasta read with 1000000 fastq reads.
## Names are given as $name.0 $name.1 ... but not really used anywhere.
## This process is to avoid 'too many lines of reads' problem when reading directly
echo "convert $fastq to FASTA"
echo "PWD : $PWD"
if ! [ -e $name.fa ] ; then
	if [[ ${fastq} =~ \.gz$ ]]; then
		zcat $fastq | awk -v name=$name 'BEGIN {print ">"name".0"; num=1} {if (NR%4==2) print $1"N"; if (NR%4000000==0) {print "\n>"name"."num; num++}}' > $name.fa
	else
		cat $fastq | awk -v name=$name 'BEGIN {print ">"name".0"; num=1} {if (NR%4==2) print $1"N"; if (NR%4000000==0) {print "\n>"name"."num; num++}}' > $name.fa
	fi
fi

echo "build meryl db"
echo "\
meryl -B -C -s $name.fa -m $k -threads $SLURM_CPUS_PER_TASK -segments $SLURM_CPUS_PER_TASK -o $name.$k"
meryl -B -C -s $name.fa -m $k -threads $SLURM_CPUS_PER_TASK -segments $SLURM_CPUS_PER_TASK -o $name.$k

