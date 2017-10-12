task bwa_mem_paired {

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
		
		# align reads and create unsorted bam file
		/usr/gitc/bwa mem -t ${cpu} ${ref_fasta} ${fastq_r1} ${fastq_r2} \
			| samtools view -b - \
			> unsorted.bam
		
		# sort alignments
		samtools sort unsorted.bam -o sorted.bam
		rm unsorted.bam
		
		# mark duplicates
		java -jar /usr/gitc/picard.jar MarkDuplicates \
			INPUT=sorted.bam \
			OUTPUT=${sample_id}.bam \
			METRICS_FILE=${sample_id}_picard-mark-dup_metrics.txt
		rm sorted.bam
				
		# create index for the bam file
		samtools index ${sample_id}.bam ${sample_id}.bai
	>>>

	output {
		File bam = "${sample_id}.bam"
		File bai = "${sample_id}.bai"
		File markdup_metrics = "${sample_id}_picard-mark-dup_metrics.txt"
	}

	runtime {
		docker: "broadinstitute/genomes-in-the-cloud:2.3.1-1500064817"
		memory: "${memory_gb} GB"
		cpu: "${cpu}"
		disks: "local-disk ${diskspace} HDD"
	}

}
