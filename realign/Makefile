all: bam_realign_paired.wdl bam_realign_paired_fast.wdl bam_realign_paired_faster.wdl
	

bam_realign_paired.wdl:
	../bin/wdl-assemble.py bam_realign_paired.workflow > $@

bam_realign_paired_fast.wdl:
	../bin/wdl-assemble.py bam_realign_paired_fast.workflow > $@

bam_realign_paired_faster.wdl:
	../bin/wdl-assemble.py bam_realign_paired_faster.workflow > $@

clean:
	rm -f *.wdl

