include bam_to_ubam.task
include ubam_bwa_mem_paired.task
include bam_sort_coord.task

workflow bam_realign_paired_faster {
	String sample_id

	call bam_to_ubam {
		input:
			sample_id = sample_id
	}

	call ubam_bwa_mem_paired {
		input:
			sample_id = sample_id
			input_ubam = bam_to_ubam.ubam
	}

	call bam_sort_coord {
		input:
			sample_id = sample_id
			input_bam = ubam_bwa_mem_paired.bam
	}
}
