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

# ripgrep config
export RIPGREP_CONFIG_PATH=~/.ripgreprc

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

	if [[ $target =~ [^[:digit:]] ]]; then
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
	git diff -U1 $(git_main_branch) -- | gsed 's/[ \t]*$//' | pbcopy
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
		diff -u <(git rev-list --first-parent $(git_current_branch)) \
			<(git rev-list --first-parent $(git dbr)) |
			gsed -ne 's/^ //p' | head -1
	)
	git add -u && git commit -m 'checkpoint'

	grb $(git dbr)
	git push --set-upstream origin $(git_current_branch) --force-with-lease
}

# "git add -u" + "git commit -m" i.e. stages changes and commits them
unalias gam # oh-my-zsh uses this (https://t.ly/hqOq) but i got used to this function before i used OMZ
function gam {
	m="$@"
	if ! (git add -u && git commit -m "$m"); then
		# assume pre-commit changed the file and try again
		git add -u && git commit -m "$m"
	fi
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
		time_since_last_run=$((current_date_time - last_run_date_time))
		if [ $time_since_last_run -lt 86400 ]; then
			return
		fi
	fi

	# Upgrade pip dependencies
	echo "Upgrading pip dependencies..."
	python$ver -m venv ~/tmp/venv"$ver"
	~/tmp/venv"$ver"/bin/pip install -U pip &&
		~/tmp/venv"$ver"/bin/pip install -U \
			ruff \
			mypy \
			pyupgrade \
			reorder_python_imports

	# Update the timestamp file
	echo "$current_date_time" >$fname
}

function lint {
	ver="$1"
	short_ver=$(echo $ver | tr -d ".")
	upgrade_pip_dependencies $ver
	~/tmp/venv$ver/bin/reorder-python-imports --py$short_ver-plus --add-import 'from __future__ import annotations' "${@:2}"
	~/tmp/venv$ver/bin/ruff \
		check \
		--target-version=py"${short_ver}" \
		--extend-select=UP,B,A,C4,SIM,TCH \
		--fix \
		"${@:2}"
	~/tmp/venv$ver/bin/ruff \
		format \
		--target-version=py"${short_ver}" \
		"${@:2}"
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

ffmpeg_resize() {
	local file="$1"
	local target_size_mb="$2"

	if [[ -z "$file" || -z "$target_size_mb" ]]; then
		echo "Usage: ffmpeg_resize <input_file> <target_size_mb>"
		return 1
	fi

	if [[ ! -f "$file" ]]; then
		echo "Error: file not found: $file"
		return 1
	fi

	if ! [[ "$target_size_mb" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
		echo "Error: target_size_mb must be a positive number"
		return 1
	fi

	if ! command -v ffmpeg >/dev/null 2>&1; then
		echo "Error: ffmpeg not found in PATH"
		return 1
	fi

	if ! command -v ffprobe >/dev/null 2>&1; then
		echo "Error: ffprobe not found in PATH"
		return 1
	fi

	local duration
	duration="$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)"

	local duration_sec
	duration_sec="$(awk -v d="$duration" 'BEGIN { if (d+0 <= 0) print 0; else if (d == int(d)) print int(d); else print int(d)+1 }')"
	if [[ "$duration_sec" -le 0 ]]; then
		echo "Error: could not read valid media duration from: $file"
		return 1
	fi

	local target_bits
	target_bits="$(awk -v mb="$target_size_mb" 'BEGIN { printf "%.0f", mb*1000*1000*8 }')"

	local total_bitrate=$((target_bits / duration_sec))
	local audio_bitrate=128000
	local min_audio_bitrate=64000
	local min_video_bitrate=100000
	local video_bitrate=$((total_bitrate - audio_bitrate))

	if [[ "$video_bitrate" -lt "$min_video_bitrate" ]]; then
		audio_bitrate="$min_audio_bitrate"
		video_bitrate=$((total_bitrate - audio_bitrate))
	fi

	if [[ "$video_bitrate" -lt "$min_video_bitrate" ]]; then
		echo "Error: target size too small for duration; cannot keep usable A/V bitrates."
		echo "       Increase target_size_mb (current: $target_size_mb MB)."
		return 1
	fi

	local bufsize=$((video_bitrate * 2))
	local output="${file%.*}-${target_size_mb}mb.mp4"

	ffmpeg -i "$file" \
		-c:v libx264 -b:v "$video_bitrate" -maxrate:v "$video_bitrate" -bufsize:v "$bufsize" \
		-c:a aac -b:a "$audio_bitrate" \
		"$output"
}

# aliases
# marker will find a pattern in the output and put an arrow before it
alias marker='python3.12 -c "import re, sys; [ print(f'\''---> {line}'\'', end='\'''\'') if re.search(sys.argv[1], line) else print(f'\''     {line}'\'', end='\'''\'') for line in sys.stdin ] "'
