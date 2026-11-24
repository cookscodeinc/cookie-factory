#!/usr/bin/env bash

set -euo pipefail

OUTPUT_DIR="${OUTPUT_DIR:-./build}"
INSTALL_DIR="${INSTALL_DIR:-}"
GEMFILE_LOCK_SOURCE="${GEMFILE_LOCK_SOURCE:-}"
# OUTPUT_DIR="$HOME/Documents/git_repo/"

PYTHON_ENV="${PYTHON_ENV:-$HOME/Documents/git_repo/nutri-matic}"
PYTHON_ACTIVATE="${PYTHON_ACTIVATE-$PYTHON_ENV/.venv/bin/activate}"

PROJECT="${PROJECT:-Cookie Factory}"
PROJECT_SLUG="${PROJECT_SLUG:-cookie-factory}"
# PROJECT="the-cook-family-comedy"

COOKIE_REPO="${COOKIE_REPO:-git@github.com:jcook3701/github-docs-cookiecutter.git}"
BRANCH="${BRANCH-feat-024}"

SITE_TYPE="${SITE_TYPE:-documentation}"
PAGES_SITE_TYPE="${PAGES_SITE_TYPE:-project}"
CUSTOM_DOMAIN="${CUSTOM_DOMAIN:-}"
COMPANY="${COMPANY:-}"
FORMSPREE_FORM_PATH="${FORMSPREE_FORM_PATH:-}"
# DESCRIPTION="Welcome to the family history repository. This project serves as a centralized collection of genealogical data, trees, and historical documentation."
DESCRIPTION="${DESCRIPTION:-}"
GITHUB_ORG="${GITHUB_ORG:-cookscodeinc}"
LICENSE="${LICENSE:-GPL-3.0-or-later}"
PUB_YEAR="${PUB_YEAR:-2026}"
THEME="${THEME:-just-the-docs/just-the-docs@v0.11.0}"
TEMPLATE_TYPE="${TEMPLATE_TYPE:-cookiecutter}"

if [[ -z "$COMPANY" ]]; then
	COMPANY="Cook's Code, Inc."
fi
if [[ -z "$DESCRIPTION" ]]; then
	DESCRIPTION="Containerized project generators for repeatable Cook's Code repositories."
fi

GENERATED_PROJECT="$OUTPUT_DIR/$PROJECT_SLUG"

if [[ -z "$PROJECT" || -z "$PROJECT_SLUG" || "$PROJECT_SLUG" == "." || "$PROJECT_SLUG" == ".." || "$PROJECT_SLUG" == */* || -z "$OUTPUT_DIR" || "$OUTPUT_DIR" == "/" ]]; then
	printf 'Refusing to remove an unsafe project path: %q\n' "$GENERATED_PROJECT" >&2
	exit 1
fi

rm -rf -- "$GENERATED_PROJECT"

venv_activated=false
if [[ -n "$PYTHON_ACTIVATE" ]]; then
	if [[ -r "$PYTHON_ACTIVATE" ]]; then
		# shellcheck disable=SC1090
		source "$PYTHON_ACTIVATE"
		venv_activated=true
	elif ! command -v cookiecutter >/dev/null 2>&1; then
		printf 'Virtual environment activation script not found: %s\n' "$PYTHON_ACTIVATE" >&2
		exit 1
	fi
fi

cookiecutter_args=("$COOKIE_REPO")
if [[ -n "$BRANCH" ]]; then
	cookiecutter_args+=(--checkout "$BRANCH")
fi
cookiecutter_args+=(
	--no-input
	--output-dir "$OUTPUT_DIR"
	project_name="$PROJECT"
	project_slug="$PROJECT_SLUG"
	site_type="$SITE_TYPE"
	pages_site_type="$PAGES_SITE_TYPE"
	custom_domain="$CUSTOM_DOMAIN"
	company="$COMPANY"
	formspree_form_path="$FORMSPREE_FORM_PATH"
	description="$DESCRIPTION"
	github_org="$GITHUB_ORG"
	license="$LICENSE"
	publication_year="$PUB_YEAR"
	theme="$THEME"
	template_type="$TEMPLATE_TYPE"
)

# Note: Github Docs Cookiecutter Project
cookiecutter "${cookiecutter_args[@]}"

if [[ -n "$INSTALL_DIR" ]]; then
	install_parent="$(dirname -- "$INSTALL_DIR")"
	install_staging="${INSTALL_DIR}.new"
	if [[ "$(basename -- "$INSTALL_DIR")" != "jekyll" || "$(basename -- "$install_parent")" != "docs" || "$INSTALL_DIR" == "$GENERATED_PROJECT" ]]; then
		printf 'Refusing to replace an unsafe documentation path: %q\n' "$INSTALL_DIR" >&2
		exit 1
	fi
	if [[ -n "$GEMFILE_LOCK_SOURCE" && ! -f "$GEMFILE_LOCK_SOURCE" ]]; then
		printf 'Gemfile lock source not found: %s\n' "$GEMFILE_LOCK_SOURCE" >&2
		exit 1
	fi

	rm -rf -- "$install_staging"
	mkdir -p -- "$install_parent"
	cp -a -- "$GENERATED_PROJECT" "$install_staging"
	rm -rf -- "$install_staging/.github"
	if [[ -n "$GEMFILE_LOCK_SOURCE" ]]; then
		cp -- "$GEMFILE_LOCK_SOURCE" "$install_staging/Gemfile.lock"
	fi
	rm -rf -- "$INSTALL_DIR"
	mv -- "$install_staging" "$INSTALL_DIR"
	printf 'Installed generated documentation at %s\n' "$INSTALL_DIR"
fi

if [[ "$venv_activated" == true ]]; then
	deactivate
fi
