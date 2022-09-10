include bam_phi_estimation.task
include vcf_filter_mobsnvf_ffpe.task

workflow vcf_mobsnvf_ffpe{
	String sample_id
	File vcf
	File bam

	call bam_phi_estimation {
		input:
			sample_id = sample_id,
			bam = bam
	}

	call vcf_filter_mobsnvf_ffpe {
		input:
			sample_id = sample_id,
			vcf = vcf,
			bam = bam,
			phi_json = bam_phi_estimation.phi
	}

	output {
		File filtered_vcf = vcf_filter_mobsnvf_ffpe.filtered_vcf
		File phi = bam_phi_estimation.phi
	}
}
