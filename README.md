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


## Test the workflows

Requirements:
- java (jre8)
- docker

The workflows can be run on pre-generated test data by

```
make check
```

The exit codes of all tasks are printed to `stdout`.


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

