---
layout: "default"
title: "Getting Started"
description: "Take the first steps with the project."
author: "Jared Cook"
nav_order: 1
parent: "Introduction"
---

## Getting started with Cookie Factory

1. Install the [host requirements]({% link _manual/setup-guide/requirements.md %}).
2. Clone Cookie Factory and the enabled repositories in `cookiecutters.yml`
   beneath a common template parent directory.
3. Copy `.env.example` to `.env` and set `COOKIECUTTER_ROOT` to that absolute
   parent path.
4. Build the pinned toolchain and run the complete verification suite.

```shell
cp .env.example .env
make build
make templates-validate
make verify
```

For an interactive environment, open the repository in VS Code and choose
**Dev Containers: Reopen in Container**. The container uses the same image as
the Compose test services and GitHub Actions.

To generate the Cookie Factory documentation from the mounted template:

```shell
make docs-generate
make site-test
```

Review the generated diff before committing it. This keeps upstream template
changes visible and makes project-specific documentation edits easy to retain.
