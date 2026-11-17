# Repository guidance

## Purpose

Cookie Factory provides repeatable wrapper scripts for generating Cook's Code
projects. The GitHub Pages integration is validated against the sibling
`github-docs-cookiecutter` repository.

## Canonical verification

Use the containerized workflows; do not depend on host Python, Ruby, Bundler,
Cookiecutter, Jekyll, or ShellCheck installations.

- Run `make lint` for the complete offline repository lint suite.
- Run `make pre-commit` to exercise every hook against all tracked files.
- Run `make test` for upstream template tests and representative generation.
- Run `make site-test` when a real networked Jekyll remote-theme build matters.
- Run `make verify` before handing off changes to container or generation logic.
- Run `make docs-generate` to replace `docs/jekyll` from the mounted GitHub Docs
  template, then review and restore intentional project-specific prose.

The services use disposable output directories and contain no production
credentials. It is safe to rerun a failed service after making an in-scope fix.

## Container boundaries

- Never mount the Docker socket, the host home directory, SSH keys, or cloud
  credentials into a project service.
- Keep the `test` service network-disabled.
- Network access in `site-test` is limited to resolving and building the remote
  Jekyll theme.
- Keep the source and template mounts read-only in test services.
- Keep pre-commit hooks local and system-language so they reuse the pinned image.
- Pin Python, Ruby, and Node.js dependencies and update their locks deliberately.

## Script conventions

- Use Bash strict mode and quote variable expansions.
- Keep host-friendly defaults but permit environment overrides for containers
  and CI.
- Validate deletion targets before recursive removal.
- Preserve unrelated working-tree changes.

## Licensing

- Cookie Factory and generated-project defaults use `GPL-3.0-or-later`.
- Keep the canonical GPLv3 text in `LICENSE.md` unchanged.
