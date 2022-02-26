version 1.0

# Workflow for running the GATK CNV pipeline on a matched pair. Supports both WGS and WES.
#
# Notes:
#
# - The intervals argument is required for both WGS and WES workflows and accepts formats compatible with the
#   GATK -L argument (see https://gatkforums.broadinstitute.org/gatk/discussion/11009/intervals-and-interval-lists).
#   These intervals will be padded on both sides by the amount specified by padding (default 250)
#   and split into bins of length specified by bin_length (default 1000; specify 0 to skip binning,
#   e.g., for WES).  For WGS, the intervals should simply cover the autosomal chromosomes (sex chromosomes may be
#   included, but care should be taken to 1) avoid creating panels of mixed sex, and 2) denoise case samples only
#   with panels containing only individuals of the same sex as the case samples).
#
# - Intervals can be blacklisted from coverage collection and all downstream steps by using the blacklist_intervals
#   argument, which accepts formats compatible with the GATK -XL argument
#   (see https://gatkforums.broadinstitute.org/gatk/discussion/11009/intervals-and-interval-lists).
#   This may be useful for excluding centromeric regions, etc. from analysis.  Alternatively, these regions may
#   be manually filtered from the final callset.
#
#  A reasonable blacklist for excluded intervals (-XL) can be found at:
#   hg19: gs://gatk-best-practices/somatic-b37/CNV_and_centromere_blacklist.hg19.list
#   hg38: gs://gatk-best-practices/somatic-hg38/CNV_and_centromere_blacklist.hg38liftover.list (untested)
#
# - The sites file (common_sites) should be a Picard or GATK-style interval list.  This is a list of sites
#   of known variation at which allelic counts will be collected for use in modeling minor-allele fractions.
#
# - If you opt to run FuncotateSegments (i.e. set `is_run_funcotator` to `true`), then please also ensure that you have
#       the correct value for `funcotator_ref_version`.  Treat `funcotator_ref_version` as required if
#       `is_run_funcotator` is `true`.  Valid values for `funcotator_ref_version` are `hg38` and `hg19`.
#       The latter includes GRCh37.
#
#
# - Example invocation:
#
#       java -jar cromwell.jar run cnv_somatic_pair_workflow.wdl -i my_parameters.json
#
#############

include intervals_preprocess_intervals.task
include bam_collect_counts.task
include bam_collect_allelic_counts.task
include counts_denoise_read_counts.task
include counts_model_segments.task
include copy_ratio_segments_call.task
include denoised_copy_ratios_plot.task
include denoised_copy_ratios_plot_modeled_segments.task


