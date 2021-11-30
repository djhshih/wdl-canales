include bam_phi_estimation.task
include vcf_ffpe_filter.task

workflow bam_mobsnvf_ffpe{
	String sample_id
	File bam

	call bam_phi_estimation {
		input:
			sample_id = sample_id,
			bam = bam
	}

	call vcf_ffpe_filter {
		input:
			sample_id = sample_id,
			bam = bam,
			phi_json = bam_phi_estimation.phi
	}

	output {
		File ffpe_vcf = vcf_ffpe_filter.ffpe_fixed_vcf
		File phi = bam_phi_estimation.phi
	}
}
