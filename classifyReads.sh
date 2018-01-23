#!/bin/sh

syst=`uname -s`
arch=`uname -m`
name=`uname -n`

if [ "$arch" = "x86_64" ] ; then
  arch="amd64"
fi
if [ "$arch" = "Power Macintosh" ] ; then
  arch="ppc"
fi

bin="canu-1.6/$syst-$arch/bin"

if [ ! -d "$bin" ] ; then
  bin="/data/projects/phillippy/software/canu-1.6"
fi


#  Store must exist: correction/asm.gkpStore

#  Discover the job ID to run, from either a grid environment variable and a
#  command line offset, or directly from the command line.
#
if [ x$SGE_TASK_ID = x -o x$SGE_TASK_ID = xundefined -o x$SGE_TASK_ID = x0 ]; then
  baseid=$1
  offset=0
else
  baseid=$SGE_TASK_ID
  offset=$1
fi
if [ x$offset = x ]; then
  offset=0
fi
if [ x$baseid = x ]; then
  echo Error: I need SGE_TASK_ID set, or a job index on the command line.
  exit
fi
jobid=`expr $baseid + $offset`
if [ x$SGE_TASK_ID = x ]; then
  echo Running job $jobid based on command line options.
else
  echo Running job $jobid based on SGE_TASK_ID=$SGE_TASK_ID and offset=$offset.
fi

NUM_JOBS=`wc -l input.fofn |awk '{print $1}'`

if [ $jobid -gt $NUM_JOBS ]; then
  echo Error: Only $NUM_JOBS partitions, you asked for $jobid.
  exit 1
fi

jobid=`echo $jobid |awk '{print $1}'`
input_file=`head -n $jobid input.fofn |tail -n 1`
output_file=`echo $input_file |awk -F "/" '{print $(NF-1)"_"$NF}'`
output_file=`echo $output_file |awk -F "." '{print $1"."$2}' | sed s/.subreads//g`

echo "Running wtih $input_file to $output_file"

if [ ! -e $output_file.dam.fastq.gz ]; then
   if [ ! -e $jobid.success ]; then
      echo "Running classification..."
      java convertFastqToFastaAndQual $input_file $output_file.fasta tmp.qual PHRED32 false
      python classify.py onlydam.counts onlysire.counts $output_file.fasta > $output_file.out && touch $jobid.success
      echo "Done"
   fi

   echo "Extracting..."
   # split the reads
   cat $output_file.out |grep Read |awk '{print $2" "$5}'|grep haplotype0 |awk '{if (match($1, "_RQ")) { print substr($1, 1, index($1, "_RQ")-1)" 1 2000000"; } else if (match($1, "_fmh")) { print substr($1, 1, index($1, "_fmh")-1)" 1 2000000"; } else if (match($1, "_template_")) { print substr($1, 1, index($1, "_template_")-1)"_template 1 2000000"; } else if (match($1, "_runid")) { print substr($1, 1, index($1, "_runid")-1)" 1 2000000"; } else { print $1" 1 200000"}}' > $output_file.dam.cut
   cat $output_file.out  |grep Read |awk '{print $2" "$5}'|grep haplotype1 |awk '{if (match($1, "_RQ")) { print substr($1, 1, index($1, "_RQ")-1)" 1 2000000"; } else if (match($1, "_fmh")) { print substr($1, 1, index($1, "_fmh")-1)" 1 2000000"; } else if (match($1, "_template_")) { print substr($1, 1, index($1, "_template_")-1)"_template 1 2000000"; }  else if (match($1, "_runid")) { print substr($1, 1, index($1, "_runid")-1)" 1 2000000"; } else { print $1" 1 200000"}}' > $output_file.sire.cut
   cat $output_file.out  |grep Read |awk '{print $2" "$5}'|grep -v haplotype0 | grep -v haplotype1 |awk '{if (match($1, "_RQ")) { print substr($1, 1, index($1, "_RQ")-1)" 1 2000000"; } else if (match($1, "_fmh")) { print substr($1, 1, index($1, "_fmh")-1)" 1 2000000"; } else if (match($1, "_template_")) { print substr($1, 1, index($1, "_template_")-1)"_template 1 2000000"; } else if (match($1, "_runid")) { print substr($1, 1, index($1, "_runid")-1)" 1 2000000"; } else { print $1" 1 200000"}}' > $output_file.unknown.cut

   # get the sequences
   java SubFasta $output_file.dam.cut $input_file > $output_file.dam.fastq
   java SubFasta $output_file.sire.cut $input_file > $output_file.sire.fastq
   java SubFasta $output_file.unknown.cut $input_file > $output_file.unknown.fastq

   gzip $output_file*.fastq
   echo "Done"

   rm -f $output_file.fasta

   NUM_ACTUAL=`java SizeFasta $output_file*fastq.gz |wc -l`
   NUM_EXPECTED=`java SizeFasta $input_file |wc -l`
   if [ $NUM_ACTUAL -ne $NUM_EXPECTED ]; then
      echo "Error: expected $NUM_EXPECTED reads but total in classification is $NUM_ACTUAL"
      exit
   else
      echo "Done!"
   fi
else
   echo "Already done"
fi
