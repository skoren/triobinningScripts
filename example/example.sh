cd ../canu/src
make -j8
cd -

cd ../meryl/src
make -j8
cd -

wget https://gembox.cbcb.umd.edu/triobinning/example/k12.12.fasta
wget https://gembox.cbcb.umd.edu/triobinning/example/o157.12.fasta
wget https://gembox.cbcb.umd.edu/triobinning/example/pacbio.fasta

# count
../meryl/*/bin/meryl -threads 16 -B -C -m 16 -s k12.12.fasta -o k12
../meryl/*/bin/meryl -threads 16 -B -C -m 16 -s o157.12.fasta -o o157

# subtract
../meryl/*/bin/meryl -M difference -s k12 -s o157 -o k12.only
 ../meryl/*/bin/meryl -M difference -s o157 -s k12 -o o157.only

# get sets
../meryl/*/bin/meryl -Dt -n 25 -s k12.only |awk '{if (match($1,">")) { COUNT=substr($1, 2, length($1)); } else {print $1" "COUNT}}' |awk '{if ($NF < 150) print $0}' >  k12.counts
../meryl/*/bin/meryl -Dt -n 25 -s o157.only |awk '{if (match($1,">")) { COUNT=substr($1, 2, length($1)); } else {print $1" "COUNT}}' |awk '{if ($NF < 150) print $0}' >  o157.counts

# classify
python ../classify.py k12.counts o157.counts pacbio.fasta > pacbio.out

# get read stats
echo "For K12 classify stats:"
cat pacbio.out |grep Read |grep K12 |awk '{if ($5 == "haplotype0") { print "CORRECT"; } else { print "WRONG"}}'|sort |uniq -c

echo ""
echo "For O157 classify stats:"
cat pacbio.out |grep Read |grep O157 |awk '{if ($5 == "haplotype0") { print "WRONG"; } else { print "CORRECT"}}'|sort |uniq -c

# get reads and assemble
cat pacbio.out |grep Read |grep haplotype0 |awk '{print $2" 1 200000"}' > k12.cut
cat pacbio.out |grep Read |grep haplotype1 |awk '{print $2" 1 200000"}' > o157.cut
java -cp ../ SubFasta k12.cut pacbio.fasta > k12.fasta
java -cp ../ SubFasta o157.cut pacbio.fasta > o157.fasta
../canu/*/bin/canu -p asm -d k12 useGrid=false genomeSize=5m -pacbio-raw k12.fasta
../canu/*/bin/canu -p asm -d o157 useGrid=false genomeSize=5m -pacbio-raw o157.fasta
