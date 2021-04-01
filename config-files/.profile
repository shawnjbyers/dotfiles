[ "${HOME:-}" != "" ] && [ -d "${HOME}/.local/bin" ] && export PATH="${PATH}:${HOME}/.local/bin"
umask u=rwx,go=
export GUI_EDITOR='/usr/bin/gedit'
