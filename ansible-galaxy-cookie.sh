#!/bin/bash

NAMESPACE=jcook3701
# PROJECT=flatpak
# PROJECT=snap
# PROJECT=source
# PROJECT=pkgs
# PROJECT=utils
# PROJECT=docker
# PROJECT=homelab
# PROJECT=lab
# PROJECT=
LICENSE="GPL-3.0-or-later"

BRANCH=main

# Note: Github Docs Cookiecutter Project
# cookiecutter git@github.com:jcook3701/github-docs-cookiecutter.git --checkout develop
rm -rf "$NAMESPACE.$PROJECT/"
# shellcheck disable=SC1091
source "$HOME/Documents/git_repo/nutri-matic/.venv/bin/activate"
# Note: Ansible Galaxy Cookiecutter Project
cookiecutter git@github.com:jcook3701/ansible-galaxy-cookiecutter.git \
	--checkout "$BRANCH" \
	--no-input \
	--output-dir "$HOME/Documents/git_repo/" \
	project_name="$PROJECT" \
	description="Ansible Galaxy collection used to install docker packages." \
	license="$LICENSE"

deactivate


# cd python3_cookiecutter/docs/jekyll/
# bundle install
# bundle exec jekyll serve

# Safely export all simple JSON keys as variables
# eval $(jq -r 'to_entries | map("\(.key)=\"\(.value|tostring)\"") | .[]' test.json)
# echo "$project_name"

# 	   $(jq -r 'to_entries|map("\(.key)=\(.value|tostring)")|.[]' test.json)

#	  "$(cat test.json)"
