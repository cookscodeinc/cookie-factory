#!/usr/bin/env bash

set -euo pipefail

die() {
	printf 'Release validation failed: %s\n' "$*" >&2
	exit 1
}

enabled() {
	case "${1,,}" in
		1 | true | yes)
			return 0
			;;
		*)
			return 1
			;;
	esac
}

is_stable_tag() {
	[[ "$1" =~ ^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]
}

is_prerelease_tag() {
	local identifier prerelease
	if [[ ! "$1" =~ ^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)-([0-9A-Za-z-]+)(\.[0-9A-Za-z-]+)*$ ]]; then
		return 1
	fi

	prerelease="${1#*-}"
	IFS='.' read -r -a identifiers <<<"$prerelease"
	for identifier in "${identifiers[@]}"; do
		if [[ "$identifier" =~ ^[0-9]+$ && "$identifier" == 0* && "$identifier" != "0" ]]; then
			return 1
		fi
	done
	return 0
}

is_semver_tag() {
	is_stable_tag "$1" || is_prerelease_tag "$1"
}

validate_tag() {
	if is_stable_tag "$RELEASE_TAG"; then
		RELEASE_IS_PRERELEASE=false
	elif is_prerelease_tag "$RELEASE_TAG"; then
		enabled "$ALLOW_PRERELEASE" || die "prerelease tag $RELEASE_TAG requires ALLOW_PRERELEASE=true"
		RELEASE_IS_PRERELEASE=true
	else
		die "tag $RELEASE_TAG is not strict semantic version syntax (vMAJOR.MINOR.PATCH)"
	fi
}

