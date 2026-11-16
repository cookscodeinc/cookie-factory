SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

.PHONY: build config dev down help site-test test verify

config: ## Validate the resolved Compose model.
	docker compose config --quiet

build: config ## Build the pinned development and test toolchain.
	docker compose build

dev: config ## Start the VS Code development service.
	docker compose up --detach dev

down: ## Stop the development stack without deleting its home volume.
	docker compose down

test: config ## Run offline lint, upstream tests, and generation checks.
	docker compose run --rm test

site-test: config ## Run the full verification plus a networked Jekyll build.
	docker compose run --rm site-test

verify: test site-test ## Run every containerized verification stage.

help: ## Show available targets.
	@awk 'BEGIN {FS = ":.*## "; printf "Usage: make <target>\n\nTargets:\n"} /^[a-zA-Z_-]+:.*## / {printf "  %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
