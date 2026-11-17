#!/usr/bin/env bash

set -euo pipefail

WORKSPACE_ROOT="${WORKSPACE_ROOT:-/workspace}"
TEMPLATE_ROOT="${TEMPLATE_ROOT:-/template}"
OUTPUT_ROOT="${OUTPUT_ROOT:-/output}"
GENERATED_PROJECT="$OUTPUT_ROOT/cookie-factory"

mkdir -p "$HOME" "$XDG_CACHE_HOME" "$OUTPUT_ROOT"

if [[ ! -f "$TEMPLATE_ROOT/cookiecutter.json" ]]; then
	printf 'Cookiecutter template not found at %s\n' "$TEMPLATE_ROOT" >&2
	exit 1
fi

printf '%s\n' '==> Cookie Factory tests'
python -m pytest \
	--quiet \
	-p no:cacheprovider \
	"$WORKSPACE_ROOT/tests"

if [[ "${SKIP_UPSTREAM_TESTS:-0}" != "1" ]]; then
	printf '%s\n' '==> Upstream template tests'
	python -m pytest \
		--quiet \
		-p no:cacheprovider \
		--template "$TEMPLATE_ROOT" \
		"$TEMPLATE_ROOT/tests"
fi

printf '%s\n' '==> Cookie Factory integration generation'
env \
	BRANCH= \
	COOKIE_REPO="$TEMPLATE_ROOT" \
	OUTPUT_DIR="$OUTPUT_ROOT" \
	PYTHON_ACTIVATE= \
	"$WORKSPACE_ROOT/github-docs-cookie.sh"

python "$WORKSPACE_ROOT/tests/container/verify_generated.py" "$GENERATED_PROJECT"

if [[ "${BUILD_SITE:-0}" == "1" ]]; then
	printf '%s\n' '==> Generated Jekyll build'
	cp /opt/jekyll/Gemfile.lock "$GENERATED_PROJECT/Gemfile.lock"
	export BUNDLE_GEMFILE="$GENERATED_PROJECT/Gemfile"
	export BUNDLE_FROZEN=true
	bundle check
	bundle exec jekyll build \
		--source "$GENERATED_PROJECT" \
		--destination "$OUTPUT_ROOT/site" \
		--trace
	test -f "$OUTPUT_ROOT/site/index.html"

	printf '%s\n' '==> Committed documentation build'
	export BUNDLE_GEMFILE=/opt/jekyll/Gemfile
	bundle check
	bundle exec jekyll build \
		--source "$WORKSPACE_ROOT/docs/jekyll" \
		--destination "$OUTPUT_ROOT/docs-site" \
		--disable-disk-cache \
		--trace
	test -f "$OUTPUT_ROOT/docs-site/index.html"
fi

printf '%s\n' '==> Container verification passed'
