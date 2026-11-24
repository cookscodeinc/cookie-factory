---
layout: "default"
title: "Release Guide"
description: "Prepare and publish a verified Cookie Factory release."
author: "Jared W. Cook"
nav_order: 6
---

## Release Cookie Factory

Cookie Factory has three independent automation boundaries:

1. Developers use the VS Code Dev Container and local pre-commit hooks.
2. GitHub Actions runs Docker linting, offline tests, and the Jekyll build for
   branch pushes and pull requests.
3. A semantic version tag on an approved `master` commit triggers validation,
   the same container verification, git-cliff notes, and a GitHub Release.

Ordinary pushes never publish a release. The root `VERSION` describes Cookie
Factory itself and is independent of the versions assigned to generated
projects.

### Prepare and inspect the candidate

Update `VERSION` to the approved `MAJOR.MINOR.PATCH` value in a reviewed change,
merge it into `master`, and use a clean `master` checkout:

```shell
make build
make verify
make release-check
make release-notes
make release-dry-run
```

Inspect `build/release-notes.md`. The pinned git-cliff version scopes the notes
from the previous reachable semantic version tag through the exact candidate
commit. The dry run creates neither a tag nor a GitHub Release. `make release`
also performs only this guarded preview and prints the manual tag instructions.

Prereleases such as `v1.0.0-rc.1` require both the
`RELEASE_ALLOW_PRERELEASE=true` repository variable and an intentional local
`ALLOW_PRERELEASE=true` override.

### Publish with an existing tag

After approval, create the annotated tag printed by the dry run and push that
single tag:

```shell
git tag --annotate v0.1.0 --message "Release v0.1.0"
git push origin v0.1.0
```

Monitor the **Publish GitHub Release** workflow. Before publishing, it validates
strict semantic version syntax, confirms `VERSION`, verifies the tagged commit
is reachable from `master`, rejects an existing Release, reruns the container
workflow, and regenerates nonempty notes. Publishing uses the built-in token
and `gh release create --verify-tag`; it cannot silently create a tag.

Verify the finished entry on GitHub's **Releases** page. Cookie Factory does not
produce a distributable binary, so GitHub's automatic source archives are the
only release downloads.

### Recover from a failure

Read the failed job before changing anything. Do not move, force-push, delete,
or overwrite a published tag. Put a required fix in a new reviewed `master`
commit, choose a new semantic version, rerun the dry run, and create a new tag.
This keeps every published version reproducible and auditable.

### Protect the release path

Recommended GitHub rulesets require pull requests and the **Container tests /
verify** check for `master`. A tag ruleset for `v*` should restrict creation to
maintainers and prevent tag updates or deletion. Configure the `github-release`
environment with the desired reviewer approval. The workflow obtains the owner
and repository from GitHub Actions context, so an organization transfer does
not require release-script changes.

GitHub Releases and GitHub Pages serve different purposes. A Release records an
immutable tagged software version. GitHub Pages continuously deploys the Jekyll
documentation and does not create or approve a Cookie Factory version.
