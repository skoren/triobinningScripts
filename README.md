# triobinningScripts

Scripts used to generate results for the TrioBinning assembly paper. The data from that paper is available [here](https://gembox.cbcb.umd.edu/triobinning/index.html). 

The trio binning approach will be incorporated into [Canu](https://github.com/marbl/canu) as a module in an upcoming release. If you are assembling a new trio dataset, see the [Canu documentation](https://canu.readthedocs.io/en/latest/) for more information on how to run it.

## Installation
Requires BioPython. Includes canu as a sub-module dependency. 

## Running
These scripts should only be used if you are interesting in reproducing the results in the TrioBinning paper exactly. They are not optimized and are slow to run (classifying approximately 1000/reads per minute on a single CPU). There is an example script (classifyReads.sh and input.fofn) which show how to run classification in parallel on an SGE grid but must be submitted by the user and updated for user environment.

Example classifying an ecoli genome is in example/example.sh. It will download data for two E. coli strains and generate a binned assembly as well as a combined assembly for comparison.

The input for k-mer counting must be fasta formatted. If you have a fastq file you can run

`zcat $fastq | awk -v name=$name 'BEGIN {num=0} {if (NR%2000000==1) {num+=1; print ">"name"."num} } {if (NR%4==2) print $1"N"}' > $name.fa`

The shell script also has comments along the way but a brief outline of the steps:

* Count k-mers for both parents
* Subtract k-mers for each parent from the other to make two parent-specific k-mer sets
* Dump k-mers within good part of the distribution of each parent (plotting the counts) and excluding low-count (typically <10) and high count (typically > 100) copy k-mers
* Classify reads with provided python script
* Get fasta sets for each haplotype based on output of python script
* Generate assemblies.

The example assembles both E. coli strains in combination and separately. As an example, aligning to the K12 reference with MUMmer gives the following stats:

```
[Sequences]							[Sequences]
TotalSeqs                          1                  423     |	TotalSeqs                          1                    3
AlignedSeqs               1(100.00%)          417(98.58%)     |	AlignedSeqs               1(100.00%)            2(66.67%)
UnalignedSeqs               0(0.00%)             6(1.42%)     |	UnalignedSeqs               0(0.00%)            1(33.33%)

[Bases]								[Bases]
TotalBases                   4639560             10688138     |	TotalBases                   4639560              4665629
AlignedBases         4638011(99.97%)      9103771(85.18%)     |	AlignedBases        4639560(100.00%)      4647021(99.60%)
UnalignedBases           1549(0.03%)      1584367(14.82%)     |	UnalignedBases              0(0.00%)         18608(0.40%)

[Alignments]							[Alignments]
1-to-1                           236                  236     |	1-to-1                             8                    8
TotalLength                  5713731              5712169     |	TotalLength                  4644305              4644259
AvgLength                   24210.72             24204.11     |	AvgLength                  580538.12            580532.38
AvgIdentity                    98.81                98.81     |	AvgIdentity                    99.99                99.99
							      |
M-to-M                           938                  938     |	M-to-M                            12                   12
TotalLength                  9140017              9137274     |	TotalLength                  4647562              4647515
AvgLength                    9744.15              9741.23     |	AvgLength                  387296.83            387292.92
AvgIdentity                    98.55                98.55     |	AvgIdentity                    99.99                99.99
```

The result on the left is the combined assembly, fragmented into >400 contigs and only having 98.8% identity to the reference. In contrast, the haplotyped assembly has 1 contig covering the genome and is >99.99% identity.

### Using k-mers over 31
Modify the meryl code src/AS_UTL/kMer.H from
```
#define KMER_WORDS  1
```
to
```
#define KMER_WORDS  3
```
and src/AS_UTL/kMerHuge.H from
```
str[ms-i-1] = bitsToLetter[(mer >> (2*i)) & 0x03];
```
to
```
str[ms-i-1] = alphabet.bitsToLetter((mer >> (2*i)) & 0x03);
```
and re-compile

### Using other k-mer counters

The trio-binning approach is compatible with any k-mer counter, as long as you can generate the counts file in the expected format.

## Citation:
 - Koren S, Rhie A, et al. Trio binning enables complete assembly of individual haplotypes. In prep (2018).
