# Meryl diff on parent meryl DB and classify child's reads manually

## What is this update about?
Sometimes, you want to bin the reads your self. Yes, there is an easier way to do it, if you already have a meryl k-mer db built.

## What is this script doing
* Use meryl diff for getting haplotype specific k-mers from the parental illumina dataset
* Use simple-dump to dump a query db
* Use the query db instead of the python script for classifying the child’s long read

## Installation
This update uses meryl and simple-dump in canu 1.7 or higher.

## How to run
### 1. Get haplotype specific k-mers
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

### 2. Classify child’s read
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

### 3. Canu on classified reads
Now, it is easy. Launch two canu jobs, one pointing to the classified/\<hapA\> and the other to the classified/\<hapB\>.
Two assemblies will run simultaneously.
Done!



