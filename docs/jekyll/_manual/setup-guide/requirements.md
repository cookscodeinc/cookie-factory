---
layout: "default"
title: "Requirements"
description: "Install the tools required to use and develop the project."
author: "Jared Cook"
nav_order: 1
parent: "Setup Guide"
---

## Cookie Factory requirements

- Git
- Docker Engine with the Compose v2 plugin
- A local checkout of Cookie Factory
- A local checkout of `github-doc-cookiecutter` on the branch being validated
- Enough disk space for the pinned multi-language toolchain image

VS Code plus the Dev Containers extension is recommended for interactive work,
but it is not required for `make lint`, `make test`, or `make verify`.

The image already contains the pinned Python, Ruby, Node.js, Cookiecutter,
Nutri-Matic, Jekyll, ShellCheck, lint, and pre-commit dependencies. Installing
those tools directly on the host creates an untested execution path and is not
part of the supported workflow.
