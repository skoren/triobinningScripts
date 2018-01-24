# triobinningScripts

Scripts used to generate results for the TrioBinning assembly paper. 

## Installation
Requires BioPython. Includes canu as a sub-module dependency. 

## Running
Example scripts (classifyReads.sh and input.fofn) show how to run classification in parallel on an SGE grid.

Example classifying an ecoli genome is in examples/example.sh. It will download data for two E. coli strains and generate a binned assembly as well as a combined assembly for comparison.

## Learn

These scripts should only be used if you are interesting in reproducing the results in the TrioBinning paper exactly. They are not optimized and are slow to run. The data from that paper is available [here](https://gembox.cbcb.umd.edu/triobinning/index.html). 

The trio binning approach will be incorporated into [Canu](https://github.com/marbl/canu) as a module. If you are assembling a new trio dataset, see the [Canu documentation](https://canu.readthedocs.io/en/latest/) for more information on how to run it.

## Citation:
 - Koren S, Rhie A, et al. Trio binning enables complete assembly of individual haplotypes. In prep (2018).
