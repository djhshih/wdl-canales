#!/bin/bash

set -eu

path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
root="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"

wdl=$1
indir=$2

if [[ $wdl =~ .*\.wdl ]]; then

	wdl_fname=${wdl##*/}
	wdl_wname=${wdl_fname%%.*}

	echo "[check-wdl] Checking $wdl_wname ..."

	inputs=$indir/${wdl_wname}.inputs

	$path/cromwell run $wdl -i <(sed -e "s|\${root}|${root}|g" $inputs)

fi