workflow bam_cnv_somatic_pair {
    input {
      ##################################
      #### required basic arguments ####
      ##################################
      File common_sites
      File intervals
      File? blacklist_intervals
      File tumor_bam
      File tumor_bam_idx
      File? normal_bam
      File? normal_bam_idx
      File read_count_pon
      File ref_fasta_dict
      File ref_fasta_fai
      File ref_fasta
      String gatk_docker

      ##################################
      #### optional basic arguments ####
      ##################################
       # For running oncotator
     # Boolean? is_run_oncotator
       # For running funcotator
     # Boolean? is_run_funcotator

      File? gatk4_jar_override
      Int? preemptible_attempts
      # Use as a last resort to increase the disk given to every task in case of ill behaving data
      Int? emergency_extra_disk

      # Required if BAM/CRAM is in a requester pays bucket
      String? gcs_project_for_requester_pays

      ###############################################################
      #### optional arguments for intervals_preprocess_intervals ####
      ###############################################################
      Int? padding
      Int? bin_length
      Int? mem_gb_for_preprocess_intervals

      ##################################################
      #### optional arguments for bam_collect_counts ###
      ##################################################
      String? collect_counts_format
      Int? mem_gb_for_collect_counts

      ###########################################################
      #### optional arguments for bam_collect_allelic_counts ####
      String? minimum_base_quality
      Int? mem_gb_for_collect_allelic_counts

      ###########################################################
      #### optional arguments for counts_denoise_read_counts ####
      ###########################################################
      Int? number_of_eigensamples
      Int? mem_gb_for_denoise_read_counts

      ######################################################
      #### optional arguments for counts_model_segments ####
      ######################################################
      Int? max_num_segments_per_chromosome
      Int? min_total_allele_count
      Int? min_total_allele_count_normal
      Float? genotyping_homozygous_log_ratio_threshold
      Float? genotyping_base_error_rate
      Float? kernel_variance_copy_ratio
      Float? kernel_variance_allele_fraction
      Float? kernel_scaling_allele_fraction
      Int? kernel_approximation_dimension
      Array[Int]+? window_sizes = [8, 16, 32, 64, 128, 256]
      Float? num_changepoints_penalty_factor
      Float? minor_allele_fraction_prior_alpha
      Int? num_samples_copy_ratio
      Int? num_burn_in_copy_ratio
      Int? num_samples_allele_fraction
      Int? num_burn_in_allele_fraction
      Float? smoothing_threshold_copy_ratio
      Float? smoothing_threshold_allele_fraction
      Int? max_num_smoothing_iterations
      Int? num_smoothing_iterations_per_fit
      Int? mem_gb_for_model_segments

      #########################################################
      #### optional arguments for copy_ratio_segments_call ####
      #########################################################
      Float? neutral_segment_copy_ratio_lower_bound
      Float? neutral_segment_copy_ratio_upper_bound
      Float? outlier_neutral_segment_copy_ratio_z_score_threshold
      Float? calling_copy_ratio_z_score_threshold
      Int? mem_gb_for_call_copy_ratio_segments

      #########################################
      #### optional arguments for plotting ####
      #########################################
      Int? minimum_contig_length
      # If maximum_copy_ratio = Infinity, the maximum copy ratio will be automatically determined
      String? maximum_copy_ratio
      Float? point_size_copy_ratio
      Float? point_size_allele_fraction
      Int? mem_gb_for_plotting
}
    Int ref_size = ceil(size(ref_fasta, "GB") + size(ref_fasta_dict, "GB") + size(ref_fasta_fai, "GB"))
    Int read_count_pon_size = ceil(size(read_count_pon, "GB"))
    Int tumor_bam_size = ceil(size(tumor_bam, "GB") + size(tumor_bam_idx, "GB"))
    Int normal_bam_size = if defined(normal_bam) then ceil(size(normal_bam, "GB") + size(normal_bam_idx, "GB")) else 0

    Int gatk4_override_size = if defined(gatk4_jar_override) then ceil(size(gatk4_jar_override, "GB")) else 0
    # This is added to every task as padding, should increase if systematically you need more disk for every call
    Int disk_pad = 20 + ceil(size(intervals, "GB")) + ceil(size(common_sites, "GB")) + gatk4_override_size + select_first([emergency_extra_disk, 0])

    File final_normal_bam = select_first([normal_bam, "null"])
    File final_normal_bam_idx = select_first([normal_bam_idx, "null"])

    Int preprocess_intervals_disk = ref_size + disk_pad
    call intervals_preprocess_intervals {
        input:
            intervals = intervals,
            blacklist_intervals = blacklist_intervals,
            ref_fasta = ref_fasta,
            ref_fasta_fai = ref_fasta_fai,
            ref_fasta_dict = ref_fasta_dict,
            padding = padding,
            bin_length = bin_length,
            gatk4_jar_override = gatk4_jar_override,
            gatk_docker = gatk_docker,
            mem_gb = mem_gb_for_preprocess_intervals,
            disk_space_gb = preprocess_intervals_disk,
            preemptible_attempts = preemptible_attempts
    }

    Int collect_counts_tumor_disk = tumor_bam_size + ceil(size(intervals_preprocess_intervals.preprocessed_intervals, "GB")) + disk_pad
    call bam_collect_counts as CollectCountsTumor {
        input:
            intervals = intervals_preprocess_intervals.preprocessed_intervals,
            bam = tumor_bam,
            bam_idx = tumor_bam_idx,
            ref_fasta = ref_fasta,
            ref_fasta_fai = ref_fasta_fai,
            ref_fasta_dict = ref_fasta_dict,
            format = collect_counts_format,
            enable_indexing = false,
            gatk4_jar_override = gatk4_jar_override,
            gatk_docker = gatk_docker,
            mem_gb = mem_gb_for_collect_counts,
            disk_space_gb = collect_counts_tumor_disk,
            preemptible_attempts = preemptible_attempts,
            gcs_project_for_requester_pays = gcs_project_for_requester_pays
    }

    Int collect_allelic_counts_tumor_disk = tumor_bam_size + ref_size + disk_pad
    call bam_collect_allelic_counts as CollectAllelicCountsTumor {
        input:
            common_sites = common_sites,
            bam = tumor_bam,
            bam_idx = tumor_bam_idx,
            ref_fasta = ref_fasta,
            ref_fasta_dict = ref_fasta_dict,
            ref_fasta_fai = ref_fasta_fai,
            minimum_base_quality =  minimum_base_quality,
            gatk4_jar_override = gatk4_jar_override,
            gatk_docker = gatk_docker,
            mem_gb = mem_gb_for_collect_allelic_counts,
            disk_space_gb = collect_allelic_counts_tumor_disk,
            preemptible_attempts = preemptible_attempts,
            gcs_project_for_requester_pays = gcs_project_for_requester_pays
    }

    Int denoise_read_counts_tumor_disk = read_count_pon_size + ceil(size(CollectCountsTumor.counts, "GB")) + disk_pad
    call counts_denoise_read_counts as DenoiseReadCountsTumor {
        input:
            entity_id = CollectCountsTumor.entity_id,
            read_counts = CollectCountsTumor.counts,
            read_count_pon = read_count_pon,
            number_of_eigensamples = number_of_eigensamples,
            gatk4_jar_override = gatk4_jar_override,
            gatk_docker = gatk_docker,
            mem_gb = mem_gb_for_denoise_read_counts,
            disk_space_gb = denoise_read_counts_tumor_disk,
            preemptible_attempts = preemptible_attempts
    }

    Int model_segments_normal_portion = if defined(normal_bam) then ceil(size(CollectAllelicCountsNormal.allelic_counts, "GB")) else 0
    Int model_segments_tumor_disk = ceil(size(DenoiseReadCountsTumor.denoised_copy_ratios, "GB")) + ceil(size(CollectAllelicCountsTumor.allelic_counts, "GB")) + model_segments_normal_portion + disk_pad
    call counts_model_segments as ModelSegmentsTumor {
        input:
            entity_id = CollectCountsTumor.entity_id,
            denoised_copy_ratios = DenoiseReadCountsTumor.denoised_copy_ratios,
            allelic_counts = CollectAllelicCountsTumor.allelic_counts,
            normal_allelic_counts = CollectAllelicCountsNormal.allelic_counts,
            max_num_segments_per_chromosome = max_num_segments_per_chromosome,
            min_total_allele_count = min_total_allele_count,
            min_total_allele_count_normal = min_total_allele_count_normal,
            genotyping_homozygous_log_ratio_threshold = genotyping_homozygous_log_ratio_threshold,
            genotyping_base_error_rate = genotyping_base_error_rate,
            kernel_variance_copy_ratio = kernel_variance_copy_ratio,
            kernel_variance_allele_fraction = kernel_variance_allele_fraction,
            kernel_scaling_allele_fraction = kernel_scaling_allele_fraction,
            kernel_approximation_dimension = kernel_approximation_dimension,
            window_sizes = window_sizes,
            num_changepoints_penalty_factor = num_changepoints_penalty_factor,
            minor_allele_fraction_prior_alpha = minor_allele_fraction_prior_alpha,
            num_samples_copy_ratio = num_samples_copy_ratio,
            num_burn_in_copy_ratio = num_burn_in_copy_ratio,
            num_samples_allele_fraction = num_samples_allele_fraction,
            num_burn_in_allele_fraction = num_burn_in_allele_fraction,
            smoothing_threshold_copy_ratio = smoothing_threshold_copy_ratio,
            smoothing_threshold_allele_fraction = smoothing_threshold_allele_fraction,
            max_num_smoothing_iterations = max_num_smoothing_iterations,
            num_smoothing_iterations_per_fit = num_smoothing_iterations_per_fit,
            gatk4_jar_override = gatk4_jar_override,
            gatk_docker = gatk_docker,
            mem_gb = mem_gb_for_model_segments,
            disk_space_gb = model_segments_tumor_disk,
            preemptible_attempts = preemptible_attempts
    }

    Int copy_ratio_segments_tumor_disk = ceil(size(DenoiseReadCountsTumor.denoised_copy_ratios, "GB")) + ceil(size(ModelSegmentsTumor.copy_ratio_only_segments, "GB")) + disk_pad
    call copy_ratio_segments_call as CallCopyRatioSegmentsTumor {
        input:
            entity_id = CollectCountsTumor.entity_id,
            copy_ratio_segments = ModelSegmentsTumor.copy_ratio_only_segments,
            neutral_segment_copy_ratio_lower_bound = neutral_segment_copy_ratio_lower_bound,
            neutral_segment_copy_ratio_upper_bound = neutral_segment_copy_ratio_upper_bound,
            outlier_neutral_segment_copy_ratio_z_score_threshold = outlier_neutral_segment_copy_ratio_z_score_threshold,
            calling_copy_ratio_z_score_threshold = calling_copy_ratio_z_score_threshold,
            gatk4_jar_override = gatk4_jar_override,
            gatk_docker = gatk_docker,
            mem_gb = mem_gb_for_call_copy_ratio_segments,
            disk_space_gb = copy_ratio_segments_tumor_disk,
            preemptible_attempts = preemptible_attempts
    }

    # The F=files from other tasks are small enough to just combine into one disk variable and pass to the tumor plotting tasks
    Int plot_tumor_disk = ref_size + ceil(size(DenoiseReadCountsTumor.standardized_copy_ratios, "GB")) + ceil(size(DenoiseReadCountsTumor.denoised_copy_ratios, "GB")) + ceil(size(ModelSegmentsTumor.het_allelic_counts, "GB")) + ceil(size(ModelSegmentsTumor.modeled_segments, "GB")) + disk_pad
    call denoised_copy_ratios_plot as PlotDenoisedCopyRatiosTumor {
        input:
            entity_id = CollectCountsTumor.entity_id,
            standardized_copy_ratios = DenoiseReadCountsTumor.standardized_copy_ratios,
            denoised_copy_ratios = DenoiseReadCountsTumor.denoised_copy_ratios,
            ref_fasta_dict = ref_fasta_dict,
            minimum_contig_length = minimum_contig_length,
            maximum_copy_ratio = maximum_copy_ratio,
            point_size_copy_ratio = point_size_copy_ratio,
            gatk4_jar_override = gatk4_jar_override,
            gatk_docker = gatk_docker,
            mem_gb = mem_gb_for_plotting,
            disk_space_gb = plot_tumor_disk,
            preemptible_attempts = preemptible_attempts
    }

    call denoised_copy_ratios_plot_modeled_segments as PlotModeledSegmentsTumor {
        input:
            entity_id = CollectCountsTumor.entity_id,
            denoised_copy_ratios = DenoiseReadCountsTumor.denoised_copy_ratios,
            het_allelic_counts = ModelSegmentsTumor.het_allelic_counts,
            modeled_segments = ModelSegmentsTumor.modeled_segments,
            ref_fasta_dict = ref_fasta_dict,
            minimum_contig_length = minimum_contig_length,
            maximum_copy_ratio = maximum_copy_ratio,
            point_size_copy_ratio = point_size_copy_ratio,
            point_size_allele_fraction = point_size_allele_fraction,
            gatk4_jar_override = gatk4_jar_override,
            gatk_docker = gatk_docker,
            mem_gb = mem_gb_for_plotting,
            disk_space_gb = plot_tumor_disk,
            preemptible_attempts = preemptible_attempts
    }

    Int collect_counts_normal_disk = normal_bam_size + ceil(size(intervals_preprocess_intervals.preprocessed_intervals, "GB")) + disk_pad
    if (defined(normal_bam)) {
        call bam_collect_counts as CollectCountsNormal {
            input:
                intervals = intervals_preprocess_intervals.preprocessed_intervals,
                bam = final_normal_bam,
                bam_idx = final_normal_bam_idx,
                ref_fasta = ref_fasta,
                ref_fasta_fai = ref_fasta_fai,
                ref_fasta_dict = ref_fasta_dict,
                format = collect_counts_format,
                enable_indexing = false,
                gatk4_jar_override = gatk4_jar_override,
                gatk_docker = gatk_docker,
                mem_gb = mem_gb_for_collect_counts,
                disk_space_gb = collect_counts_normal_disk,
                preemptible_attempts = preemptible_attempts,
                gcs_project_for_requester_pays = gcs_project_for_requester_pays
        }

        Int collect_allelic_counts_normal_disk = normal_bam_size + ref_size + disk_pad
        call bam_collect_allelic_counts as CollectAllelicCountsNormal {
            input:
                common_sites = common_sites,
                bam = final_normal_bam,
                bam_idx = final_normal_bam_idx,
                ref_fasta = ref_fasta,
                ref_fasta_dict = ref_fasta_dict,
                ref_fasta_fai = ref_fasta_fai,
                minimum_base_quality =  minimum_base_quality,
                gatk4_jar_override = gatk4_jar_override,
                gatk_docker = gatk_docker,
                mem_gb = mem_gb_for_collect_allelic_counts,
                disk_space_gb = collect_allelic_counts_normal_disk,
                preemptible_attempts = preemptible_attempts,
                gcs_project_for_requester_pays = gcs_project_for_requester_pays
        }

        Int denoise_read_counts_normal_disk = read_count_pon_size + ceil(size(CollectCountsNormal.counts, "GB")) + disk_pad
        call counts_denoise_read_counts as DenoiseReadCountsNormal {
            input:
                entity_id = CollectCountsNormal.entity_id,
                read_counts = CollectCountsNormal.counts,
                read_count_pon = read_count_pon,
                number_of_eigensamples = number_of_eigensamples,
                gatk4_jar_override = gatk4_jar_override,
                gatk_docker = gatk_docker,
                mem_gb = mem_gb_for_denoise_read_counts,
                disk_space_gb = denoise_read_counts_normal_disk,
                preemptible_attempts = preemptible_attempts
        }

        Int model_segments_normal_disk = ceil(size(DenoiseReadCountsNormal.denoised_copy_ratios, "GB")) + ceil(size(CollectAllelicCountsNormal.allelic_counts, "GB")) + disk_pad
        call counts_model_segments as ModelSegmentsNormal {
            input:
                entity_id = CollectCountsNormal.entity_id,
                denoised_copy_ratios = DenoiseReadCountsNormal.denoised_copy_ratios,
                allelic_counts = CollectAllelicCountsNormal.allelic_counts,
                max_num_segments_per_chromosome = max_num_segments_per_chromosome,
                min_total_allele_count = min_total_allele_count_normal,
                genotyping_homozygous_log_ratio_threshold = genotyping_homozygous_log_ratio_threshold,
                genotyping_base_error_rate = genotyping_base_error_rate,
                kernel_variance_copy_ratio = kernel_variance_copy_ratio,
                kernel_variance_allele_fraction = kernel_variance_allele_fraction,
                kernel_scaling_allele_fraction = kernel_scaling_allele_fraction,
                kernel_approximation_dimension = kernel_approximation_dimension,
                window_sizes = window_sizes,
                num_changepoints_penalty_factor = num_changepoints_penalty_factor,
                minor_allele_fraction_prior_alpha = minor_allele_fraction_prior_alpha,
                num_samples_copy_ratio = num_samples_copy_ratio,
                num_burn_in_copy_ratio = num_burn_in_copy_ratio,
                num_samples_allele_fraction = num_samples_allele_fraction,
                num_burn_in_allele_fraction = num_burn_in_allele_fraction,
                smoothing_threshold_copy_ratio = smoothing_threshold_copy_ratio,
                smoothing_threshold_allele_fraction = smoothing_threshold_allele_fraction,
                max_num_smoothing_iterations = max_num_smoothing_iterations,
                num_smoothing_iterations_per_fit = num_smoothing_iterations_per_fit,
                gatk4_jar_override = gatk4_jar_override,
                gatk_docker = gatk_docker,
                mem_gb = mem_gb_for_model_segments,
                disk_space_gb = model_segments_normal_disk,
                preemptible_attempts = preemptible_attempts
        }

        Int copy_ratio_segments_normal_disk = ceil(size(DenoiseReadCountsNormal.denoised_copy_ratios, "GB")) + ceil(size(ModelSegmentsNormal.copy_ratio_only_segments, "GB")) + disk_pad
        call copy_ratio_segments_call as CallCopyRatioSegmentsNormal {
            input:
                entity_id = CollectCountsNormal.entity_id,
                copy_ratio_segments = ModelSegmentsNormal.copy_ratio_only_segments,
                neutral_segment_copy_ratio_lower_bound = neutral_segment_copy_ratio_lower_bound,
                neutral_segment_copy_ratio_upper_bound = neutral_segment_copy_ratio_upper_bound,
                outlier_neutral_segment_copy_ratio_z_score_threshold = outlier_neutral_segment_copy_ratio_z_score_threshold,
                calling_copy_ratio_z_score_threshold = calling_copy_ratio_z_score_threshold,
                gatk4_jar_override = gatk4_jar_override,
                gatk_docker = gatk_docker,
                mem_gb = mem_gb_for_call_copy_ratio_segments,
                disk_space_gb = copy_ratio_segments_normal_disk,
                preemptible_attempts = preemptible_attempts
        }

        # The files from other tasks are small enough to just combine into one disk variable and pass to the normal plotting tasks
        Int plot_normal_disk = ref_size + ceil(size(DenoiseReadCountsNormal.standardized_copy_ratios, "GB")) + ceil(size(DenoiseReadCountsNormal.denoised_copy_ratios, "GB")) + ceil(size(ModelSegmentsNormal.het_allelic_counts, "GB")) + ceil(size(ModelSegmentsNormal.modeled_segments, "GB")) + disk_pad
        call denoised_copy_ratios_plot as PlotDenoisedCopyRatiosNormal {
            input:
                entity_id = CollectCountsNormal.entity_id,
                standardized_copy_ratios = DenoiseReadCountsNormal.standardized_copy_ratios,
                denoised_copy_ratios = DenoiseReadCountsNormal.denoised_copy_ratios,
                ref_fasta_dict = ref_fasta_dict,
                minimum_contig_length = minimum_contig_length,
                maximum_copy_ratio = maximum_copy_ratio,
                point_size_copy_ratio = point_size_copy_ratio,
                gatk4_jar_override = gatk4_jar_override,
                gatk_docker = gatk_docker,
                mem_gb = mem_gb_for_plotting,
                disk_space_gb = plot_normal_disk,
                preemptible_attempts = preemptible_attempts
        }

        call denoised_copy_ratios_plot_modeled_segments as PlotModeledSegmentsNormal {
            input:
                entity_id = CollectCountsNormal.entity_id,
                denoised_copy_ratios = DenoiseReadCountsNormal.denoised_copy_ratios,
                het_allelic_counts = ModelSegmentsNormal.het_allelic_counts,
                modeled_segments = ModelSegmentsNormal.modeled_segments,
                ref_fasta_dict = ref_fasta_dict,
                minimum_contig_length = minimum_contig_length,
                maximum_copy_ratio = maximum_copy_ratio,
                point_size_copy_ratio = point_size_copy_ratio,
                point_size_allele_fraction = point_size_allele_fraction,
                gatk4_jar_override = gatk4_jar_override,
                gatk_docker = gatk_docker,
                mem_gb = mem_gb_for_plotting,
                disk_space_gb = plot_normal_disk,
                preemptible_attempts = preemptible_attempts
        }
    }

    output {
        File preprocessed_intervals = intervals_preprocess_intervals.preprocessed_intervals
        File read_counts_entity_id_tumor = CollectCountsTumor.entity_id
        File read_counts_tumor = CollectCountsTumor.counts
        File allelic_counts_entity_id_tumor = CollectAllelicCountsTumor.entity_id
        File allelic_counts_tumor = CollectAllelicCountsTumor.allelic_counts
        File denoised_copy_ratios_tumor = DenoiseReadCountsTumor.denoised_copy_ratios
        File standardized_copy_ratios_tumor = DenoiseReadCountsTumor.standardized_copy_ratios
        File het_allelic_counts_tumor = ModelSegmentsTumor.het_allelic_counts
        File normal_het_allelic_counts_tumor = ModelSegmentsTumor.normal_het_allelic_counts
        File copy_ratio_only_segments_tumor = ModelSegmentsTumor.copy_ratio_only_segments
        File copy_ratio_legacy_segments_tumor = ModelSegmentsTumor.copy_ratio_legacy_segments
        File allele_fraction_legacy_segments_tumor = ModelSegmentsTumor.allele_fraction_legacy_segments
        File modeled_segments_begin_tumor = ModelSegmentsTumor.modeled_segments_begin
        File copy_ratio_parameters_begin_tumor = ModelSegmentsTumor.copy_ratio_parameters_begin
        File allele_fraction_parameters_begin_tumor = ModelSegmentsTumor.allele_fraction_parameters_begin
        File modeled_segments_tumor = ModelSegmentsTumor.modeled_segments
        File copy_ratio_parameters_tumor = ModelSegmentsTumor.copy_ratio_parameters
        File allele_fraction_parameters_tumor = ModelSegmentsTumor.allele_fraction_parameters
        File called_copy_ratio_segments_tumor = CallCopyRatioSegmentsTumor.called_copy_ratio_segments
        File called_copy_ratio_legacy_segments_tumor = CallCopyRatioSegmentsTumor.called_copy_ratio_legacy_segments
        File denoised_copy_ratios_plot_tumor = PlotDenoisedCopyRatiosTumor.denoised_copy_ratios_plot
        File standardized_MAD_tumor = PlotDenoisedCopyRatiosTumor.standardized_MAD
        Float standardized_MAD_value_tumor = PlotDenoisedCopyRatiosTumor.standardized_MAD_value
        File denoised_MAD_tumor = PlotDenoisedCopyRatiosTumor.denoised_MAD
        Float denoised_MAD_value_tumor = PlotDenoisedCopyRatiosTumor.denoised_MAD_value
        File delta_MAD_tumor = PlotDenoisedCopyRatiosTumor.delta_MAD
        Float delta_MAD_value_tumor = PlotDenoisedCopyRatiosTumor.delta_MAD_value
        File scaled_delta_MAD_tumor = PlotDenoisedCopyRatiosTumor.scaled_delta_MAD
        Float scaled_delta_MAD_value_tumor = PlotDenoisedCopyRatiosTumor.scaled_delta_MAD_value
        File modeled_segments_plot_tumor = PlotModeledSegmentsTumor.modeled_segments_plot

        File? read_counts_entity_id_normal = CollectCountsNormal.entity_id
        File? read_counts_normal = CollectCountsNormal.counts
        File? allelic_counts_entity_id_normal = CollectAllelicCountsNormal.entity_id
        File? allelic_counts_normal = CollectAllelicCountsNormal.allelic_counts
        File? denoised_copy_ratios_normal = DenoiseReadCountsNormal.denoised_copy_ratios
        File? standardized_copy_ratios_normal = DenoiseReadCountsNormal.standardized_copy_ratios
        File? het_allelic_counts_normal = ModelSegmentsNormal.het_allelic_counts
        File? normal_het_allelic_counts_normal = ModelSegmentsNormal.normal_het_allelic_counts
        File? copy_ratio_only_segments_normal = ModelSegmentsNormal.copy_ratio_only_segments
        File? copy_ratio_legacy_segments_normal = ModelSegmentsNormal.copy_ratio_legacy_segments
        File? allele_fraction_legacy_segments_normal = ModelSegmentsNormal.allele_fraction_legacy_segments
        File? modeled_segments_begin_normal = ModelSegmentsNormal.modeled_segments_begin
        File? copy_ratio_parameters_begin_normal = ModelSegmentsNormal.copy_ratio_parameters_begin
        File? allele_fraction_parameters_begin_normal = ModelSegmentsNormal.allele_fraction_parameters_begin
        File? modeled_segments_normal = ModelSegmentsNormal.modeled_segments
        File? copy_ratio_parameters_normal = ModelSegmentsNormal.copy_ratio_parameters
        File? allele_fraction_parameters_normal = ModelSegmentsNormal.allele_fraction_parameters
        File? called_copy_ratio_segments_normal = CallCopyRatioSegmentsNormal.called_copy_ratio_segments
        File? called_copy_ratio_legacy_segments_normal = CallCopyRatioSegmentsNormal.called_copy_ratio_legacy_segments
        File? denoised_copy_ratios_plot_normal = PlotDenoisedCopyRatiosNormal.denoised_copy_ratios_plot
        File? standardized_MAD_normal = PlotDenoisedCopyRatiosNormal.standardized_MAD
        Float? standardized_MAD_value_normal = PlotDenoisedCopyRatiosNormal.standardized_MAD_value
        File? denoised_MAD_normal = PlotDenoisedCopyRatiosNormal.denoised_MAD
        Float? denoised_MAD_value_normal = PlotDenoisedCopyRatiosNormal.denoised_MAD_value
        File? delta_MAD_normal = PlotDenoisedCopyRatiosNormal.delta_MAD
        Float? delta_MAD_value_normal = PlotDenoisedCopyRatiosNormal.delta_MAD_value
        File? scaled_delta_MAD_normal = PlotDenoisedCopyRatiosNormal.scaled_delta_MAD
        Float? scaled_delta_MAD_value_normal = PlotDenoisedCopyRatiosNormal.scaled_delta_MAD_value
        File? modeled_segments_plot_normal = PlotModeledSegmentsNormal.modeled_segments_plot

   }
}
