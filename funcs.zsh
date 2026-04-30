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

tag() {
	emulate -L zsh
	setopt nounset pipefail

	local bump="${1:-}"
	local version_file file_type
	local -a manifests
	local version new_version
	local major minor patch
	local tag_name

	if [[ "$bump" != "major" && "$bump" != "minor" && "$bump" != "patch" ]]; then
		echo "usage: tag {major|minor|patch}" >&2
		return 1
	fi

	git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
		echo "not in a git repository" >&2
		return 1
	}

	if [[ -f "setup.cfg" ]]; then
		version_file="setup.cfg"
		file_type="setup_cfg"
	else
		manifests=(custom_components/*/manifest.json(N))
	fi

	if [[ -z "${file_type:-}" && "${#manifests[@]}" -eq 1 ]]; then
		version_file="${manifests[1]}"
		file_type="manifest_json"
	elif [[ -z "${file_type:-}" && "${#manifests[@]}" -gt 1 ]]; then
		echo "multiple manifest.json files found under custom_components" >&2
		return 1
	elif [[ -z "${file_type:-}" ]]; then
		echo "missing setup.cfg or custom_components/*/manifest.json" >&2
		return 1
	fi

	git checkout main || return 1
	git pull --ff-only || return 1

	if [[ "$file_type" == "setup_cfg" ]]; then
		version="$(perl -ne 'if (/^[ \t]*version[ \t]*=[ \t]*([0-9]+\.[0-9]+\.[0-9]+)[ \t]*$/) { print "$1\n"; exit }' "$version_file")"
	else
		version="$(jq -r '.version' "$version_file")" || return 1
	fi

	[[ -n "$version" ]] || {
		echo "could not parse version from $version_file" >&2
		return 1
	}

	[[ "$version" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]] || {
		echo "unsupported version format in $version_file: $version" >&2
		return 1
	}

	IFS='.' read -r major minor patch <<<"$version"

	case "$bump" in
	major)
		((major += 1))
		minor=0
		patch=0
		;;
	minor)
		((minor += 1))
		patch=0
		;;
	patch)
		((patch += 1))
		;;
	esac

	new_version="${major}.${minor}.${patch}"
	tag_name="v${new_version}"

	if [[ "$file_type" == "setup_cfg" ]]; then
		perl -0pi -e "s/^[ \t]*version[ \t]*=[ \t]*[0-9]+\.[0-9]+\.[0-9]+[ \t]*\$/version = $new_version/m" "$version_file" || return 1
	else
		jq --arg version "$new_version" '.version = $version' "$version_file" >"$version_file.tmp" || return 1
		mv "$version_file.tmp" "$version_file" || return 1
	fi

	git add "$version_file" || return 1
	git commit -m "$tag_name" || return 1
	git tag "$tag_name" || return 1
	git push origin main "refs/tags/$tag_name" || return 1
	gh release create "$tag_name" --generate-notes || return 1

	[[ "$file_type" == "setup_cfg" ]] || return 0

	if [[ ! -f ".venv/bin/activate" ]]; then
		uv venv || return 1
	fi

	source .venv/bin/activate || return 1
	uv pip install -U build setuptools twine || return 1
	rm -rf dist build *.egg-info
	python -m build || return 1
	python -m twine upload --repository pypi dist/* || return 1
}

bump() {
	emulate -L zsh
	setopt pipefail null_glob

	if [[ $# -ne 2 ]]; then
		echo "usage: bump <lib> <version|latest>" >&2
		return 2
	fi

	local lib="$1"
	local want="$2"
	local ver="$want"

	command -v perl >/dev/null 2>&1 || {
		echo "missing: perl" >&2
		return 1
	}
	command -v curl >/dev/null 2>&1 || {
		echo "missing: curl" >&2
		return 1
	}
	command -v git >/dev/null 2>&1 || {
		echo "missing: git" >&2
		return 1
	}
	command -v rg >/dev/null 2>&1 || {
		echo "missing: rg" >&2
		return 1
	}

	if [[ "$want" == "latest" ]]; then
		command -v jq >/dev/null 2>&1 || {
			echo "missing: jq (required for latest)" >&2
			return 1
		}
		ver="$(
			curl -fsSL "https://pypi.org/pypi/${lib}/json" |
				jq -r '.info.version // empty'
		)" || {
			echo "failed to resolve latest version from PyPI for $lib" >&2
			return 1
		}
		[[ -n "$ver" && "$ver" != "null" ]] || {
			echo "PyPI returned no version for $lib" >&2
			return 1
		}
	fi

	local escaped_lib
	escaped_lib="$(printf '%s' "$lib" | perl -pe 's/([^A-Za-z0-9_])/\\$1/g')"

	local -a candidate_globs
	candidate_globs=(
		requirements.txt
		dev-requirements.txt
		.pre-commit-config.yaml
		setup.cfg
		pyproject.toml
		custom_components/*/manifest.json
	)

	local -a existing_files
	local candidate_glob
	for candidate_glob in "${candidate_globs[@]}"; do
		existing_files+=($~candidate_glob(N))
	done

	((${#existing_files} > 0)) || {
		echo "no candidate dependency files exist in this repo" >&2
		return 1
	}

	local -a matched_files
	matched_files=("${(@f)$(rg -l -F -- "$lib" -- "${existing_files[@]}" 2>/dev/null || true)}")

	((${#matched_files} > 0)) || {
		echo "no matching files found for $lib" >&2
		return 1
	}

	local -a changed_files
	local f
	for f in "${matched_files[@]}"; do
		[[ -f "$f" ]] || continue

		cp "$f" "$f.bak" || return 1

		LIB="$escaped_lib" VER="$ver" perl -0pi -e '
  my $lib = $ENV{LIB};
  my $ver = $ENV{VER};

  # Only replace actual versioned dependency specs.
  # Preserves comparator and spacing.
  #
  # Matches:
  #   lib==1.2.3
  #   lib >= 1.2.3
  #   "lib>=1.2.3"
  #   lib[extra]~=1.2
  #
  # Does NOT match:
  #   https://github.com/org/lib
  #   documentation URLs
  #   random prose strings
  s{
    (?<![A-Za-z0-9_./:-])         # avoid URLs / package-name substrings
    ($lib(?:\[[^][]+\])?\s*)      # package name (+ optional extras)
    (===|==|~=|!=|<=|>=|<|>)      # comparator
    (\s*)                         # original spacing
    ([A-Za-z0-9*+!._-]+)          # existing version
  }{$1.$2.$3.$ver}gex;
' "$f" || {
			mv "$f.bak" "$f"
			return 1
		}

		if ! cmp -s "$f.bak" "$f"; then
			rm -f "$f.bak"
			changed_files+=("$f")
			echo "updated $f"
		else
			mv "$f.bak" "$f"
		fi
	done

	((${#changed_files} > 0)) || {
		echo "found $lib but no versions changed" >&2
		return 1
	}

	local branch="bump-${lib//[^A-Za-z0-9._-]/-}-${ver}"

	git checkout -b "$branch" || return 1
	git add -- "${changed_files[@]}" || return 1
	git commit -m "Bump $lib to $ver" || return 1

	if command -v gh >/dev/null 2>&1; then
		git push -u origin "$branch" || return 1

		local pr_url
		pr_url="$(
			gh pr create \
				--fill \
				--title "Bump $lib to $ver" \
				--body "Automated dependency bump for \`$lib\` to \`$ver\`."
		)" || {
			echo "commit created, but gh pr create failed" >&2
			return 1
		}

		echo "created PR: $pr_url"

		gh pr merge --auto --squash --delete-branch "$pr_url" || {
			echo "PR created, but enabling auto-merge failed" >&2
			return 1
		}
	else
		echo "gh not found; skipping PR creation and auto-merge"
	fi

	echo "done: $lib -> $ver"
}
