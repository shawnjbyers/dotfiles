if [ "${sval}" = '-' ]; then
  sval='./-'
fi

cd -- "${sval}"

make || {
  printf '%s: failed to make project\n' "${bname}" >&2
  exit 1
}

if [ "${tval}" = '-' ]; then
  tval='./-'
fi

cp -- ./datetime "${tval}" || {
  printf '%s: failed to copy datetime to %s\n' "${bname}" "${tval}" >&2
  exit 1
}
