---
layout: "default"
title: "FAQ"
description: "Answers to frequently asked project questions."
author: "Jared Cook"
nav_order: 1
parent: "Troubleshooting"
---

## Cookie Factory frequently asked questions

### Compose says the template directory is not set

Copy `.env.example` to `.env` and set `GITHUB_DOCS_TEMPLATE_DIR` to an absolute
host path containing `cookiecutter.json`.

### Generated files have the wrong owner

Set `LOCAL_UID` and `LOCAL_GID` in `.env` to the host user's numeric IDs, then
rebuild the image with `make build`.

### Why does `make test` have no network?

The test service proves the pinned image and mounted template are sufficient.
Only `make site-test` receives network access because Jekyll must resolve the
remote theme.

### Why does the remote-theme build print Sass warnings?

Some upstream themes still use syntax deprecated by newer Dart Sass releases.
Warnings are acceptable while the build succeeds; failures should be
investigated as compatibility regressions.

### How do I reset the development service?

```shell
make down
make dev
```

The named development-home volume is preserved. Project test outputs remain
disposable.
