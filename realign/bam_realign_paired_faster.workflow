include bwa_mem_paired_bam.task

workflow bam_realign_paired_faster {
	String sample_id

	call bwa_mem_paired_bam {
		input:
			sample_id = sample_id
	}
}
