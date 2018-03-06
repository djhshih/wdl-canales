include maf_filter_oxog_legacy.task
include maf_filter_ffpe_legacy.task

workflow maf_filter_orient_bias_legacy {
	String sample_id
	File input_bam
	File input_bai
	File ref_fasta
	File ref_fasta_fai

	call maf_filter_oxog_legacy {
		input:
			sample_id = sample_id,
			input_bam = input_bam,
			input_bai = input_bai,
			ref_fasta = ref_fasta,
			ref_fasta_fai = ref_fasta_fai
	}

	call maf_filter_ffpe_legacy {
		input:
			sample_id = sample_id,
			input_bam = input_bam,
			input_bai = input_bai,
			ref_fasta = ref_fasta,
			ref_fasta_fai = ref_fasta_fai,
			input_maf = maf_filter_oxog_legacy.filtered_maf
	}
}
