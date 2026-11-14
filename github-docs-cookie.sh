#!/bin/bash

# PROJECT="cookscodeinc"
PROJECT="the-cook-family-comedy"
# OUTPUT_DIR="$HOME/Documents/git_repo/"
OUTPUT_DIR="./"
LICENSE="AGPL-3.0-or-later"
BRANCH=master

DESCRIPTION="Welcome to the family history repository. This project serves as a centralized collection of genealogical data, trees, and historical documentation."
# DESCRIPTION="Cook's Code, Inc. develops resilient, open-source technology stack components designed for modern infrastructure. We build high-integrity engineering tools, automation software, and decentralized systems with a firm commitment to software freedom, transparency, and self-hosted architectural stability."
PUB_YEAR="2026"
THEME="mmistakes/minimal-mistakes"

# Note: Github Docs Cookiecutter Project
# cookiecutter git@github.com:jcook3701/github-docs-cookiecutter.git --checkout develop
rm -rf $PROJECT/
source "$HOME/Documents/git_repo/nutri-matic/.venv/bin/activate"
# Note: Github Docs Cookiecutter Project
cookiecutter git@github.com:jcook3701/github-docs-cookiecutter.git \
	--checkout $BRANCH \
	--no-input \
	--output-dir $OUTPUT_DIR \
	project_name=$PROJECT \
	description="$DESCRIPTION" \
	license=$LICENSE \
    publication_year=$PUB_YEAR \
    theme=$THEME

deactivate
