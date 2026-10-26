#!/bin/bash

PYTHON_VENV="$HOME/Documents/git_repo/nutri-matic/.venv/bin/activate"

echo "$PYTHON_VENV"

PROJECT_NAME="ClubPoker"
SLUG_NAME="ClubPoker"
TEMPLATE="cookiecutter-cookiecutter"
LICENSE="GPL-3.0-or-later"
BRANCH="main"
DESCRIPTION="Cookiecutter utilities for streamlining development and utilization of Cookiecutter templates."

# Ensure the venv exists
if [ -f "$PYTHON_VENV" ]; then
    source "$PYTHON_VENV"
else
    echo "Virtual environment not found at $PYTHON_VENV"
    exit 1
fi

rm -rf $SLUG_NAME/
source $PYTHON_VENV
cookiecutter git@github.com:jcook3701/$TEMPLATE.git \
    --checkout $BRANCH \
    --no-input \
    project_name="$PROJECT_NAME" \
    description="$DESCRIPTION" \
    license="$LICENSE"
deactivate
