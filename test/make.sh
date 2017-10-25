#!/bin/bash

dwgsim tp53.fasta -N 100 reads

bwa index -a bwtsw tp53.fasta

bwa mem tp53.fasta reads.bwa.read1.fastq reads.bwa.read2.fastq \
	| samtools view -b \
	> sample.bam

