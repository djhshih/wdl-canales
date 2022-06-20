include bam_phi_estimation.task
include snv_ffpe_oxog_filter.task
include snv_bh.task
include snv_to_vcf.task
include vcf_variant_filter.task
include vcf_select_variants.task

workflow vcf_hts_mobsnvf {
	String sample_id
	File bam

	call bam_phi_estimation {
		input:
			sample_id = sample_id,
			bam = bam
	}
	
	call snv_ffpe_oxog_filter {
		input: 
			sample_id = sample_id,
			bam = bam,
			phi_json = bam_phi_estimation.phi
	}

	call snv_bh {
		input:
			sample_id = sample_id,
			input_snv = snv_ffpe_oxog_filter.filtered_snv
	}

	call snv_to_vcf {
		input:
			sample_id = sample_id,
			input_snv = snv_bh.ffpe_mask_snv
	}


	call vcf_variant_filter {
		input:
			sample_id = sample_id,
			mask_vcf = snv_to_vcf.ffpe_mask_vcf,
			mask_vcf_index = snv_to_vcf.ffpe_mask_vcf_idx
	}

	call vcf_select_variants {
		input:
			sample_id = sample_id,
			input_vcf = vcf_variant_filter.masked_vcf, 
			input_vcf_index = vcf_variant_filter.masked_vcf_index 
	}

	output {
		File ffpe_masked_vcf = vcf_variant_filter.masked_vcf
		File ffpe_masked_vcf_index = vcf_variant_filter.masked_vcf_index
		File ffpe_selected_vcf = vcf_select_variants.selected_vcf 
		File ffpe_selected_vcf_index = vcf_select_variants.selected_vcf_index
	}

}