repository_name() {
	local remote_url
	if [[ -n "${GITHUB_REPOSITORY:-}" ]]; then
		printf '%s\n' "$GITHUB_REPOSITORY"
		return
	fi

	remote_url="$(git remote get-url origin 2>/dev/null || true)"
	remote_url="${remote_url%.git}"
	remote_url="${remote_url#git@github.com:}"
	remote_url="${remote_url#https://github.com/}"
	if [[ "$remote_url" == */* && "$remote_url" != *:* ]]; then
		printf '%s\n' "$remote_url"
	fi
}

check_duplicate_release() {
	local check_output repository
	repository="$(repository_name)"

	if [[ "$CHECK_REMOTE_RELEASE" == "auto" ]]; then
		if ! command -v gh >/dev/null 2>&1 || [[ -z "$repository" || -z "${GH_TOKEN:-${GITHUB_TOKEN:-}}" ]]; then
			printf '%s\n' 'Remote duplicate-release check deferred to the tag workflow.' >&2
			return
		fi
	elif ! enabled "$CHECK_REMOTE_RELEASE"; then
		return
	fi

	command -v gh >/dev/null 2>&1 || die "gh is required to check existing releases"
	[[ -n "$repository" ]] || die "unable to determine the GitHub owner/repository"
	[[ -n "${GH_TOKEN:-${GITHUB_TOKEN:-}}" ]] || die "GH_TOKEN or GITHUB_TOKEN is required for the release lookup"

	if check_output="$(gh release view "$RELEASE_TAG" --repo "$repository" 2>&1)"; then
		die "GitHub Release $RELEASE_TAG already exists in $repository"
	fi
	case "${check_output,,}" in
		*"not found"* | *404*) ;;
		*) die "unable to confirm that $RELEASE_TAG is unpublished: $check_output" ;;
	esac
}

run_check() {
	local branch commit_sha master_sha tag_sha version
	command -v git >/dev/null 2>&1 || die "git is required"
	[[ -f "$VERSION_FILE" ]] || die "$VERSION_FILE is missing"

	validate_tag
	version="$(tr -d '[:space:]' <"$VERSION_FILE")"
	[[ -n "$version" ]] || die "$VERSION_FILE is empty"
	[[ "$RELEASE_TAG" == "v$version" ]] || die "$VERSION_FILE contains $version but the release tag is $RELEASE_TAG"

	commit_sha="$(git rev-parse --verify "${RELEASE_COMMIT}^{commit}" 2>/dev/null)" || die "release commit $RELEASE_COMMIT does not exist"
	master_sha="$(git rev-parse --verify "${MASTER_REF}^{commit}" 2>/dev/null)" || die "master reference $MASTER_REF does not exist"
	git merge-base --is-ancestor "$commit_sha" "$master_sha" || die "$commit_sha is not reachable from $MASTER_REF"

	if enabled "$REQUIRE_MASTER_BRANCH"; then
		branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
		[[ "$branch" == "$EXPECTED_BRANCH" ]] || die "current branch is ${branch:-detached}; expected $EXPECTED_BRANCH"
	fi

	if [[ -n "$(git status --porcelain --untracked-files=normal)" ]]; then
		die "the working tree is not clean"
	fi

	if git show-ref --verify --quiet "refs/tags/$RELEASE_TAG"; then
		tag_sha="$(git rev-list --max-count=1 "$RELEASE_TAG")"
		[[ "$tag_sha" == "$commit_sha" ]] || die "$RELEASE_TAG points to $tag_sha instead of $commit_sha"
	elif enabled "$REQUIRE_TAG"; then
		die "required tag $RELEASE_TAG does not exist"
	fi

	check_duplicate_release
	RELEASE_COMMIT_SHA="$commit_sha"
	printf 'Release candidate validated: %s at %s\n' "$RELEASE_TAG" "$RELEASE_COMMIT_SHA"
}

previous_release_tag() {
	local candidate
	while IFS= read -r candidate; do
		if [[ "$candidate" != "$RELEASE_TAG" ]] && is_semver_tag "$candidate"; then
			printf '%s\n' "$candidate"
			return
		fi
	done < <(git tag --merged "$RELEASE_COMMIT_SHA" --sort=-version:refname)
}

generate_notes() {
	local notes_dir previous_tag revision_range
	run_check
	command -v git-cliff >/dev/null 2>&1 || die "git-cliff is required"
	[[ -f "$CLIFF_CONFIG" ]] || die "$CLIFF_CONFIG is missing"

	previous_tag="$(previous_release_tag)"
	if [[ -n "$previous_tag" ]]; then
		revision_range="${previous_tag}..${RELEASE_COMMIT_SHA}"
	else
		revision_range="$RELEASE_COMMIT_SHA"
	fi

	notes_dir="$(dirname -- "$RELEASE_NOTES_FILE")"
	mkdir -p -- "$notes_dir"
	rm -f -- "$RELEASE_NOTES_FILE"
	git-cliff \
		--config "$CLIFF_CONFIG" \
		--tag "$RELEASE_TAG" \
		--output "$RELEASE_NOTES_FILE" \
		"$revision_range"

	[[ -s "$RELEASE_NOTES_FILE" ]] || die "git-cliff produced an empty release notes file"
	grep -Eq '^## ' "$RELEASE_NOTES_FILE" || die "release notes contain no change section"
	grep -Eq '^- ' "$RELEASE_NOTES_FILE" || die "release notes contain no commit entries"
	printf 'Release notes generated: %s\n' "$RELEASE_NOTES_FILE"
}

dry_run() {
	generate_notes
	printf '\n%s\n\n' '--- Release notes preview ---'
	cat "$RELEASE_NOTES_FILE"
	printf '\n%s\n' '--- No tag or GitHub Release was created ---'
	printf 'After approval, create and push the existing-version tag explicitly:\n'
	printf '  git tag --annotate %q --message %q\n' "$RELEASE_TAG" "Release $RELEASE_TAG"
	printf '  git push origin %q\n' "$RELEASE_TAG"
}

usage() {
	printf 'Usage: %s {check|notes|dry-run|release|prerelease}\n' "${0##*/}" >&2
	exit 2
}

repository_root="$(git rev-parse --show-toplevel 2>/dev/null)" || die "run this command inside a Git repository"
cd "$repository_root"

VERSION_FILE="${VERSION_FILE:-VERSION}"
version_default="$(tr -d '[:space:]' <"$VERSION_FILE" 2>/dev/null || true)"
RELEASE_TAG="${RELEASE_TAG:-v$version_default}"
RELEASE_COMMIT="${RELEASE_COMMIT:-HEAD}"
MASTER_REF="${MASTER_REF:-master}"
EXPECTED_BRANCH="${EXPECTED_BRANCH:-master}"
ALLOW_PRERELEASE="${ALLOW_PRERELEASE:-false}"
REQUIRE_MASTER_BRANCH="${REQUIRE_MASTER_BRANCH:-false}"
REQUIRE_TAG="${REQUIRE_TAG:-false}"
CHECK_REMOTE_RELEASE="${CHECK_REMOTE_RELEASE:-auto}"
CLIFF_CONFIG="${CLIFF_CONFIG:-cliff.toml}"
RELEASE_NOTES_FILE="${RELEASE_NOTES_FILE:-build/release-notes.md}"
RELEASE_IS_PRERELEASE=false
RELEASE_COMMIT_SHA=""

case "${1:-}" in
	check)
		run_check
		;;
	notes)
		generate_notes
		;;
	dry-run | release)
		dry_run
		;;
	prerelease)
		validate_tag
		printf '%s\n' "$RELEASE_IS_PRERELEASE"
		;;
	*)
		usage
		;;
esac
