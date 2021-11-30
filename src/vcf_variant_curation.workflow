include vcf_variant_filter.task
include vcf_select_variants.task

workflow vcf_variant_curation {
	String sample_id

	call vcf_variant_filter {
		input:
			sample_id = sample_id
	}

	call vcf_select_variants {
		input:
			sample_id = sample_id,
			input_vcf = vcf_variant_filter.masked_vcf,
			input_vcf_index = vcf_variant_filter.masked_vcf_index
	}
	
	output {
		File masked_vcf = vcf_variant_filter.masked_vcf
		File masked_vcf_index = vcf_variant_filter.masked_vcf_index
		File selected_vcf = vcf_select_variants.selected_vcf
		File selected_vcf_index = vcf_select_variants.selected_vcf_index
	}
}
