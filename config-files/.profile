if [ "${HOME-}" != '' ]
then
	if [ -d ~/.local/bin ]
	then
		export PATH="${PATH}:${HOME}/.local/bin"
	fi

	if [ -d ~/.pub-cache/bin ]
	then
		export PATH="${PATH}:${HOME}/.pub-cache/bin"
	fi
fi

umask u=rwx,go=

export GUI_EDITOR

for editor in gedit gnome-text-editor xedit
do
	GUI_EDITOR="$(command -v -- "$editor")" || continue
	break
done

if [ "$GUI_EDITOR" = '' ]
then
	unset GUI_EDITOR
fi
