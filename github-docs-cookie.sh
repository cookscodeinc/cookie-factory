#!/usr/bin/env bash

set -euo pipefail

OUTPUT_DIR="${OUTPUT_DIR:-./build}"
# OUTPUT_DIR="$HOME/Documents/git_repo/"

PYTHON_ENV="${PYTHON_ENV:-$HOME/Documents/git_repo/nutri-matic}"
PYTHON_ACTIVATE="${PYTHON_ACTIVATE-$PYTHON_ENV/.venv/bin/activate}"

PROJECT="${PROJECT:-cookscodeinc}"
# PROJECT="the-cook-family-comedy"

COOKIE_REPO="${COOKIE_REPO:-git@github.com:jcook3701/github-docs-cookiecutter.git}"
BRANCH="${BRANCH-feat-024}"

SITE_TYPE="${SITE_TYPE:-company}"
PAGES_SITE_TYPE="${PAGES_SITE_TYPE:-project}"
CUSTOM_DOMAIN="${CUSTOM_DOMAIN:-}"
COMPANY="${COMPANY:-}"
FORMSPREE_FORM_PATH="${FORMSPREE_FORM_PATH:-}"
# DESCRIPTION="Welcome to the family history repository. This project serves as a centralized collection of genealogical data, trees, and historical documentation."
DESCRIPTION="${DESCRIPTION:-}"
GITHUB_ORG="${GITHUB_ORG:-cookscodeinc}"
LICENSE="${LICENSE:-AGPL-3.0-or-later}"
PUB_YEAR="${PUB_YEAR:-2026}"
THEME="${THEME:-mmistakes/minimal-mistakes}"

if [[ -z "$COMPANY" ]]; then
	COMPANY="Cook's Code, Inc."
fi
if [[ -z "$DESCRIPTION" ]]; then
	DESCRIPTION="Cook's Code, Inc. develops resilient, open-source technology stack components designed for modern infrastructure. We build high-integrity engineering tools, automation software, and decentralized systems with a firm commitment to software freedom, transparency, and self-hosted architectural stability."
fi

GENERATED_PROJECT="$OUTPUT_DIR/$PROJECT"

if [[ -z "$PROJECT" || "$PROJECT" == "." || "$PROJECT" == ".." || "$PROJECT" == */* || -z "$OUTPUT_DIR" || "$OUTPUT_DIR" == "/" ]]; then
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
)

# Note: Github Docs Cookiecutter Project
cookiecutter "${cookiecutter_args[@]}"

if [[ "$venv_activated" == true ]]; then
	deactivate
fi
