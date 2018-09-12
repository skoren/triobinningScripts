import sys
import math
import argparse

from Bio import SeqIO

def reverse_complement(kmer):
   complement = {'A': 'T', 'C': 'G', 'G': 'C', 'T': 'A'}
   return str("".join(complement.get(base, base) for base in reversed(kmer)))

def get_cannonical(kmer):
   rc = reverse_complement(kmer)
   if str(rc) < str(kmer):
      return rc
   else:
      return kmer

# used to decide how to classify
HAPLOTYPES = 2

# first load hap-specific mers
merSize = 0
haps = []

for i in range(0,HAPLOTYPES):
   f = open('%s'%(sys.argv[i+1]))
   haps.append({})
   for line in f:
      line = line.strip().split()[0].upper()
      haps[i][line] = 1
      if merSize == 0:
         merSize = len(line)
      else:
         if merSize != len(line):
            print "Error: expected %d-mer and got %s!"%(merSize, line)
            sys.exit(1)
   f.close()
   print >> sys.stderr, "Recorded %d haplpotype %d specfic %d-mers"%(len(haps[i]), i, merSize)

# now score read to chose a haplotype
#we process fasta
for i in range(HAPLOTYPES,len(sys.argv)):
   recs = [ (rec.name, str(rec.seq)) for rec in SeqIO.parse(open(sys.argv[i]), "fasta")]
   for name, seq in recs:
      readHap = ""
      readHapCount = 0
      secondBest = 0
      hapCounts = {}
      start = 0

      while start < len(seq)-merSize+1:
         end = start+merSize
         kmer=get_cannonical(seq[start:end].upper())
         start +=1
         for i in range(0, HAPLOTYPES):
            if kmer in haps[i]:
               if i not in hapCounts:
                  hapCounts[i] = 0
               hapCounts[i]+=1

      # scale by mers
      for i in range(0, HAPLOTYPES):
         if i in hapCounts:
            hapCounts[i] /= float(len(haps[i]))

      tot = 0
      for i in range(0, HAPLOTYPES):
         if i in hapCounts:
            tot+=hapCounts[i]
            if hapCounts[i] > 0 and hapCounts[i] < readHapCount and hapCounts[i] > secondBest:
               secondBest = hapCounts[i]

            if hapCounts[i] > 0 and hapCounts[i] > readHapCount:
               readHap = "haplotype%d"%(i)
               secondBest = readHapCount
               readHapCount = hapCounts[i]

      if secondBest == 0 and readHapCount != 0:
         print "Read %s classified as %s with %s"%(name, readHap, hapCounts)
      elif readHapCount == 0 and secondBest == 0:
         print "Read %s has no distringuising mers, ambiguous"%(name) 
      elif readHapCount == 0 and secondBest != 0:
         print "Not possible!"
         sys.exit(1)
      elif float(readHapCount) / secondBest > 1:
          print "Read %s classified as %s due to %f but second best existed with %f all counts %s"%(name, readHap, readHapCount, secondBest, hapCounts)
      else:
         print "Read %s is amibigous unalbe to classify due to %f and %f"%(name, readHapCount, secondBest) 
