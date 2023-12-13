# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/Users/$USER/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# Caution: this setting can cause issues with multiline prompts (zsh 5.7.1 and newer seem to work)
# See https://github.com/ohmyzsh/ohmyzsh/issues/5765
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# gitignore for fzf
# https://github.com/junegunn/fzf/tree/168829b5550336886a426073670153f84f8a34b2#respecting-gitignore
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# fzf completions and shortcuts
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# source highlighting for less
# brew install source-highlight
export LESSOPEN="| /usr/local/bin/src-hilite-lesspipe.sh %s"
export LESS=' -R '

# i run brew `cleanup --quiet` manually every-so-often
export HOMEBREW_NO_INSTALL_CLEANUP=true

# git QOL improvements

# "git sync-merge" i.e. get the latest main branch and merge it into this one
function gsm {
    local cbr=$(git_current_branch)
    local m=$(git_main_branch)

    gco $m
    ggl

    gco $cbr
    git merge $m --no-edit
}

# "git sync-merge branch" i.e. get the latest main branch and merge it into the given target
# target can be branch or PR number (depends on `gh` tool)
function gsmb {
    local target="$1"
    local m=$(git_main_branch)

    gco $m
    ggl

    if [[ $target =~ [^[:digit:]] ]]
    then
        gco $target
    else
        gh co $target
    fi

    git merge $m --no-edit
}


# "git cleanup" i.e. delete all branches except the main one
function gcu {
    gco $(git_main_branch) && git branch -D $(git branch | sort -r | tail -n'+2')
}

# "git diff copy" i.e. copies the diff concisely with stripped trailing whitespace
function gdcp {
    git diff -U1 $(git_main_branch) -- | gsed  's/[ \t]*$//' | pbcopy
    echo "copied"
}

function gsmpr {
    local cbr=$(git_current_branch)

    gh co "$1"
    gsm
    ggp

    gco $cbr
}

# "git rebase squash" i.e. squishes everything into one commit rebased onto the tip of the main branch
function grsq {
    gsm

    git reset --soft $(
        diff -u <(git rev-list --first-parent $(git_current_branch))   \
                <(git rev-list --first-parent $(git dbr))              \
        | gsed -ne 's/^ //p' | head -1
    )
    git add -u && git commit -m 'checkpoint'

    grb $(git dbr)
    git push --set-upstream origin $(git_current_branch) --force-with-lease
}

# "git add -u" + "git commit -m" i.e. stages changes and commits them
unalias gam # oh-my-zsh uses this (https://t.ly/hqOq) but i got used to this function before i used OMZ
function gam {
    m="$@"
    git add -u && git commit -m "$m"
}

# zsh ggp but quiet
function ggp() {
  if [[ "$#" != 0 ]] && [[ "$#" != 1 ]]; then
    git push --quiet origin "${*}"
  else
    [[ "$#" == 0 ]] && local b="$(git_current_branch)"
    git push --quiet origin "${b:=$1}"
  fi
}

function gmne() {
    git merge --quiet --no-edit "$@"
}

alias gprunesquashmerged='(
dbr=$(git dbr) && git checkout -q $dbr && git for-each-ref refs/heads/ "--format=%(refname:short)" |
while read branch
do
  mb=$(git merge-base $dbr $branch) &&
  [[ $(git cherry $dbr $(git commit-tree $(git rev-parse "$branch^{tree}") -p $mb -m _)) == "-"* ]] &&
  git branch -D $branch
done
)'

function decode_qsp {
    python3 -c """
from urllib.parse import unquote, parse_qs
import json

print(json.dumps(parse_qs(unquote('"$1"')), sort_keys=True, indent=2))
"""
}

# remove the trailing newline from a file (if it exists)
# useful when editing auto-generated files manually
function chomp {
    perl -p -i -e 'chomp if eof' "$1"
}

function upgrade_pip_dependencies {
  current_date_time="$(date +%s)"
  ver="$1"
  fname="/tmp/.pip_upgrade_timestamp_$ver"

  # Check if the function has run in the last day
  if [ -f $fname ]; then
    last_run_date_time=$(cat $fname)
    time_since_last_run=$((current_date_time-last_run_date_time))
    if [ $time_since_last_run -lt 86400 ]; then
      return
    fi
  fi

  # Upgrade pip dependencies
  echo "Upgrading pip dependencies..."
  ~/tmp/venv"$ver"/bin/pip install -U pip && \
  ~/tmp/venv"$ver"/bin/pip install -U \
                    black \
                    flake8 \
                    flake8-bugbear \
                    flake8-comprehensions \
                    flake8-tidy-imports \
                    mypy \
                    pyupgrade \
                    reorder_python_imports \
                    unimport

  # Update the timestamp file
  echo "$current_date_time" > $fname
}

function lint {
    ver="$1"
    short_ver=$(echo $ver | tr -d ".")
    upgrade_pip_dependencies $ver
    ~/tmp/venv$ver/bin/pyupgrade --py$short_ver-plus "${@:2}"
    ~/tmp/venv$ver/bin/black "${@:2}"
    ~/tmp/venv$ver/bin/unimport "${@:2}"
    ~/tmp/venv$ver/bin/reorder-python-imports --py$short_ver-plus --add-import 'from __future__ import annotations' "${@:2}"
    ~/tmp/venv$ver/bin/flake8 --extend-ignore="E203,E501" "${@:2}"
    ~/tmp/venv$ver/bin/mypy \
        --install-types \
        --check-untyped-defs \
        --disallow-any-generics \
        --disallow-incomplete-defs \
        --disallow-untyped-defs \
        --no-implicit-optional \
        --warn-redundant-casts \
        --warn-unused-ignores \
        --ignore-missing-import \
        "${@:2}"
}

function igdl {
    part=$(cut -d'/' -f5 <<< "${1}")
    ~/tmp/venv3.11/bin/instaloader -- "-${part}"
}

# aliases
# marker will find a pattern in the output and put an arrow next to it, using a consistent width
alias marker='python -c "import re, sys; [print(f'"'{line.rstrip()}{' '*(100-len(line))} <----') if re.search(sys.argv[1], line) else print(line,end='') for line in sys.stdin]"'"'
