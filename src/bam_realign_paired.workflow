include bam_to_fastq_paired.task
include fastq_bwa_mem_paired_sorted.task

workflow bam_realign_paired {
	String sample_id

	call bam_to_fastq_paired {
		input:
			sample_id = sample_id
	}

	call fastq_bwa_mem_paired_sorted {
		input:
			fastq_r1 = bam_to_fastq_paired.fastq_r1,
			fastq_r2 = bam_to_fastq_paired.fastq_r2,
			sample_id = sample_id
	}
}
