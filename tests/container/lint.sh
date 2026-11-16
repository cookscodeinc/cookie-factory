#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(cd -- "$script_dir/../.." && pwd)}"
cd "$WORKSPACE_ROOT"

printf '%s\n' '==> pre-commit configuration'
pre-commit validate-config .pre-commit-config.yaml

printf '%s\n' '==> ShellCheck'
mapfile -d '' shell_scripts < <(find . -maxdepth 3 -type f -name '*.sh' -print0)
shellcheck "${shell_scripts[@]}"

printf '%s\n' '==> Ruff lint and format checks'
ruff check tests
ruff format --check tests

printf '%s\n' '==> YAML lint'
yamllint .github .markdownlint-cli2.yml .pre-commit-config.yaml .yamllint.yml compose.yml

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

printf '%s\n' '==> JSON syntax'
python -m json.tool .devcontainer/devcontainer.json >/dev/null
python -m json.tool .prettierrc.json >/dev/null
python -m json.tool cspell.json >/dev/null
python -m json.tool package.json >/dev/null
python -m json.tool package-lock.json >/dev/null

printf '%s\n' '==> Dependency consistency'
python -m pip check
BUNDLE_FROZEN=true BUNDLE_GEMFILE=/opt/jekyll/Gemfile bundle check

printf '%s\n' '==> Lint verification passed'
