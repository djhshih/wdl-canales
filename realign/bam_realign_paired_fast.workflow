include bam_to_fastq_paired_fast.task
include bwa_mem_paired_fast.task

workflow bam_realign_paired_fast {
	String sample_id

	call bam_to_fastq_paired_fast {
		input:
			sample_id = sample_id
	}

	call bwa_mem_paired_fast {
		input:
			fastq_r1_r2 = bam_to_fastq_paired_fast.fastq_r1_r2,
			sample_id = sample_id
	}
}
