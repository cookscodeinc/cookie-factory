---
layout: "default"
title: "Template Catalog"
description: "List, validate, test, and generate every Cookie Factory template."
author: "Jared Cook"
nav_order: 2
parent: "Tutorials"
---

## Use the Cookiecutter catalog

`cookiecutters.yml` is the canonical inventory for Cookie Factory. It declares
the personal GitHub source owner, and each entry declares a stable ID, local
directory, repository, tested ref, enablement state, and upstream test interface.
The source owner remains independent when Cookie Factory moves to an organization.

Set `COOKIECUTTER_ROOT` in `.env` to the absolute parent containing those local
checkouts. Containers mount the parent read-only at `/templates`; generated
projects never write into a template repository.

List and validate the inventory:

```shell
make templates-list
make templates-validate
```

Generate a project with catalog defaults:

```shell
make generate TEMPLATE=python3
```

Generated projects are written beneath `build/generated`. Use the generic
wrapper for Cookiecutter context overrides:

```shell
./cookie-factory.sh generate ansible-galaxy \
  --set namespace=example \
  --set project_name=automation \
  --set license=GPL-3.0-or-later
```

The enabled IDs are:

- `ansible-galaxy`
- `cookiecutter`
- `github-docs`
- `python3`
- `sphinx`

`typescript` is cataloged but disabled because its repository does not contain
a templated project directory. Selecting it fails with the recorded structural
reason instead of silently skipping validation. Repair that template and add an
upstream test interface before changing its catalog entry to enabled.

`make test` runs every enabled repository's own bake suite without network
access. GitHub Actions checks out the same declared refs as sibling repositories
and mounts them through the same `/templates` boundary used locally.
