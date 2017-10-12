task bwa_mem_paired_fast {

	File ref_fasta
	# NB  64-bit bwa index files should be used
	File ref_fasta_amb
	File ref_fasta_ann
	File ref_fasta_bwt
	File ref_fasta_pac
	File ref_fasta_sa
	File fastq_r1
	File fastq_r2
	String sample_id

	Int preemptible_tries = 3
	Float diskspace = ceil(4 * (size(fastq_r1, "GB") + size(fastq_r2, "GB")))
	Int cpu = 8
	Int memory_gb = 30

	command <<<
		set -eu
		
		if [[ ! -f $ref_fasta_sa ]]; then
			#	index the reference fasta if it is missing
			/usr/gitc/bwa index -a bwtsw ${ref_fasta}
		fi
		
		# align reads, mark duplicates, and create unsorted bam file with fast compression
		# difference in duplicate marking between samblaster and Picard:
		#  the first encountered read-pair of a duplicate set will considered as the 
		#  prototype instead of the 'best' read-pair
		/usr/gitc/bwa mem -t ${cpu} ${ref_fasta} ${fastq_r1} ${fastq_r2} \
			| samblaster | samtools view -b1 - \
			> unsorted.bam
		
		# sort alignments with ample RAM to avoid disk IO and create final bam file
		sambamba sort -m ${memory_gb}GB unsorted.bam -o ${sample_id}.bam
		rm unsorted.bam
		
		# create index for the bam file with ample threads
		sambamba -t ${cpu} index ${sample_id}.bam ${sample_id}.bai
	>>>

	output {
		File bam = "${sample_id}.bam"
		File bai = "${sample_id}.bai"
	}

	runtime {
		docker: "djhshih/seqkit:0.1"
		memory: "${memory_gb} GB"
		cpu: "${cpu}"
		disks: "local-disk ${diskspace} HDD"
	}

}
