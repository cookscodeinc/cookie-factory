#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f /.dockerenv ]]; then
	exec python "$script_dir/scripts/cookie_factory.py" "$@"
fi

exec docker compose \
	--project-directory "$script_dir" \
	run --rm dev \
	python /workspace/scripts/cookie_factory.py "$@"
