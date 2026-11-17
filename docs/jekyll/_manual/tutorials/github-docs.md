---
layout: "default"
title: "GitHub Docs Generation"
description: "Generate and update the Just the Docs site from its Cookiecutter."
author: "Jared Cook"
nav_order: 3
parent: "Tutorials"
---

## Generate GitHub documentation

Set `COOKIECUTTER_ROOT` in `.env` to the absolute parent of the cataloged
template checkouts. Cookie Factory mounts that parent read-only at `/templates`;
the GitHub Docs entry resolves to `/templates/github-doc-cookiecutter`.

Generate the documentation site with:

```shell
make docs-generate
```

The target calls `github-docs-cookie.sh` inside the `dev` service with these
Cookie Factory defaults:

- Project: `Cookie Factory`
- Site type: `documentation`
- Pages type: `project`
- Theme: `just-the-docs/just-the-docs@v0.11.0`
- License: `GPL-3.0-or-later`
- Destination: `docs/jekyll`

The installer validates the destination, stages the complete generated site,
adds the pinned Bundler lockfile, and replaces `docs/jekyll`. The repository
workflow stays at `.github/workflows/pages.yml`, where GitHub Actions can find
it.

Run `make site-test` after generation. It creates a second site in a disposable
directory directly from the template and builds both that result and the
checked-in documentation. A successful run proves the upstream template and
the committed project customization remain compatible.

Generation replaces `docs/jekyll`, so review the Git diff and restore any
intentional project-specific prose before committing an upstream update.
