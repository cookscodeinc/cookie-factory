---
layout: "default"
title: "Installation Guide"
description: "Install the project and its dependencies on Linux."
author: "Jared Cook"
nav_order: 2
parent: "Introduction"
---

## Installation guide for Cookie Factory

Clone Cookie Factory and the enabled template repositories under a common
parent directory. The catalog supplies the tested branches:

```shell
git clone https://github.com/cookscodeinc/cookie-factory.git
cd cookie-factory
```

Create the local Compose configuration:

```shell
cp .env.example .env
```

Edit `.env` so `COOKIECUTTER_ROOT` points to the absolute parent containing the
directories listed by `make templates-list`. If the host user does not use UID
and GID `1000`, update `LOCAL_UID` and `LOCAL_GID` as well.

Build and verify the environment:

```shell
make build
make templates-list
make templates-validate
make verify
```

No host Python virtual environment, Ruby installation, Bundler setup, Jekyll,
Node.js, or ShellCheck installation is required.
