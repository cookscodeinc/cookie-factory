#!/usr/bin/env bash

set -euo pipefail

WORKSPACE_ROOT="${WORKSPACE_ROOT:-/workspace}"
COOKIECUTTER_ROOT="${COOKIECUTTER_ROOT:-/templates}"
OUTPUT_ROOT="${OUTPUT_ROOT:-/output}"
GENERATED_PROJECT="$OUTPUT_ROOT/cookie-factory"
GITHUB_DOCS_TEMPLATE="$COOKIECUTTER_ROOT/github-doc-cookiecutter"

mkdir -p "$HOME" "$XDG_CACHE_HOME" "$OUTPUT_ROOT"

printf '%s\n' '==> Cookie Factory tests'
python -m pytest \
	--quiet \
	-p no:cacheprovider \
	"$WORKSPACE_ROOT/tests"

if [[ "${SKIP_UPSTREAM_TESTS:-0}" != "1" ]]; then
	printf '%s\n' '==> All enabled upstream template tests'
	python "$WORKSPACE_ROOT/scripts/cookie_factory.py" test-all
fi

printf '%s\n' '==> Cookie Factory integration generation'
env \
	BRANCH= \
	COOKIE_REPO="$GITHUB_DOCS_TEMPLATE" \
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
