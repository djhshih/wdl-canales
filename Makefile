build = ./bin/wdl-assemble.py
validate = womtool validate
check = ./bin/check-wdl.sh 
check_rc = ./bin/check-rc.sh

targets = \
	wdl/fastq_align_paired.wdl \
	wdl/bam_realign_paired.wdl \
	wdl/bam_realign_paired_fast.wdl \
	wdl/bam_realign_paired_faster.wdl \
	wdl/maf_filter_orient_bias_legacy.wdl \
	wdl/bam_cnv_somatic_pair.wdl \
	wdl/bam_cnv_somatic_panel.wdl \
	wdl/vcf_filter_mobsnvf.wdl \
	wdl/bam_mutect2.wdl \
	wdl/vcf_rm_variants.wdl \
	wdl/vcf_rm_filtered.wdl \
	wdl/vcf_annot_funcotator.wdl \

all: $(targets)
	

wdl/%.wdl: src/%.workflow
	$(build) $< > $@
	$(validate) $@

clean:
	rm -rf wdl/*
	rm -rf cromwell-*/
	rm -rf tmp

bin/cromwell:
	DESTDIR=. bin/install-cromwell.sh

test/S01.bam:
	test/make.sh

test: $(targets) bin/cromwell test/S01.bam
	for f in $^; do $(check) $$f test/inputs/jes; done
	$(check_rc) cromwell-executions

check: $(targets)
	for f in $^; do echo "Checking $$f ..."; $(validate) $$f; done

