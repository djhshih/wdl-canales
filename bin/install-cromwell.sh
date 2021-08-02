#!/bin/bash
set -e

# install cromwell and womtool

names=(cromwell womtool)
version="66"
author=broadinstitute
repo=cromwell
url=https://github.com/$author/$repo/releases/download/${version}

for name in ${names[@]}; do

	# set the installation directory

	target_dir=${DESTDIR:-$HOME/.cromwell}
	echo "Installing to $target_dir ..."

	# download source files for tmux, libevent, and ncurses
	# save them in /tmp

	mkdir -p $target_dir/{bin,jar} && cd $target_dir

	wget -O jar/${name}-${version}.jar $url/${name}-${version}.jar

	jar_path=$(readlink -f jar/${name}-${version}.jar)
	echo "java -Xmx1G -XX:+UseSerialGC -jar $jar_path \"\$@\"" > bin/$name
	chmod +x bin/$name

	cd -

done
