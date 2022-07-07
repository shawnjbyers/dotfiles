#!/usr/bin/env sh

set -eu

bname="$(basename -- "$0")" || {
	bname="$0"
	printf '%s: basename failed\n' "$bname" >&2
	exit 1
}

print_usage() (
printf 'usage: %s -s source-dir -t target-dir\n' "$bname" >&2
)

sflag=''
tflag=''
while getopts 's:t:' name
do
	case "$name" in
		s)
			sflag=1
			sval="$OPTARG"
			;;
		t)
			tflag=1
			tval="$OPTARG"
			;;
		*)
			print_usage
			exit 2
			;;
	esac
done
shift $((OPTIND - 1))

if [ "$sflag" = '' ] || [ "$tflag" = '' ]
then
	print_usage
	exit 2
fi

if [ 0 -ne $# ]
then
	print_usage
	exit 2
fi
