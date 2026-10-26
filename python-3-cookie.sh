#!/bin/bash

# Note: Github Docs Cookiecutter Project
# cookiecutter git@github.com:jcook3701/github-docs-cookiecutter.git --checkout develop


# Note: Python3 Cookiecutter Project
cookiecutter git@github.com:jcook3701/python3-cookiecutter.git \
	--checkout develop \
	--no-input \
	project_name="testing" \
	description="Cookiecutter utilities for jcook3701's cookiecuter templates."


# cd python3_cookiecutter/docs/jekyll/
# bundle install
# bundle exec jekyll serve

# Safely export all simple JSON keys as variables
# eval $(jq -r 'to_entries | map("\(.key)=\"\(.value|tostring)\"") | .[]' test.json)
# echo "$project_name"

# 	   $(jq -r 'to_entries|map("\(.key)=\(.value|tostring)")|.[]' test.json)

#	  "$(cat test.json)"
