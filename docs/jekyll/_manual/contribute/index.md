---
layout: "default"
title: "Contribute"
description: "Find the contribution workflow and project standards."
author: "Jared Cook"
nav_order: 4
has_children: true
---

## Contribute to Cookie Factory

Cookie Factory contributions should preserve the container boundaries and keep
the host dependency-free workflow working.

- Read the [developer guide]({% link _manual/contribute/developer-guide.md %}).
- Keep shell scripts strict, quoted, and safe around recursive deletion.
- Keep the `test` service network-disabled and source mounts read-only.
- Pin dependency versions and update lockfiles deliberately.
- Run `make verify` before requesting review.

Use focused conventional commits and keep unrelated working-tree changes out of
the contribution.
