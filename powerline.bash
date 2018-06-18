#!/bin/bash
__powerline() {

  readonly MAX_PATH_LENGTH=30
  readonly GIT_BRANCH_SYMBOL=''
  readonly GIT_BRANCH_CHANGED_SYMBOL='Δ'
  readonly GIT_BRANCH_ADDED_SYMBOL='+'
  readonly GIT_NEED_PUSH_SYMBOL='↑'
  readonly GIT_NEED_PULL_SYMBOL='↓'

  # Powerline symbols
  readonly BLOCK_START=''

  # ANSI Colours
  readonly BLACK=0
  readonly RED=1
  readonly GREEN=2
  readonly YELLOW=3
  readonly BLUE=4
  readonly MAGENTA=5
  readonly CYAN=6
  readonly WHITE=7

  readonly BLACK_BRIGHT=8
  readonly RED_BRIGHT=9
  readonly GREEN_BRIGHT=10
  readonly YELLOW_BRIGHT=11
  readonly BLUE_BRIGHT=12
  readonly MAGENTA_BRIGHT=13
  readonly CYAN_BRIGHT=14
  readonly WHITE_BRIGHT=15

  # Font effects
  readonly DIM="\\[$(tput dim)\\]"
  readonly REVERSE="\\[$(tput rev)\\]"
  readonly RESET="\\[$(tput sgr0)\\]"
  readonly BOLD="\\[$(tput bold)\\]"

  # Generate terminal colour codes
  # $1 is an int (a colour) and $2 must be 'fg' or 'bg'
  __colour() {
    case "$2" in
      'fg'*)
        echo "\\[$(tput setaf "$1")\\]"
        ;;
      'bg'*)
        echo "\\[$(tput setab "$1")\\]"
        ;;
      *)
        echo "\\[$(tput setab "$1")\\]"
        ;;
    esac
  }

  # Generate a single-coloured block for the prompt
  __prompt_block() {
    local bg; local fg
    if [ ! -z "${1+x}" ]; then
      bg=$1
    else
      if [ ! -z "$last_bg" ]; then
        bg=$last_bg
      else
        bg=$DEFAULT_BG
      fi
    fi
    if [ ! -z "${2+x}" ]; then
      fg=$2
    else
      fg=$DEFAULT_FG
    fi

    local block

    # Need to generate a separator if the background changes
    if [[ ! -z "$last_bg" && "$bg" != "$last_bg" ]]; then
      block+="$(__colour "$bg" 'bg')"
      block+="$(__colour "$last_bg" 'fg')"
      block+="$BLOCK_START $RESET"
      block+="$(__colour "$bg" 'bg')"
      block+="$(__colour "$fg" 'fg')"
    else
      block+="$(__colour "$bg" 'bg')"
      block+="$(__colour "$fg" 'fg')"
      block+=" "
    fi

    if [ ! -z "${3+x}" ]; then
      block+="$3 $RESET"
    fi

    last_bg=$bg

    __block_text="$block"
  }

  function __end_block() {
    __block_text=''
    if [ ! -z "$last_bg" ]; then
      __block_text+="$RESET"
      __block_text+="$(__colour "$last_bg" 'fg')"
      __block_text+="$BLOCK_START$RESET"
      __block_text+="$RESET"
    fi
    __block_text+=' '
  }

  ### Prompt components

  __git_block() {

    # check if pwd is under git
    if ! git rev-parse --is-inside-git-dir > /dev/null 2> /dev/null; then
      # not in a git repo, bail out
      __block_text=''
      return
    fi

    # get current branch name or short SHA1 hash for detached head
    local branch; local ref_symbol
    branch="$(git symbolic-ref --short HEAD 2>/dev/null)"
    # shellcheck disable=SC2181
    if [ $? != 0 ]; then
      branch="$(git describe --tags --always 2>/dev/null)"
      ref_symbol='➦'
    else
      ref_symbol=$GIT_BRANCH_SYMBOL
    fi

    # In pcmode (and only pcmode) the contents of
    # $gitstring are subject to expansion by the shell.
    # Avoid putting the raw ref name in the prompt to
    # protect the user from arbitrary code execution via
    # specially crafted ref names (e.g., a ref named
    # '$(IFS=_;cmd=sudo_rm_-rf_/;$cmd)' would execute
    # 'sudo rm -rf /' when the prompt is drawn).  Instead,
    # put the ref name in a new global variable (in the
    # __git_ps1_* namespace to avoid colliding with the
    # user's environment) and reference that variable from
    # PS1.
    # note that the $ is escaped -- the variable will be
    # expanded later (when it's time to draw the prompt)
    if shopt -q promptvars; then
      export __git_ps1_block="$branch"
      ref="$ref_symbol \${__git_ps1_block}"
    else
      ref="$ref_symbol $branch"
    fi

    local marks
    local bg=$GREEN
    local fg=$BLACK

    # check if HEAD is dirty
    if ! (git diff --no-ext-diff --cached --quiet); then
      bg=$YELLOW
      marks+=" $GIT_BRANCH_ADDED_SYMBOL"
    fi
    if ! (git diff --no-ext-diff --quiet); then
      bg=$YELLOW
      marks+=" $GIT_BRANCH_CHANGED_SYMBOL"
    fi

    __prompt_block $bg $fg "$ref$marks"
  }


  __pwd_block() {
    # Use ~ to represent $HOME prefix
    local pwd; pwd=$(pwd | sed -e "s|^$HOME|~|")
    # shellcheck disable=SC1001,SC2088
    if [[ ( $pwd = ~\/*\/* || $pwd = \/*\/*/* ) && ${#pwd} -gt $MAX_PATH_LENGTH ]]; then
      local IFS='/'
      read -ra split <<< "$pwd"
      local n=${#split[@]}
      ((--n))
      pwd=${split[$n]}
      ((--n))
      for ((i=n;i>=0;--i)); do
          local s=${split[$i]}
          pwd="${s:0:1}/$pwd"
      done
    fi
    __prompt_block $BLACK_BRIGHT $WHITE_BRIGHT "$pwd"
    #__prompt_block $BLUE $WHITE "$pwd"
  }

  # Build the prompt
  prompt() {
    last_bg=''

    __pwd_block
    PS1=$__block_text

    __git_block
    PS1+=$__block_text

    __end_block
    PS1+=$__block_text
  }

  PROMPT_COMMAND=prompt
}

__powerline
unset __powerline
