rcfile="${sval}"'/shellrc.sh'

if ! [ -f "${rcfile}" ]; then
  printf '%s: could not find file %s\n' "${bname}" "${rcfile}" >&2
  exit 1
fi

for tfile in .bashrc .zshrc; do
  cp -- "${rcfile}" "${tval}"/"${tfile}" || {
    printf '%s: cp failed\n' "${bname}" >&2
    exit 1
  }
done
