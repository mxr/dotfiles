#!/usr/bin/env bats

setup() {
	cd "$BATS_TEST_TMPDIR" || exit 1
}

# Runs tag in zsh with git and cargo stubbed out. The git stub prints the tag it would create.
tag() {
	run zsh -c "source '$BATS_TEST_DIRNAME/../funcs.zsh'; git() { [[ \$1 == tag ]] && echo \"created \$2\"; return 0; }; cargo() { :; }; tag $*"
}

@test "rejects bad usage" {
	for args in "" "pre pre" "major foo" "foo"; do
		tag "$args"
		[ "$status" -eq 1 ]
		[[ "$output" == *"usage: tag"* ]]
	done
}

@test "bumps a final version" {
	echo 1.2.3 >.version
	tag minor
	[ "$status" -eq 0 ]
	[[ "$output" == *"created v1.3.0"* ]]
	[ "$(cat .version)" = 1.3.0 ]
}

@test "starts, bumps, and releases a prerelease" {
	echo 1.0.1 >.version
	tag major pre
	[ "$(cat .version)" = 2.0.0rc0 ]
	[[ "$output" == *"created v2.0.0rc0"* ]]
	tag pre
	[ "$(cat .version)" = 2.0.0rc1 ]
	tag major
	[ "$(cat .version)" = 2.0.0 ]
	[[ "$output" == *"created v2.0.0"* ]]
}

@test "starts minor and patch prereleases" {
	echo 1.0.1 >.version
	tag minor pre
	[ "$(cat .version)" = 1.1.0rc0 ]
	echo 1.0.1 >.version
	tag patch pre
	[ "$(cat .version)" = 1.0.2rc0 ]
}

@test "tag pre needs an existing prerelease" {
	echo 1.0.1 >.version
	tag pre
	[ "$status" -eq 1 ]
	[[ "$output" == *"1.0.1 is not a prerelease"* ]]
	[ "$(cat .version)" = 1.0.1 ]
}

@test "rejects a bump that does not match the prerelease" {
	echo 2.0.0rc1 >.version
	for args in minor patch "major pre" "minor pre"; do
		tag "$args"
		[ "$status" -eq 1 ]
		[[ "$output" == *"2.0.0rc1 is a major prerelease"* ]]
	done
	[ "$(cat .version)" = 2.0.0rc1 ]
}

@test "infers minor and patch prereleases" {
	echo 1.1.0rc0 >.version
	tag minor
	[ "$(cat .version)" = 1.1.0 ]
	echo 1.0.2rc0 >.version
	tag patch
	[ "$(cat .version)" = 1.0.2 ]
}

@test "updates setup.cfg" {
	printf '[metadata]\nversion = 2.0.0rc1\n' >setup.cfg
	tag major
	[ "$status" -eq 0 ]
	grep -qx 'version = 2.0.0' setup.cfg
}

@test "updates pyproject.toml" {
	command -v uv >/dev/null || skip "uv not installed"
	printf '[project]\nname = "x"\nversion = "0.1.0"\n' >pyproject.toml
	tag patch pre
	[ "$status" -eq 0 ]
	grep -qx 'version = "0.1.1rc0"' pyproject.toml
}

@test "uses semver prereleases in Cargo.toml" {
	printf '[package]\nname = "x"\nversion = "1.2.3"\n' >Cargo.toml
	tag minor pre
	grep -qx 'version = "1.3.0-rc.0"' Cargo.toml
	tag pre
	grep -qx 'version = "1.3.0-rc.1"' Cargo.toml
	tag minor
	[[ "$output" == *"created v1.3.0"* ]]
	grep -qx 'version = "1.3.0"' Cargo.toml
}

@test "updates a home assistant manifest" {
	mkdir -p custom_components/x
	echo '{"domain": "x", "version": "1.0.1"}' >custom_components/x/manifest.json
	tag major pre
	[ "$status" -eq 0 ]
	grep -qF '"version": "2.0.0rc0"' custom_components/x/manifest.json
}

@test "fails without a version file" {
	tag patch
	[ "$status" -eq 1 ]
	[[ "$output" == *"missing package.json"* ]]
}
