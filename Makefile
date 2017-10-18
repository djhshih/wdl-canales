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

check: $(targets) bin/cromwell
	for f in $^; do $(check) $$f test; done
