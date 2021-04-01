#!/bin/nologin

is_bash() (
[ -z "${BASH_VERSION-}" ] || exit 0
exit 1
)

is_zsh() (
[ -z "${ZSH_VERSION-}" ] || exit 0
exit 1
)

is_interactive() (
if is_bash || is_zsh; then
  case "$-" in
    *i*) exit 0;;
    *) exit 1;;
  esac
else
  exit 1
fi
)

if is_interactive; then
  user_id="$(id -u)" || {
    user_id='0'
    echo 'shellrc: id failed'
  }

  if is_bash; then
    set -o vi # set vi keybindings
    export SHELL='/bin/bash'
    shopt -s extglob # enable extended globbing

    # bash lists the status of stopped or running jobs before exiting
    shopt -s checkjobs

    PS1='\[\033[01;32m\][\[\033[01;37m\]\W\[\033[01;32m\]]\$\[\033[00m\] '
    PS2='> '
    PS3='#? '
    PS4='+ '

    if [ "x$user_id" = 'x0' ]; then
      # root
      export HISTSIZE=50 # in-memory history 50 lines
      export HISTFILESIZE=0 # disable on-disk history
      unset HISTFILE
    else
      # normal user
      # enable history with 10,000 lines
      export HISTSIZE=10000
      export HISTFILESIZE=10000
    fi
  elif is_zsh; then
    export SHELL='/bin/zsh'

    # equivalent of bash ``help'' command
    alias run-help > /dev/null 2>&1 && unalias run-help
    autoload run-help
    alias help='run-help'

    # see `man zshoptions'
    setopt APPEND_HISTORY EXTENDED_GLOB NOMATCH
    setopt INTERACTIVE_COMMENTS HIST_IGNORE_ALL_DUPS AUTO_CD
    unsetopt BEEP NOTIFY

    # initialize autocompletion
    autoload -Uz compinit
    compinit

    bindkey -v # use vi keybindings

    # disable the delay after <Esc> or ^[ in vi-mode
    KEYTIMEOUT=1

    # make delete/backspace work normally
    bindkey -M viins '^?' backward-delete-char
    bindkey -M viins '^H' backward-delete-char

    # change the way you go through history so the cursor remains at the
    # beginning of the line
    bindkey -M vicmd k vi-up-line-or-history
    bindkey -M vicmd j vi-down-line-or-history

    # bind <Esc>z to edit the command line in a text editor
    autoload edit-command-line
    zle -N edit-command-line
    bindkey -M vicmd z edit-command-line

    # custom tab-completion settings
    zstyle ':completion:*' completer _expand _complete _ignored \
      _correct _approximate
    zstyle ':completion:*' matcher-list '' \
      'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'l:|=* r:|=*'
    zstyle ':completion:*' max-errors 3
    zstyle :compinstall filename ~/.zshrc

    # custom prompt
    PROMPT='%F{green}[%f%B%F{white}%1/%f%b%F{green}]%#%f '

    if [ "x$user_id" = 'x0' ]; then
      # root
      HISTSIZE=50 # in-memory history 50 lines
      SAVEHIST=0 # disable on-disk history
      unset HISTFILE
    else
      # normal user
      # enable history with 10,000 lines
      HISTFILE=~/.zsh_histfile
      HISTSIZE=10000
      SAVEHIST=10000
    fi
  fi

  if [ "x$user_id" = 'x0' ]; then
    # root
    alias emerge='emerge --ask --quiet'
  else
    # normal user
    alias dtrace='sudo dtrace'
    alias stap='sudo stap'
    alias bpftrace='sudo bpftrace'
    alias poweroff='sudo poweroff'
    alias s2ram='sudo s2ram'
    alias grub-mkconfig='sudo grub-mkconfig'
    alias dispatch-conf='sudo dispatch-conf'
    alias eclean-kernel='sudo eclean-kernel'
    alias emerge='sudo emerge --ask --quiet'
    alias emerge-webrsync='sudo emerge-webrsync'
  fi

  ### BASIC SETUP ###

  umask u=rwx,go= # restrictive creation mode
  stty -ixon # disable ctrl+s on terminals

  export EDITOR='/usr/bin/vim'
  export VISUAL='/usr/bin/vim'

  # give nice colored output with GNU ls
  if command -v dircolors > /dev/null 2>&1; then
    export LS_COLORS=''
    if [ -f ~/.dir_colors ] ; then
      eval "$(dircolors -b ~/.dir_colors)"
    elif [ -f /etc/DIR_COLORS ] ; then
      eval "$(dircolors -b /etc/DIR_COLORS)"
    else
      eval "$(dircolors -b)"
    fi
  fi

  ### FUNCTIONS ###

  launch() (
  # launch audacious ~= audacious & disown

  if [ $# -eq 0 ]; then
    echo 'launch: bad usage' 1>&2
    exit 1
  else
    "$@" &
  fi
  )

  user_approve() (
  # prints any arguments to stderr
  # returns 0 for yes, 1 for no, and 2 for error

  printf '%s\n' "$*" >&2

  while :; do
    printf '(y/n): '

    if ! read -r approval; then
      echo
      return 2
    fi

    if [ "x${approval}" = 'xy' ]; then
      return 0
    elif [ "x${approval}" = 'xn' ]; then
      return 1
    else
      echo 'Enter either ``y'''' or ``n''''.'
    fi
  done
  )

  rmdot() {
    local bname='rmdot'

    if [ $# -ne 0 ]; then
      printf 'usage: %s' "$bname" >&2
      printf '%s: delete the current directory' "$bname" >&2
      return 2
    fi

    user_approve 'Would you like to remove the current directory?' || {
      return 1
    }

    local current_dir
    current_dir="$(pwd)" || return 1
    cd .. || return 1
    rm -r -- "${current_dir}" || return 1
  }

  inewtest() {
    local bname='inewtest'

    if [ $# -ne 0 ]; then
      printf 'usage: %s' "$bname" >&2
      printf '%s: make and enter a new test directory\n' "$bname" >&2
      return 2
    fi

    local test_dir=~/Desktop/test
    [ -d "$test_dir" ] || {
      printf '%s: could not find test directory %s\n' "$bname" "$test_dir" >&2
      return 2
    }

    local i=0
    while :; do
      local new_dir="$test_dir"/"$i"'test'
      if [ -e "$new_dir" ]; then
        i=$((i + 1))
        continue
      fi

      mkdir -- "$new_dir" || {
        printf '%s: could not make directory %s\n' "$bname" "$new_dir" >&2
        return 1
      }

      cd -- "$new_dir" || {
        printf '%s: could not cd to directory %s\n' "$bname" "$new_dir" >&2
        return 1
      }

      return 0
    done
  }

  mkcd() {
    local bname='mkcd'
    if [ 1 -ne $# ]; then
      printf 'usage: %s <new-directory-name>\n' "$bname" >&2
      return 2
    fi

    new_dir="$1"

    mkdir -- "$new_dir" || {
      printf '%s: could not make directory %s\n' "$bname" "$new_dir" >&2
      return 1
    }

    cd -- "$new_dir" || {
      printf '%s: could not cd to directory %s\n' "$bname" "$new_dir" >&2
      return 1
    }
  }

  using_coreutils() (
  bname='using_coreutils'
  if [ $# -ne 1 ]; then
    printf 'usage: %s <coreutil-type>\n' "$bname" >&2
    exit 2
  fi

  if [ "x$1" = xgnu ]; then
    ls --color=always > /dev/null 2>&1 || exit 1
    exit 0
  elif [ "x$1" = xmacos ]; then
    ls -G '-@' > /dev/null 2>&1 || exit 1
    exit 0
    ls
  else
    printf '%s: unrecognized coreutil type %s\n' "$bname" "$1" >&2
    exit 2
  fi
  )

  ### ALIASES ###

  alias cargo='cargo -q'
  alias gdb='gdb -q'
  alias mvn='mvn -q'
  alias clisp='clisp -q'

  # use hyphens instead of dashes on man pages so you can search for flags
  alias man='LC_ALL=POSIX man'

  # POSIX: diff
  # GNU coreutils: diff --color=auto
  # # --color=auto: colorize output when printing to a terminal
  # MacOS: diff

  # POSIX: grep -E -i
  # # -E: use extended regular expressions
  # # -i: ignore case when matching
  # GNU coreutils: grep -E -i --color=auto
  # # --color=auto: colorize output when printing to a terminal
  # MacOS: grep -E -i --color=auto

  # POSIX: ls -F -A
  # # -F:
  #       write special symbols after the names of special types of
  #       files for example, directories are suffixed with ``/'' and
  #       pipes with ``|''
  # # -A:
  #       list all files, even hidden files, except for ``.'' and
  #       ``..''
  # GNU coreutils: ls -F -A -h --color=auto --time-style='%Y-%m-%d %T'
  # # -h:
  #       human readable sizes in long mode (aka, say ``4.0K''
  #       instead of ``4096'')
  # # --color=auto: colorize output when printing to a terminal
  # # --time-style='+%Y-%m-%d %T':
  #                                use a special date format in long
  #                                mode, it looks like ``2020-08-21
  #                                23:14:39''
  # MacOS: ls -F -A -h -e -G '-@'
  # # -e:
  #       display access control lists in long mode if a file has
  #       one
  # # -G: colorize output
  # # '-@':
  #         display extended attribute keys and sizes in long output

  # lsna:
  #  - same as for ``ls'' but without the ``-A'' flag

  if using_coreutils gnu; then
    alias diff='diff --color=auto'
    alias grep='grep -E -i --color=auto'
    alias ls='ls -F -A -h --color=auto --time-style='\''+%Y-%m-%d %T'\'
    alias lsna='command ls -F -h --color=auto --time-style='\''+%Y-%m-%d %T'\'
  elif using_coreutils macos; then
    alias diff='diff'
    alias grep='grep -E -i --color=auto'
    alias ls='ls -F -A'
    alias ls='ls -F -A -h -e -G '\''-@'\'
    alias lsna='command ls -F -h -e -G '\''-@'\'
  else
    # using POSIX
    alias diff='diff'
    alias grep='grep -E -i'
    alias ls='ls -F -A'
    alias lsna='command ls -F'
  fi

  alias please='sudo'
  alias plz='sudo'
  
  alias shellcheck='shellcheck --enable=all --severity=info --check-sourced --external-sources'
  alias date='date '\''+%Y-%m-%d %T'\' # posix-compliant: POSIX.1-2008

  alias youtube-dl-music-playlist='youtube-dl -x --audio-format=mp3 --audio-quality=0 -o '\''%(playlist_index)s %(title)s.%(ext)s'\'

  # useful for making your shell recognize a newly installed executable
  alias rereadpath='PATH="$PATH"'

  if command -v 'rlwrap' > /dev/null 2>&1; then
    alias node='NODE_NO_READLINE=1 rlwrap node'
    alias posh='rlwrap posh'
    alias dash='rlwrap dash'
  fi

  if is_zsh; then
    # enable syntax highlighting if it's installed
    for zsh_syntax_hlf in /usr/share/zsh/site-functions/zsh-syntax-highlighting.zsh /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
      if [ -f "$zsh_syntax_hlf" ]; then
        . "$zsh_syntax_hlf"
        break
      fi
    done
  fi
fi
