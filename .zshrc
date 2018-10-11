# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/Users/mxr/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
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
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
)

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

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# aliases
source ~/.alias

# zsh overrides
ZSH_THEME_GIT_PROMPT_PREFIX="("
ZSH_THEME_GIT_PROMPT_SUFFIX=") "
ZSH_THEME_GIT_PROMPT_DIRTY=" ✗"
ZSH_THEME_GIT_PROMPT_CLEAN=" ✔"
function reldir {
	echo $(realpath --relative-to='/Users/mxr' $(pwd))
}
PROMPT='${ret_status} %{$fg[cyan]%}~/$(reldir)%{$reset_color%} $(git_prompt_info)'

# pyenv
export PATH="~/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# intellij config
# https://youtrack.jetbrains.com/issue/IDEA-153536#focus=streamItem-27-2851261-0-0
bindkey "\e\eOD" backward-word  
bindkey "\e\eOC" forward-word 

# go
export PATH=$PATH:/usr/local/opt/go@1.10/libexec/bin
export PATH="/usr/local/opt/go@1.10/bin:$PATH"
export GOPATH=~/src/go
export PATH=$GOPATH/bin:$PATH

function grb {
  # rb == rebase
  _git_update master
  git rebase master
}
function _git_update {
  # pull the latest $1 and go back to the last branch

  OLD_BRANCH=$(git branch-name)
  
  git checkout "$1"
  git pull
  git checkout "$OLD_BRANCH"
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

  (git branch -D "$1" > /dev/null 2>&1 &)
  (git push origin --delete "$1" > /dev/null 2>&1 &)
}

function gpo {
  git push origin "$(git branch-name)"
  git github-compare
}
