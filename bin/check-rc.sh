#!/bin/bash

# Check all return code files in a directory

set -o errexit
set -o nounset


root=$1

final_rc=0

for f in $(find $1 -name rc); do
	echo ${f#*/} $(cat $f);
	rc=$(cat $f)
	if [[ ! $rc -eq 0 ]]; then
		final_rc=1
	fi
done

if [[ $final_rc -eq 0 ]]; then
	echo "overall status: success"
else
	echo "overall status: failure"
fi

exit $final_rc

