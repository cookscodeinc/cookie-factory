#!/usr/bin/env bash

set -euo pipefail

PYTHON_VENV="$HOME/Documents/git_repo/nutri-matic/.venv/bin/activate"

printf '%s\n' "$PYTHON_VENV"

PROJECT_NAME="ClubPoker"
SLUG_NAME="ClubPoker"
TEMPLATE="cookiecutter-cookiecutter"
LICENSE="GPL-3.0-or-later"
BRANCH="main"
DESCRIPTION="Cookiecutter utilities for streamlining development and utilization of Cookiecutter templates."

# Ensure the venv exists
if [[ -f "$PYTHON_VENV" ]]; then
	# shellcheck disable=SC1090
	source "$PYTHON_VENV"
else
	printf 'Virtual environment not found at %s\n' "$PYTHON_VENV" >&2
	exit 1
fi

if [[ -z "$SLUG_NAME" || "$SLUG_NAME" == "." || "$SLUG_NAME" == ".." || "$SLUG_NAME" == */* ]]; then
	printf 'Refusing to remove an unsafe project path: %q\n' "$SLUG_NAME" >&2
	exit 1
fi

rm -rf -- "$SLUG_NAME"
cookiecutter "git@github.com:jcook3701/${TEMPLATE}.git" \
	--checkout "$BRANCH" \
	--no-input \
	project_name="$PROJECT_NAME" \
	description="$DESCRIPTION" \
	license="$LICENSE"
deactivate
