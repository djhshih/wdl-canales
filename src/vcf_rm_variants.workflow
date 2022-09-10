include vcf_mask_variants.task
include vcf_select_variants.task

workflow vcf_rm_variants {
	String sample_id
	File vcf
	File rm_vcf

	call vcf_mask_variants {
		input:
			sample_id = sample_id,
			vcf = vcf,
			mask_vcf = rm_vcf
	}

	call vcf_select_variants {
		input:
			sample_id = sample_id,
			vcf = vcf_mask_variants.masked_vcf,
			vcf_index = vcf_mask_variants.masked_vcf_index
	}
	
	output {
		File removed_vcf = vcf_mask_variants.masked_vcf
		File removed_vcf_index = vcf_mask_variants.masked_vcf_index
		File selected_vcf = vcf_select_variants.selected_vcf
		File selected_vcf_index = vcf_select_variants.selected_vcf_index
	}
}
