#!/dev/null

if [ "${HOME-}" != '' ]; then
  if [ -f "${HOME}/.profile" ]; then
    . "${HOME}/.profile"
  fi
fi

is_bash() (
if [ "${BASH_VERSION-}" != '' ]; then
  exit 0
fi

exit 1
)

is_zsh() (
if [ "${ZSH_VERSION-}" != '' ]; then
  exit 0
fi

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

load_nvm_command() {
  export NVM_DIR="${HOME}/.nvm"
  [ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"
}

load_nvm_completion() {
  [ -s "${NVM_DIR}/bash_completion" ] && \. "${NVM_DIR}/bash_completion"
}

load_nvm() {
  load_nvm_command && load_nvm_completion
}

if is_interactive; then
  user_id="$(id -u)" || {
    user_id='0'
    echo 'shellrc: id failed' >&2
  }

  if is_zsh; then
    # Add directories to the front of $PATH for node that nvm would have
    # added.
    setopt nullglob
    for entry in "${HOME}/.nvm/versions/node/"*/bin; do
      PATH="${entry}:${PATH}"
    done
    unsetopt nullglob
  fi

  if is_bash; then
    load_nvm || {
      echo 'shellrc: failed to load nvm' >&2
    }
    set -o vi # set vi keybindings
    if command -v bash > /dev/null 2>&1; then
      if SHELL="$(command -v bash)"; then
        export SHELL
      else
        echo 'shellrc: could not find bash' >&2
      fi
    fi
    shopt -s extglob # enable extended globbing

    # if bash major version is 5 or more
    if [ "${BASH_VERSION%%.*}" -ge 5 ]; then
      # bash lists the status of stopped or running jobs before exiting
      shopt -s checkjobs
    fi

    PS1='\[\033[01;32m\][\[\033[01;37m\]\W\[\033[01;32m\]]\$\[\033[00m\] '
    PS2='> '
    PS3='#? '
    PS4='+ '

    if [ "${user_id}" = '0' ]; then
      # root
      export HISTSIZE=50 # in-memory history 50 lines
      export HISTFILESIZE=0 # disable on-disk history
      unset HISTFILE
    else
      # normal user
      # enable history with 10,000 lines
      export HISTSIZE=10000
      export HISTFILESIZE=10000

      if [ "${HOME-}" = '' ]; then
        echo 'shellrc: ${HOME} is unset or empty' >&2
      else
        histfile_dir=''

        if [ "${XDG_DATA_HOME-}" = '' ]; then
          histfile_dir="${HOME}"'/.local/share/bash'
        else
          histfile_dir="${XDG_DATA_HOME}"'/bash'
        fi

        if ! [ -d "${histfile_dir}" ]; then
          mkdir -p -- "${histfile_dir}" || {
            printf 'shellrc: failed to create directory %s\n' "${histfile_dir}" >&2
          }
        fi

        export HISTFILE="${histfile_dir}"'/history'
        unset histfile_dir
      fi
    fi
  elif is_zsh; then
    if command -v zsh > /dev/null 2>&1; then
      if SHELL="$(command -v zsh)"; then
        export SHELL
      else
        echo 'shellrc: could not find zsh' >&2
      fi
    fi

    # equivalent of bash ``help'' command
    if alias run-help > /dev/null 2>&1; then
      unalias run-help
    fi
    autoload run-help
    alias help='run-help'

    # see `man zshoptions'
    setopt APPEND_HISTORY EXTENDED_GLOB NOMATCH
    setopt INTERACTIVE_COMMENTS HIST_IGNORE_ALL_DUPS AUTO_CD
    unsetopt BEEP NOTIFY

    # add ~/.local/share/zsh to autocompletion
    # hidden behind eval so other shells can still parse this file
    eval 'fpath=(~/.local/share/zsh/functions/Completion/*/. $fpath)'

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
      _correct
    zstyle ':completion:*' matcher-list '' \
      'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'l:|=* r:|=*'
    zstyle ':completion:*' max-errors 0
    zstyle :compinstall filename ~/.zshrc

    # custom prompt
    PROMPT='%F{green}[%f%B%F{white}%1/%f%b%F{green}]%#%f '

    if [ "${user_id}" = '0' ]; then
      # root
      HISTSIZE=50 # in-memory history 50 lines
      SAVEHIST=0 # disable on-disk history
      unset HISTFILE
    else
      # normal user
      # enable history with 10,000 lines
      HISTSIZE=10000
      SAVEHIST=10000

      if [ "${HOME-}" = '' ]; then
        echo 'shellrc: ${HOME} is unset or empty' >&2
      else
        histfile_dir=''

        if [ "${XDG_DATA_HOME-}" = '' ]; then
          histfile_dir="${HOME}"'/.local/share/zsh'
        else
          histfile_dir="${XDG_DATA_HOME}"'/zsh'
        fi

        if ! [ -d "${histfile_dir}" ]; then
          mkdir -p -- "${histfile_dir}" || {
            printf 'shellrc: failed to create directory %s\n' "${histfile_dir}" >&2
          }
        fi

        export HISTFILE="${histfile_dir}"'/history'
        unset histfile_dir
      fi
    fi
  fi

  ### BASIC SETUP ###

  umask u=rwx,go= # restrictive creation mode

  export LESSHISTFILE='-' # disable on-drive history for less

  export MANPAGER='nvim-manpager'

  if [ "${HOME-}" != '' ] && [ -d "${HOME}"/.local/bin ]; then
    case "${PATH}" in
      *:"${HOME}"/.local/bin)
        # already fine
        ;;
      *)
        # add ~/.local/bin
        PATH="${PATH}:${HOME}/.local/bin"
        ;;
    esac
  fi

  if [ -t 0 ]; then
    stty -ixon # disable ctrl+s on terminals
  fi

  if command -v nvim > /dev/null 2>&1; then
    if EDITOR="$(command -v nvim)"; then
      export EDITOR
      export VISUAL="${EDITOR}"
    else
      echo 'shellrc: could not find nvim' >&2
    fi
  fi

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

  rmdot() {
    local bname='rmdot'

    if [ $# -ne 0 ]; then
      printf 'usage: %s' "${bname}" >&2
      printf '%s: delete the current directory' "${bname}" >&2
      return 2
    fi

    local current_dir
    current_dir="$(pwd)" || return 1
    cd .. || return 1
    rm -rf -- "${current_dir}" || return 1
  }

  inewtest() {
    local bname='inewtest'

    if [ $# -ne 0 ]; then
      printf 'usage: %s' "${bname}" >&2
      printf '%s: make and enter a new test directory\n' "${bname}" >&2
      return 2
    fi

    local test_dir=~/Desktop/test
    [ -d "${test_dir}" ] || {
      printf '%s: could not find test directory %s\n' "${bname}" "${test_dir}" >&2
      return 2
    }

    local i=0
    while :; do
      local new_dir="${test_dir}"/"${i}"'test'
      if [ -e "${new_dir}" ]; then
        i=$((i + 1))
        continue
      fi

      mkdir -- "${new_dir}" || {
        printf '%s: could not make directory %s\n' "${bname}" "${new_dir}" >&2
        return 1
      }

      cd -- "${new_dir}" || {
        printf '%s: could not cd to directory %s\n' "${bname}" "${new_dir}" >&2
        return 1
      }

      return 0
    done
  }

  mkcd() {
    local bname='mkcd'
    if [ 1 -ne $# ]; then
      printf 'usage: %s <new-directory-name>\n' "${bname}" >&2
      return 2
    fi

    new_dir="$1"

    if [ "${new_dir}" = '-' ]; then
      new_dir='./-'
    fi

    mkdir -- "${new_dir}" || {
      printf '%s: could not make directory %s\n' "${bname}" "${new_dir}" >&2
      return 1
    }

    cd -- "${new_dir}" || {
      printf '%s: could not cd to directory %s\n' "${bname}" "${new_dir}" >&2
      return 1
    }
  }

  using_coreutils() (
  bname='using_coreutils'
  if [ $# -ne 1 ]; then
    printf 'usage: %s <coreutil-type>\n' "${bname}" >&2
    exit 2
  fi

  if [ "$1" = gnu ]; then
    ls --color=always > /dev/null 2>&1 || exit 1
    exit 0
  elif [ "$1" = macos ]; then
    ls -G -'@' > /dev/null 2>&1 || exit 1
    exit 0
    ls
  else
    printf '%s: unrecognized coreutil type %s\n' "${bname}" "$1" >&2
    exit 2
  fi
  )

  ### ALIASES ###


  __echo_helper() (
  if ! [ -t 1 ]; then
    \echo "$@" || exit $?
    exit 0
  fi

  set_color='\e[1;41m'
  reset_color='\e[1;m'

  if [ $# -gt 0 ] && [ "$1" = '-n' ]; then
    args=''
    is_first_arg=true
    is_second_arg=''

    for curr_arg in "$@"; do
      if [ "${is_first_arg}" != '' ]; then
        is_first_arg=''
        is_second_arg=true
      elif [ "${is_second_arg}" != '' ]; then
        is_second_arg=''
        args="${curr_arg}"
      else
        args="${args} ${curr_arg}"
      fi
    done

    printf "${set_color}"'%s'"${reset_color}" "${args}"
  else
    printf "${set_color}"'%s'"${reset_color}"'\n' "$*"
  fi
  )

  alias echo='__echo_helper'

  __units_helper() {
    if [ $# = 0 ]; then
      echo '__units_helper: user error: try one of the following:'
      echo '$ units --one-line'
      echo '$ units -1'
      printf '%s\n' '$ \units'
      local ex_usage=64 # command line usage error
      return "$ex_usage"
    else
      \units "$@"
    fi
  }

  alias units='__units_helper'

  # use hyphens instead of dashes on man pages so you can search for flags
  alias man='LC_ALL=POSIX man'

  # POSIX: diff
  # GNU coreutils: diff --color=auto
  # # --color=auto: colorize output when printing to a terminal
  # MacOS: diff

  # POSIX: grep -E -i
  # # -E: use extended regular expressions
  # # -i: ignore case when matching
  # GNU coreutils: grep -E -i -I --color=auto
  # # --color=auto: colorize output when printing to a terminal
  # MacOS: grep -E -i -I --color=auto

  # POSIX: ls -F -A
  # # -F:
  #       write special symbols after the names of special types of
  #       files for example, directories are suffixed with ``/'' and
  #       pipes with ``|''
  # # -A:
  #       list all files, even hidden files, except for ``.'' and
  #       ``..''
  # GNU coreutils: ls -F -A -h --color=auto --time-style='%FT%T%z'
  # # -h:
  #       human readable sizes in long mode (aka, say ``4.0K''
  #       instead of ``4096'')
  # # --color=auto: colorize output when printing to a terminal
  # # --time-style='%FT%T%z':
  #                                use a special date format in long
  #                                mode, it looks like
  #                                ``2020-08-21T23:14:39-0400''
  # MacOS: ls -F -A -h -e -G -'@'
  # # -e:
  #       display access control lists in long mode if a file has
  #       one
  # # -G: colorize output
  # # -'@':
  #         display extended attribute keys and sizes in long output

  # lsna:
  #  - same as for ``ls'' but without the ``-A'' flag

  if using_coreutils gnu; then
    alias diff='diff --color=auto'
    alias grep='grep -i -I --color=auto'

    # compliant: ISO 8601
    alias ls='ls -F -A -h --color=auto --time-style=+'\''%FT%T%z'\'
    alias lsna='command ls -F -h --color=auto --time-style=+'\''%FT%T%z'\'

  elif using_coreutils macos; then
    alias diff='diff'
    alias grep='grep -i -I --color=auto'
    alias ls='ls -F -A'
    alias ls='ls -F -A -h -e -G -'\''@'\'
    alias lsna='command ls -F -h -e -G -'\''@'\'
  else
    # using POSIX
    alias diff='diff'
    alias grep='grep -i'
    alias ls='ls -F -A'
    alias lsna='command ls -F'
  fi

  alias shellcheck='shellcheck --enable=all --severity=style --check-sourced --external-sources'

  alias youtube-dl-music-playlist='youtube-dl -x --audio-format=mp3 --audio-quality=0 -o '\''%(playlist_index)s %(title)s.%(ext)s'\'

  if is_zsh; then
    # enable syntax highlighting if it's installed
    zsh_syntax_filename=/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    . "${zsh_syntax_filename}" || {
      printf 'shellrc: failure in sourcing highlight file %s\n' "${zsh_syntax_filename}" >&2
    }
  fi
fi

# Make sure every entry is unique in $PATH. No duplicates.
__old_path="$PATH"
if __new_path="$(printf '%s\n' "$PATH" | tr ':' '\n' | awk '!uniq[$0]++' | tr '\n' : | sed -E 's/:$/\n/')"; then
  PATH="$__new_path"
else
  PATH="$__old_path"
fi
