task bam_to_fastq_paired {
	File input_bam
	String sample_id

	Int preemptible_tries = 3
	Int diskspace = ceil(2 * size(input_bam, "GB"))

	command <<<
		# NB no read group information is preserved, because external
		#    samples rarely have propr read group field values
		# outputs will be minimally compressed (level=1)
		java -XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Xmx512M \
			-Dsamjdk.buffer_size=131072 -Dsamjdk.use_async_io=true \
			-Dsamjdk.compression_level=1  \
			-jar /usr/gitc/picard.jar SamToFastq \
			TMP_DIR=. \
			INPUT=${input_bam} \
			FASTQ=${sample_id}_r1.fastq.gz \
			SECOND_END_FASTQ=${sample_id}_r2.fastq.gz \
			UNPAIRED_FASTQ=${sample_id}_unpaired.fastq.gz \
			INCLUDE_NON_PF_READS=true \
	>>>

	output {
		File fastq_r1 = "${sample_id}_R1.fastq.gz"
		File fastq_r2 = "${sample_id}_R2.fastq.gz"
		File fastq_unpaired = "${sample_id}_unpaired.fastq.gz"
	}

	runtime {
		docker: "broadinstitute/genomes-in-the-cloud:2.3.1-1500064817"
		memory: "1 GB"
		cpu: "1"
		disks: "local-disk ${diskspace} HDD"
		preemptible: preemptible_tries
	}
}
