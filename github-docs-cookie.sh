#!/bin/bash

# PROJECT="cookscodeinc"
PROJECT="the-cook-family-comedy"

LICENSE="MIT"
BRANCH=main

OUTPUT_DIR="~/Documents/git_repo/"


# Note: Github Docs Cookiecutter Project
# cookiecutter git@github.com:jcook3701/github-docs-cookiecutter.git --checkout develop
rm -rf $PROJECT/
source ~/Documents/git_repo/nutri-matic/.venv/bin/activate
# Note: Ansible Galaxy Cookiecutter Project
cookiecutter git@github.com:jcook3701/github-docs-cookiecutter.git \
	--checkout $BRANCH \
	--no-input \
	--output-dir $OUTPUT_DIR \
	project_name=$PROJECT \
	description="Ansible Galaxy collection used to install docker packages." \
	license=$LICENSE

deactivate
