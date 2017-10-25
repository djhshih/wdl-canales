build = ./bin/wdl-assemble.py
check = ./bin/check-wdl.sh 

targets = \
	wdl/bam_realign_paired.wdl \
	wdl/bam_realign_paired_fast.wdl \
	wdl/bam_realign_paired_faster.wdl \


all: $(targets)
	

wdl/%.wdl: src/%.workflow
	$(build) $< > $@

clean:
	rm -rf wdl/*

bin/cromwell:
	DESTDIR=. bin/install-cromwell.sh

test/sample.bam:
	test/make.sh

check: $(targets) bin/cromwell test/sample.bam
	for f in $^; do $(check) $$f test/inputs/jes; done

