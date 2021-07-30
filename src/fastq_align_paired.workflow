include fastq_bwa_mem_paired.task
include bam_sort_coord.task

workflow fastq_align_paired {
	String sample_id

	call fastq_bwa_mem_paired {
		input:
			sample_id = sample_id
	}

	call bam_sort_coord {
		input:
			sample_id = sample_id,
			input_bam = fastq_bwa_mem_paired.bam
	}
}
