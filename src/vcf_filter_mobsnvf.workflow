include bam_phi_estimation.task
include snv_mobsnvf_filter.task
include snv_fdr_filter.task
include vcf_to_header.task
include snv_to_vcf.task
include vcf_mask_variants.task
include vcf_select_variants.task

workflow vcf_filter_mobsnvf {
	String sample_id
	String damage_type
	File vcf
	File bam
	File bai

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
			bai = bai,
			snv = vcf,
			damage_type = damage_type,
			phi_json = bam_phi_estimation.phi_json
	}

	call snv_fdr_filter {
		input:
			sample_id = sample_id,
			snv = snv_mobsnvf_filter.annotated_snv
	}

	call vcf_to_header {
		input:
			vcf = vcf
	}

	call snv_to_vcf {
		input:
			out_name = sample_id,
			snv = snv_fdr_filter.failed_snv,
			vcf_header = vcf_to_header.header
	}

	call vcf_mask_variants {
		input:
			sample_id = sample_id,
			vcf = vcf,
			mask_vcf = snv_to_vcf.vcf,
			mask_vcf_index = snv_to_vcf.vcf_idx
	}

	call vcf_select_variants {
		input:
			sample_id = sample_id,
			vcf = vcf_mask_variants.masked_vcf, 
			vcf_index = vcf_mask_variants.masked_vcf_index 
	}

	output {
		File removed_vcf = snv_to_vcf.vcf
		File removed_vcf_index = snv_to_vcf.vcf_idx
		File selected_vcf = vcf_select_variants.selected_vcf 
		File selected_vcf_index = vcf_select_variants.selected_vcf_index
	}

}
