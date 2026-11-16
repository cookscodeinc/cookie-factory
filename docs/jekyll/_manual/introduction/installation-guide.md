---
layout: "default"
title: "Installation Guide"
description: "Install the project and its dependencies on Linux."
author: "Jared Cook"
nav_order: 2
parent: "Introduction"
---

## Installation guide for Cookie Factory

Clone both repositories under a common parent directory:

```shell
git clone https://github.com/jcook3701/cookie-factory.git
git clone https://github.com/jcook3701/github-docs-cookiecutter.git
cd cookie-factory
```

Create the local Compose configuration:

```shell
cp .env.example .env
```

Edit `.env` so `GITHUB_DOCS_TEMPLATE_DIR` points to the absolute path of the
second checkout. If the host user does not use UID and GID `1000`, update
`LOCAL_UID` and `LOCAL_GID` as well.

Build and verify the environment:

```shell
make build
make verify
```

No host Python virtual environment, Ruby installation, Bundler setup, Jekyll,
Node.js, or ShellCheck installation is required.
