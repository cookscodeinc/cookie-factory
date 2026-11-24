---
layout: "default"
title: "Contribute"
description: "Find the contribution workflow and project standards."
author: "Jared W. Cook"
nav_order: 4
has_children: true
---

## Contribute to Cookie Factory

Cookie Factory contributions should preserve the container boundaries and keep
the host dependency-free workflow working.

- Read the [developer guide]({% link _manual/contribute/developer-guide.md %}).
- Read the repository's [contribution guide](https://github.com/cookscodeinc/cookie-factory/blob/master/.github/CONTRIBUTING.md)
  and [Contributor License Agreement](https://github.com/cookscodeinc/cookie-factory/blob/master/.github/CLA.md).
- Keep shell scripts strict, quoted, and safe around recursive deletion.
- Keep the `test` service network-disabled and source mounts read-only.
- Pin dependency versions and update lockfiles deliberately.
- Run `make verify` before requesting review.
- Open pull requests against `develop`.

Use focused conventional commits and keep unrelated working-tree changes out of
the contribution.
