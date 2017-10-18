build = ./bin/wdl-assemble.py
run = ./bin/cromwell run

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
	DESTDIR=$(pwd) bin/install-cromwell.sh

check: bin/cromwell
	$(run) 

