#!/bin/sh

if [ 0 -ne $# ]; then
  printf '%s: bad usage\n' "$0" >&2
  exit 2
fi

bname="$(basename -- "$0")" || {
  bname="$0"
  printf '%s: basename failed\n' "$bname" >&2
  exit 1
}

dname="$(dirname -- "$0")" || {
  printf '%s: dirname failed\n' "$bname" >&2
  exit 1
}
if [ 'x' = "x$dname" ]; then
  printf '%s: could not find dirname\n' "$bname" >&2
  exit 1
fi
fname="$dname"'/shellrc.sh'

[ -f "$fname" ] || {
  printf '%s: could not find file %s\n' "$bname" "$fname" >&2
  exit 1
}

for shell in posh dash zsh bash; do
  /bin/"$shell" -- "$fname" || {
    printf '%s: non-interactive shell %s failed\n' "$bname" "$shell" >&2
    exit 1
  }
done

for shell in zsh bash; do
  printf '%s -i %s\n' "$shell" "$fname"
  /bin/"$shell" -i -- "$fname" || {
    printf '%s: interactive shell %s failed\n' "$bname" "$shell" >&2
    exit 1
  }
done
