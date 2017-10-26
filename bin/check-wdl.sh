#!/bin/bash

set -eu

path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
root="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"

wdl=$1
indir=$2

mkdir -p tmp
tmpdir=$(mktemp -d ./tmp/XXXXXX)

if [[ $wdl =~ .*\.wdl ]]; then

	wdl_fname=${wdl##*/}
	wdl_wname=${wdl_fname%%.*}

	echo "[check-wdl] Checking $wdl_wname ..."

	inputs_raw=$indir/${wdl_wname}.inputs

	inputs=$tmpdir/${wdl_wname}.inputs
	sed -e "s|\${root}|${root}|g" $inputs_raw > $inputs

	echo "[check-wdl] Running cromwell with inputs: "
	cat $inputs >&2

	$path/cromwell run $wdl -i $inputs

fi

