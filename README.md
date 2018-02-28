# WDL Canales

[![travis-ci](https://travis-ci.org/djhshih/wdl-canales.svg?branch=master)](https://travis-ci.org/djhshih/wdl-canales)

Bioinformatic pipelines written in the Workflow Description Language (WDL)


## Assemble

Requirements:
- python2 or python3

The workflows are split into multiple files that need to be assembled into WDL files by

```
make
```

Now, WDL files can be found in `wdl/`.


## Run the workflows

The workflows can be run using [Cromwell](https://github.com/broadinstitute/cromwell) (command line) or [Firecloud](http://firecloud.org) (web service hosted on the Google Cloud platform).
See their respective documentations for further details.

The workflows here are also released under the `dshih` namespace on Firecloud.


## Test the workflows

The workflows are continuously tested on pre-generated test data on [Travis](https://travis-ci.org/djhshih/wdl-canales).

To run these tests yourself, you need to first fulfill the following requirements:
- java (jre8)
- docker

The workflows can be run on pre-generated test data using cromwell
(automatically retrieved). Simply do

```
make check
```

The exit codes of each task is printed to `stdout`.


## Generate test data

Requirements:
- dgswim
- samtools
- bwa

You can re-generate the test data by

```
cd test
./make.sh
```

## Workflows

Extract reads from pair-end BAM and re-align to another reference:
- *bam_realign_paired*
- *bam_realign_paired_fast*
- *bam_realign_paired_faster*
