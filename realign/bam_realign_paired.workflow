include bam_to_fastq_paired.task
include bwa_mem_paired.task

workflow bam_realign_paired {
	String sample_id

	call bam_to_fastq_paired {
		input:
			sample_id = sample_id
	}

	call bwa_mem_paired {
		input:
			fastq_r1 = bam_to_fastq_paired.fastq_r1,
			fastq_r2 = bam_to_fastq_paired.fastq_r2,
			sample_id = sample_id
	}
}
