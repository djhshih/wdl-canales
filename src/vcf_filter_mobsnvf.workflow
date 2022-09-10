include bam_phi_estimation.task
include snv_mobsnvf_filter.task
include snv_fdr_filter.task
include snv_to_vcf.task
include vcf_mask_variants.task
include vcf_select_variants.task

workflow vcf_filter_mobsnvf {
	String sample_id
	String damage_type
	File bam

	call bam_phi_estimation {
		input:
			sample_id = sample_id,
			bam = bam,
			damage_type = damage_type
	}
	
	call snv_mobsnvf_filter {
		input: 
			sample_id = sample_id,
			bam = bam,
			damage_type = damage_type,
			phi_json = bam_phi_estimation.phi_json
	}

	call snv_fdr_filter {
		input:
			sample_id = sample_id,
			snv = snv_mobsnvf_filter.annotated_snv
	}

	call snv_to_vcf {
		input:
			sample_id = sample_id,
			snv = snv_fdr_filter.failed_snv
	}

	call vcf_mask_variants {
		input:
			sample_id = sample_id,
			mask_vcf = snv_to_vcf.ffpe_mask_vcf,
			mask_vcf_index = snv_to_vcf.ffpe_mask_vcf_idx
	}

	call vcf_select_variants {
		input:
			sample_id = sample_id,
			input_vcf = vcf_mask_variants.masked_vcf, 
			input_vcf_index = vcf_mask_variants.masked_vcf_index 
	}

	output {
		File ffpe_masked_vcf = vcf_mask_variants.masked_vcf
		File ffpe_masked_vcf_index = vcf_mask_variants.masked_vcf_index
		File ffpe_selected_vcf = vcf_select_variants.selected_vcf 
		File ffpe_selected_vcf_index = vcf_select_variants.selected_vcf_index
	}

}
