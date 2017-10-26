#!/bin/bash

# Simulate aligned reads for Illumin pair-end sequencing

# Requires:
#   - dwgsim
#   - bwa
#   - samtools

set -o errexit
set -o nounset

sample=S01
library=$sample
platform=Illumina
barcode=GCCGTCGA-AGGTACCA
unit=HJJ5JADXX150514

ref=$(pwd)/ref/tp53.fasta

bwa index -a bwtsw $ref

tmpdir=$(mktemp -d ./tmp.XXXXXX) && cd $tmpdir && echo $tmpdir

nreads=100
lanes=(L01 L02)

# simulate Illumina pair-end reads
dwgsim $ref -N $nreads ${sample}

# split reads into two lanes (hard-coded)
# 50 reads * 4 lines per read = 200 lines
head -n 200 ${sample}.bwa.read1.fastq > ${sample}-L01.bwa.read1.fastq
tail -n 200 ${sample}.bwa.read1.fastq > ${sample}-L02.bwa.read1.fastq
head -n 200 ${sample}.bwa.read2.fastq > ${sample}-L01.bwa.read2.fastq
tail -n 200 ${sample}.bwa.read2.fastq > ${sample}-L02.bwa.read2.fastq


# for reads from each lane, align to reference and sort reads
for lane in ${lanes[@]}; do

	bwa mem $ref ${sample}-${lane}.bwa.read1.fastq ${sample}-${lane}.bwa.read2.fastq \
		| samtools view -b \
		> ${sample}-${lane}.aligned.bam

	samtools sort ${sample}-${lane}.aligned.bam -o ${sample}-${lane}.bam
	rm ${sample}-${lane}.aligned.bam

	printf "@RG\tID:${sample}-${lane}\tSM:${sample}\tLB:${library}\tPL:${platform}\tPU:${unit}.${lane}.${barcode}\n" >> rg.txt
done

# merge bam files from all lanes
samtools merge -rh rg.txt ${sample}.bam ${sample}-*.bam
rm ${sample}-*.bam
rm -f rg.txt

# index the bam file
samtools index ${sample}.bam ${sample}.bai

cd -
mv $tmpdir/${sample}.{bam,bai} .

