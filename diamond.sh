#!/usr/bin/env bash
qmk() {
	which qmk &> /dev/null \
		&& command qmk "$@" \
		|| nix-shell -p '<nixpkgs>' qmk --run "qmk $@"
}

case "$1" in
	atreus62)
		make atreus62:diamond:dfu-util CTPC=yes
		;;
	corne)
		make crkbd/r2g:mb_via
		qmk flash -kb crkbd/r2g -km mb_via
		;;
	*)
		printf "unknown keyboard %q" "$1"
		;;
esac
