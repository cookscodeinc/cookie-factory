#!/bin/bash

# PROJECT=flatpak
# PROJECT=cookiecutter-cookiecutter
# PROJECT=ansible-galaxy-cookiecutter
# PROJECT=python3-cookiecutter
# PROJECT=ansible-config-cookiecutter
PROJECT=typescript-cookiecutter

LICENSE="AGPL-3.0-or-later"

BRANCH=main

# Note: Github Docs Cookiecutter Project
# cookiecutter git@github.com:jcook3701/github-docs-cookiecutter.git --checkout develop
rm -rf $PROJECT/
source ~/Documents/git_repo/nutri-matic/.venv/bin/activate
# Note: Ansible Galaxy Cookiecutter Project
cookiecutter git@github.com:jcook3701/cookiecutter-cookiecutter.git \
	--checkout $BRANCH \
	--no-input \
	project_name=$PROJECT \
	description="**Typescript** cookiecutter project." \
	license=$LICENSE

deactivate
