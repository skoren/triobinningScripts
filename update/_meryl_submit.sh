#! /bin/bash

ls --color=never *R1_001.fastq.gz *R2_001.fastq.gz > fastq_gz.list

if [ -z $1 ]; then
	echo "Useage: sh _meryl_run.sh <k-size> <haplotypeMom> <haplotypeDad>"
	exit -1
fi
LEN=`wc -l fastq_gz.list | awk '{print $1}'`
#LEN=1

k=$1
hapMom=$2
hapDad=$3

cpus=20
mem="80g"
partition=quick
name=meryl_build
walltime="4:00:00"
script="/home/rhiea/codes/_meryl_build.sh"
args="$k fastq_gz.list"

mkdir -p logs
log=logs/${name}_%A_%a.log

echo "\
sbatch --partition=$partition --cpus-per-task=$cpus --job-name=$name --mem=$mem --time=$walltime --error=$log --output=$log --array=1-$LEN $script $args"
sbatch --partition=$partition --cpus-per-task=$cpus --job-name=$name --mem=$mem --time=$walltime --error=$log --output=$log --array=1-$LEN $script $args > meryl_build_jid

cpus=4
mem="80g"
partition=norm
walltime="8:00:00"
script="/home/rhiea/codes/_meryl_mrg.sh"
meryl_build_jid=`cat meryl_build_jid`
if [ -z $meryl_build_jid ]; then
	dependency=""
else
	dependency="--dependency=afterok:$meryl_build_jid"
fi
name=meryl_mrg_$hapMom
args="$k $hapMom fastq_gz.list"

log=logs/${name}_%A_%a.log
echo "\
sbatch --partition=$partition --cpus-per-task=$cpus --job-name=$name --mem=$mem --time=$walltime $dependency --error=$log --output=$log $script $args"
sbatch --partition=$partition --cpus-per-task=$cpus --job-name=$name --mem=$mem --time=$walltime $dependency --error=$log --output=$log $script $args

name=meryl_mrg_$hapDad
log=logs/${name}_%A_%a.log
args="$k $hapDad fastq_gz.list"
echo "\
sbatch --partition=$partition --cpus-per-task=$cpus --job-name=$name --mem=$mem --time=$walltime $dependency --error=$log --output=$log $script $args"
sbatch --partition=$partition --cpus-per-task=$cpus --job-name=$name --mem=$mem --time=$walltime $dependency --error=$log --output=$log $script $args

hapMom=$hapMom.k$k.filt
hapDad=$hapDad.k$k.filt

mem=12g
walltime="2:00:00"
script="_meryl_diff.sh"
name=meryl_diff_${hapMom}_only
log=logs/${name}_%A_%a.log
args="$k $hapMom $hapDad"
echo "\
sbatch --partition=$partition --cpus-per-task=$cpus --job-name=$name --mem=$mem --time=$walltime $dependency --error=$log --output=$log $script $args"
sbatch --partition=$partition --cpus-per-task=$cpus --job-name=$name --mem=$mem --time=$walltime $dependency --error=$log --output=$log $script $args

name=meryl_diff_${hapDad}_only
log=logs/${name}_%A_%a.log
args="$k $hapDad $hapMom"
echo "\
sbatch --partition=$partition --cpus-per-task=$cpus --job-name=$name --mem=$mem --time=$walltime $dependency --error=$log --output=$log $script $args"
sbatch --partition=$partition --cpus-per-task=$cpus --job-name=$name --mem=$mem --time=$walltime $dependency --error=$log --output=$log $script $args
