SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

.PHONY: build config dev down format help lint pre-commit site-test test verify

config: ## Validate the resolved Compose model.
	docker compose config --quiet

build: config ## Build the pinned development and test toolchain.
	docker compose build

dev: config ## Start the VS Code development service.
	docker compose up --detach dev

down: ## Stop the development stack without deleting its home volume.
	docker compose down

format: config ## Apply supported automatic formatting in the dev service.
	docker compose run --rm dev bash -lc 'ruff check --fix tests && ruff format tests && npm run format'

lint: config ## Run every repository linter without runtime network access.
	docker compose run --rm lint

pre-commit: config ## Run every pre-commit hook against the repository offline.
	docker compose run --rm hooks

test: config ## Run upstream tests and representative generation checks offline.
	docker compose run --rm test

site-test: config ## Run generation checks plus a networked Jekyll build.
	docker compose run --rm site-test

verify: pre-commit lint test site-test ## Run every containerized verification stage.

help: ## Show available targets.
	@awk 'BEGIN {FS = ":.*## "; printf "Usage: make <target>\n\nTargets:\n"} /^[a-zA-Z_-]+:.*## / {printf "  %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
