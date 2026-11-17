#!/usr/bin/env bash

set -euo pipefail

GIT_CLIFF_VERSION="2.14.2"
destination_dir="${1:-/usr/local/bin}"

case "$(uname -m)" in
	x86_64)
		archive_target="x86_64-unknown-linux-gnu"
		archive_sha256="24f397c733add5390fdceee3a2088588ab0d5f944ce00d34cb7029b888cf2db4"
		;;
	aarch64 | arm64)
		archive_target="aarch64-unknown-linux-gnu"
		archive_sha256="69e208f6e4baef3a0f9b759d5f44223aa9336b86c691072a3d0c98d35a816e69"
		;;
	*)
		printf 'Unsupported architecture for git-cliff: %s\n' "$(uname -m)" >&2
		exit 1
		;;
esac

archive_name="git-cliff-${GIT_CLIFF_VERSION}-${archive_target}.tar.gz"
download_url="https://github.com/orhun/git-cliff/releases/download/v${GIT_CLIFF_VERSION}/${archive_name}"
temporary_dir="$(mktemp -d)"
trap 'rm -rf -- "$temporary_dir"' EXIT

curl --fail --location --retry 3 --show-error --silent \
	--output "$temporary_dir/$archive_name" \
	"$download_url"
printf '%s  %s\n' "$archive_sha256" "$temporary_dir/$archive_name" | sha256sum --check --status
tar --extract --gzip --file "$temporary_dir/$archive_name" --directory "$temporary_dir"

git_cliff_binary="$(find "$temporary_dir" -type f -name git-cliff -print -quit)"
if [[ -z "$git_cliff_binary" ]]; then
	printf 'git-cliff binary was not present in %s\n' "$archive_name" >&2
	exit 1
fi

mkdir -p -- "$destination_dir"
install --mode 0755 "$git_cliff_binary" "$destination_dir/git-cliff"
"$destination_dir/git-cliff" --version
