# Bin the child's read manually before assembly

## What is this update about?
This is a step-by-step binning script for building meryl db on parent illumina reads
and binning the child’s read yourself.

## What is this script doing
* Build meryl db from parental illumina dataset
* Filter erroneous k-mers
* Use meryl diff for getting haplotype specific k-mers from the parental illumina dataset
* Use simple-dump to dump a query db
* Use the query db instead of the python script for classifying the child’s long read

## Installation
This update uses meryl and simple-dump in canu 1.7 or higher.
Add canu/.../bin to your PATH.

## How to run
1. Build meryl db and count haplotype specific k-mers
Let’s say we have \<hapA\>_R\[1-2\]_001.fastq.gz and \<hapB\>_R\[1-2]_001.fastq.gz.
We want hapA and hapB k-mer sets, which contains all k-mers.
Given the k-mer count distribution, we can discard the erroneous k-mers.
```
./_meryl_submit.sh <k-size> <hapA> <hapB>
``` 
This script launches 
* _meryl_build.sh for each fastq file in array-jobs
* _meryl_mrg.sh per haplotype 
* Subtract with _meryl_diff.sh

At the end, you can get total descriptive k-mers and haplotype-specific k-mers.
```
meryl -Dc -s <hapA>.filt  # distinct mers are the descriptive k-mers
meryl -Dc -s <hapA>.no<hapB> # hapA specific mers
```

If you have illumina dataset of the child, you can run two more union operations to get the haplotype-specific k-mers found in the child’s genome.
```
meryl -M and -s <hapA>.no<hapB> -s <child> -o <child>_hapA
meryl -M and -s <hapB>.no<hapA> -s <child> -o <child>_hapB
```

Of note, all meryl -M commands are running on a single core.


### 2. Get haplotype specific k-mers
<i>If you have launched _meryl_submit.sh , you can skip this step.</i>

Let’s assume you have filtered \<hapA\>.mcdat and \<hapB\>.mcdat where \<hapA\> is made from maternal whole genome sequence reads and \<hapB\> from paternal.
```
./_meryl_diff.sh <k-size> <hapA> <hapB>
```
This script does a simple set difference operation over the two \<hapA\>.mcdat and \<hapB\>.mcdat. Next, it builds dumped db for fast querying.
Output is:
```
<hapA>.no<hapB>.mcdat
<hapA>.no<hapB>.mcidx
<hapB>.no<hapA>.mcdat
<hapB>.no<hapA>.mcidx
<hapA>.only
<hapB>.only
```
If you already have done the subtraction, just run the final line which runs the simple-dump.

### 3. Classify child’s read
Prepare fasta.list of the child’s long read fasta files, similar to .fofn. Each line is assumed to be a full path of the .fa file.

```
./_classify_submit.sh <k-size> <hapA>.only <hapB>.only
```
This will submit jobs in arrays, one for each fasta file.
* Of note: This script uses slurm sbatch.
Important output are:
```
classified/<hapA>/<file>.fa
classified/<hapB>/<file>.fa
classified/<unknown>/<file>.fa
classified/<file>.map
```

### 4. Canu on classified reads
Now, it is easy. Launch two canu jobs, or your favorite assembler, one pointing to the classified/\<hapA\> and the other to the classified/\<hapB\>.
Two assemblies will run simultaneously.
Done!



