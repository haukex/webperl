#!/bin/bash
set -e
# Finds and displays TODOs for the WebPerl project.
# the output can be piped into e.g. "less -R"
if [ -z ${EMPERL_PERLVER+x} ]; then
	echo "Please source emperl_config.sh first"
	exit 1
fi
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. >/dev/null && pwd )"
TEMPFILE="`mktemp`"
trap 'rm -f "$TEMPFILE"' EXIT
(
	cd "$DIR/emperl5"
	# only look at files that have been added
	git diff --numstat --diff-filter=A $EMPERL_PERLVER $EMPERL_PERL_BRANCH \
		| BASEDIR=$DIR perl -wMstrict -MFile::Spec::Functions=abs2rel,rel2abs -nl0 \
			-e '/^\d+\s+\d+\s+(.+)$/ or die $_; -e $1 and print abs2rel(rel2abs($1),$ENV{BASEDIR})'
) >>"$TEMPFILE"
cd $DIR
find . -mindepth 1 \( -path ./.git -o -path ./work -o -path ./emperl5 \) -prune \
	-o ! -name 'emperl.*' ! -type d -print0 \
	| perl -wMstrict -MFile::Spec::Functions=canonpath -n0le 'print canonpath($_)' >>"$TEMPFILE"
xargs -0 -a "$TEMPFILE" \
	grep --color=always -C1 -niE '\bto.?do\b'
