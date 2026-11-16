# shellcheck shell=sh
# Keep the project toolchains available in interactive and login shells.
export BUNDLE_GEMFILE="${BUNDLE_GEMFILE:-/opt/jekyll/Gemfile}"
export BUNDLE_PATH="${BUNDLE_PATH:-/opt/gems}"
export GEM_HOME="${GEM_HOME:-/opt/gems}"
export PATH="/opt/lint/node_modules/.bin:/opt/venv/bin:/opt/gems/bin:${PATH}"
