include bam_to_fastq_paired.task
include fastq_bwa_mem_paired.task
include bam_sort_coord.task
include csbam_mark_dup.task

workflow bam_realign_paired {
	String sample_id

	call bam_to_fastq_paired {
		input:
			sample_id = sample_id
	}

	call fastq_bwa_mem_paired {
		input:
			sample_id = sample_id,
			fastq_r1 = bam_to_fastq_paired.fastq_r1,
			fastq_r2 = bam_to_fastq_paired.fastq_r2
	}

	call bam_sort_coord {
		input:
			sample_id = sample_id,
			input_bam = fastq_bwa_mem_paired.bam	
	}

	call csbam_mark_dup {
		input:
			sample_id = sample_id,
			input_bam = bam_sort_coord.bam
	}
}
