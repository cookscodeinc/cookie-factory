---
layout: "default"
title: "Upgrade Guide"
description: "Upgrade the project safely between releases."
author: "Jared Cook"
nav_order: 6
---

## Cookie Factory upgrade guide

### Update the GitHub Docs template

1. Check out the desired branch or tag in the sibling
   `github-doc-cookiecutter` repository.
2. Confirm `.env` points to that checkout.
3. Regenerate and validate the documentation.

```shell
make docs-generate
make verify
```

1. Review the complete diff. Regeneration replaces `docs/jekyll`, so restore
   intentional project-specific prose while retaining compatible scaffold,
   dependency, and theme changes.
2. Commit the template revision and generated-site update together.

### Update toolchain dependencies

Update source constraints and their locks deliberately. Rebuild the image from
scratch, run `make verify`, and keep automated dependency updates separated by
ecosystem when practical.
