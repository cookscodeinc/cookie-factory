#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(cd -- "$script_dir/../.." && pwd)}"
cd "$WORKSPACE_ROOT"

printf '%s\n' '==> Container Git safety'
if ! git config --system --get-all safe.directory | grep --fixed-strings --line-regexp -- "$WORKSPACE_ROOT"; then
	printf 'Container image does not trust the exact workspace path: %s\n' "$WORKSPACE_ROOT" >&2
	exit 1
fi

printf '%s\n' '==> pre-commit configuration'
pre-commit validate-config .pre-commit-config.yaml

printf '%s\n' '==> Repository hygiene'
python tests/container/check_repository.py

printf '%s\n' '==> ShellCheck'
mapfile -d '' shell_scripts < <(
	git ls-files --cached --others --exclude-standard -z -- '*.sh'
)
shellcheck "${shell_scripts[@]}"

printf '%s\n' '==> Ruff lint and format checks'
ruff check scripts tests
ruff format --check scripts tests

printf '%s\n' '==> YAML lint'
mapfile -d '' yaml_files < <(
	git ls-files --cached --others --exclude-standard -z -- '*.yaml' '*.yml'
)
yamllint "${yaml_files[@]}"

printf '%s\n' '==> GitHub Actions lint'
actionlint -color

printf '%s\n' '==> Dockerfile lint'
hadolint --config .hadolint.yml docker/Dockerfile

printf '%s\n' '==> Markdown lint'
markdownlint-cli2 --config .markdownlint-cli2.yml '**/*.md'

printf '%s\n' '==> Spelling'
cspell --no-progress --show-suggestions .

printf '%s\n' '==> Prettier check'
prettier --check '**/*.{json,md,yaml,yml}'

printf '%s\n' '==> Dependency consistency'
python -m pip check
BUNDLE_FROZEN=true BUNDLE_GEMFILE=/opt/jekyll/Gemfile bundle check

printf '%s\n' '==> Lint verification passed'
