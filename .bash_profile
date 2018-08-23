source ~/.alias

export PATH="/usr/local/sbin:$PATH" # For homebrew

export HISTCONTROL=ignoredups:erasedups  # no duplicate entries
export HISTSIZE=100000                   # big big history
export HISTFILESIZE=100000               # big big history
shopt -s histappend                      # append to history, don't overwrite it

# Save and reload the history after each command finishes
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

# virtualenvwrapper
export WORKON_HOME=$HOME/.virtualenvs
export PROJECT_HOME=$HOME/Devel
source /usr/local/bin/virtualenvwrapper.sh

# Show which branch you're on and if the branch is dirty
function parse_git_dirty {
    [[ $(git status 2> /dev/null | tail -n1) =~ ^nothing\ to\ commit,\ working\ [[:alpha:]]+\ clean$ ]] || echo "*"
}
function parse_git_branch {
    git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/[\1$(parse_git_dirty)] /"
}
export PS1="\w \$(parse_git_branch)$ "

## Convenience methods for git
## GIT {

function gsm {
  # sm == sync merge
  _git_update "merge master --no-edit" || gconf
}
function gsmao {
  # smf = sync merge accept-ours
  gsm || git accept-ours && gac
}
function gsm-all {
  # gsm all branches

  OLD_BRANCH=$(git branch-name)
  git checkout master
  git pull

  for b in $(git branch | tr -d '*' | grep -v master)
  do
    gco "$b"
    git merge master --no-edit
    gpo
  done

  gco "$OLD_BRANCH"
}
function grb {
  # rb == rebase
  _git_update "rebase master"
}
function _git_update {
  # pull the latest master and perform what's in $1 upon this branch

  old_branch=`git branch-name`
  git checkout master && git pull && git checkout $old_branch && git $1
}
function gam {
  # add changes and commit them. runs twice to bluntly
  # accept any pre-commit changes

  git add -u && git commit -m "$*"
  if [ $? -ne 0 ]
  then
    git add -u && git commit -m "$*"
  fi
}
function gac {
  # adds changes and commits without editing (for example for after
  # merge conflicts are resolved). runs twice for the same reason as above
  
  git add -u && git commit --no-edit
  if [ $? -ne 0 ]
  then
    git add -u && git commit --no-edit
  fi
}
function gnbr {
  # create new branch

  git stash
  git checkout master
  git prune
  git remote prune origin
  git pull
  git stash pop
  git checkout -b "$1"
}
function gbd {
  # delete a local and remote branch

  git branch -D "$1"
  git push origin --delete "$1"
}

# To use this, first
# cp /usr/local/etc/bash_completion.d/git-completion.bash ~/.git-completion.bash
if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
  
  # Autocomplete for git aliases
  __git_complete gco _git_checkout
  __git_complete gbd _git_branch
fi

## } GIT

# Install/update Python requirements
function pyvenv {
  venv_name="$1"
  version="$2"
  pyenv virtualenv "$version" "$venv_name"
  pyenv activate "$venv_name"
  pip install -r requirements*.txt
}

# Get human readable time as ms since epoch (rounded to nearest second)
# $ nlp-dt-ms now
# 1521522141000
function nlp-dt-ms {
    python3 -c \
"""
import sys
from parsedatetime import Calendar
from datetime import datetime

from tzlocal import get_localzone

tz = get_localzone()

now_dt = Calendar().parseDT(datetimeString=' '.join(sys.argv[1:]), tzinfo=tz)[0]
epoch_dt = datetime.fromtimestamp(0, tz)

print('{:.0f}'.format((now_dt - epoch_dt).total_seconds() * 1000))
"""
}

# Create file(s) nested deep in directories which may not exist
# See https://github.com/looking-for-a-job/mktouch.sh.cli
mktouch() {
    if [ $# -lt 1 ]
    then
        errcho "Missing argument"
        return 1
    fi

    for f in "$@"
    do
        mkdir -p -- "$(dirname -- "$f")"
        touch -- "$f"
    done
}
