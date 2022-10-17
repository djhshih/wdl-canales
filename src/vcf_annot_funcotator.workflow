version 1.0

include runtime.struct
include vcf_annot_funcotator.task

workflow vcf_annot_funcotator {
	input {
		File? intervals
		File ref_fasta
		File ref_fai
		File ref_dict
		File funcotate_vcf_input
		File funcotate_vcf_input_index
		File? funco_data_sources
		File? funco_data_sources_tar_gz

		# default version is "hg19"
		String? funco_reference_version
		# default format is "MAF"
		String? funco_output_format
		String funco_default_output_format = "MAF"

		# default is false
		Boolean? funco_compress
		# default is false
		Boolean? funco_use_gnomad_AF

		String? case_id
		String? control_id

		File? gnomad
		File? gnomad_idx

		String? sequencing_center
		String? sequence_source
		String? funco_transcript_selection_mode
		File? funco_transcript_selection_list

		Array[String]? funco_annotation_defaults
		Array[String]? funco_annotation_overrides
		Array[String]? funcotator_excluded_fields
		#Boolean? funco_filter_funcotations
		String? funcotator_extra_args

		# runtime
		String gatk_docker
		File? gatk_override
		String basic_bash_docker = "ubuntu:16.04"
		Boolean? filter_funcotations

		Int? preemptible
		Int? max_retries
		Int small_task_cpu = 2
		Int small_task_mem = 4
		Int small_task_disk = 100
		Int boot_disk_size = 12
		Int learn_read_orientation_mem = 8000
		Int filter_alignment_artifacts_mem = 9000

		# Use as a last resort to increase the disk given to every task in case of ill behaving data
		Int? emergency_extra_disk

		# These are multipliers to multipler inputs by to make sure we have enough disk to accommodate for possible output sizes
		# Large is for Bams/WGS vcfs
		# Small is for metrics/other vcfs
		Float large_input_to_output_multiplier = 2.25
		Float small_input_to_output_multiplier = 2.0
	}

	Int preemptible_or_default = select_first([preemptible, 2])
	Int max_retries_or_default = select_first([max_retries, 2])

	Boolean filter_funcotations_or_default = select_first([filter_funcotations, true])

	# Disk sizes used for dynamic sizing
	Int ref_size = ceil(size(ref_fasta, "GB") + size(ref_dict, "GB") + size(ref_fai, "GB"))
	Int gnomad_vcf_size = if defined(gnomad) then ceil(size(gnomad, "GB")) else 0

	# If no tar is provided, the task downloads one from broads ftp server
	Int funco_tar_size = if defined(funco_data_sources_tar_gz) then ceil(size(funco_data_sources_tar_gz, "GB") * 3) else 100
	Int gatk_override_size = if defined(gatk_override) then ceil(size(gatk_override, "GB")) else 0

	# This is added to every task as padding, should increase if systematically you need more disk for every call
	Int disk_pad = 10 + gatk_override_size + select_first([emergency_extra_disk,0])

	# logic about output file names -- these are the names *without* .vcf extensions

	Runtime standard_runtime = {"gatk_docker": gatk_docker, "gatk_override": gatk_override,
						"max_retries": max_retries_or_default, "preemptible": preemptible_or_default, "cpu": small_task_cpu,
						"machine_mem": small_task_mem * 1000, "command_mem": small_task_mem * 1000 - 500,
						"disk": small_task_disk + disk_pad, "boot_disk_size": boot_disk_size}


	call vcf_annot_funcotator {
			input:
					ref_fasta = ref_fasta,
					ref_fai = ref_fai,
					ref_dict = ref_dict,
					input_vcf = funcotate_vcf_input,
					input_vcf_idx = funcotate_vcf_input_index,
					reference_version = select_first([funco_reference_version, "hg19"]),
					output_file_base_name = basename(funcotate_vcf_input, ".vcf") + ".annotated",
					output_format = if defined(funco_output_format) then "" + funco_output_format else funco_default_output_format,
					compress = if defined(funco_compress) then select_first([funco_compress]) else false,
					use_gnomad = if defined(funco_use_gnomad_AF) then select_first([funco_use_gnomad_AF]) else false,
					data_sources = funco_data_sources,
					data_sources_tar_gz = funco_data_sources_tar_gz,
					case_id = case_id,
					control_id = control_id,
					sequencing_center = sequencing_center,
					sequence_source = sequence_source,
					transcript_selection_mode = funco_transcript_selection_mode,
					transcript_selection_list = funco_transcript_selection_list,
					annotation_defaults = funco_annotation_defaults,
					annotation_overrides = funco_annotation_overrides,
					funcotator_excluded_fields = funcotator_excluded_fields,
					filter_funcotations = filter_funcotations_or_default,
					extra_args = funcotator_extra_args,
					runtime_params = standard_runtime,
					disk_space = ceil(size(funcotate_vcf_input, "GB") * large_input_to_output_multiplier) + funco_tar_size + disk_pad
	}

	output {
			File output_file = vcf_annot_funcotator.output_file
			File output_file_index = vcf_annot_funcotator.output_file_index
	}
}
