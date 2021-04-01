if [ "x${HOME:-}" != 'x' ] && [ -d "${HOME}/.local/bin" ]; then
  export PATH="${PATH}:${HOME}/.local/bin"
fi
umask u=rwx,go=
export GUI_EDITOR='/usr/bin/gedit'
