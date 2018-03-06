build = ./bin/wdl-assemble.py
check = ./bin/check-wdl.sh 
check_rc = ./bin/check-rc.sh

targets = \
	wdl/bam_realign_paired.wdl \
	wdl/bam_realign_paired_fast.wdl \
	wdl/bam_realign_paired_faster.wdl \
	wdl/maf_filter_orient_bias_legacy.wdl \


all: $(targets)
	

wdl/%.wdl: src/%.workflow
	$(build) $< > $@

clean:
	rm -rf wdl/*
	rm -rf cromwell-*/
	rm -rf tmp

bin/cromwell:
	DESTDIR=. bin/install-cromwell.sh

test/S01.bam:
	test/make.sh

check: $(targets) bin/cromwell test/S01.bam
	for f in $^; do $(check) $$f test/inputs/jes; done
	$(check_rc) cromwell-executions

