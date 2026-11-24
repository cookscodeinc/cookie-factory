---
layout: "default"
title: "Developer Guide"
description: "Set up a contributor development workflow."
author: "Jared W. Cook"
nav_order: 1
parent: "Contribute"
---

## Developer guide

Cookie Factory uses the same Compose services locally and in CI. Start by
building the pinned image:

```shell
make build
```

## Focused checks

- `make format` applies supported automatic formatting.
- `make lint` runs ShellCheck, Ruff, YAML, Actions, Dockerfile, Markdown,
  spelling, JSON, dependency, and formatting checks offline.
- `make pre-commit` runs the repository policy against all files offline.
- `make test` runs the upstream Cookiecutter tests and integration generation
  without network access.
- `make site-test` performs the networked remote-theme builds.

Run the full contract before handoff:

```shell
make verify
```

The VS Code Dev Container uses the `dev` service and includes the recommended
Python, Ruff, YAML, Markdown, spelling, ShellCheck, and ChatGPT extensions.
