include vcf_select_variants.task

workflow vcf_rm_filtered {
	String sample_id
	File vcf
	File vcf_index

	call vcf_select_variants {
		input:
			sample_id = sample_id,
			vcf = vcf,
			vcf_index = vcf_index
	}
	
	output {
		File selected_vcf = vcf_select_variants.selected_vcf
		File selected_vcf_index = vcf_select_variants.selected_vcf_index
	}
}
