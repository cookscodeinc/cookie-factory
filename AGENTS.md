# Repository guidance

## Purpose

Cookie Factory provides repeatable wrapper scripts for generating Cook's Code
projects. The GitHub Pages integration is validated against the sibling
`github-doc-cookiecutter` repository.

## Canonical verification

Use the containerized workflows; do not depend on host Python, Ruby, Bundler,
Cookiecutter, Jekyll, or ShellCheck installations.

- Run `make test` for offline linting, upstream template tests, and generation.
- Run `make site-test` when a real networked Jekyll remote-theme build matters.
- Run `make verify` before handing off changes to container or generation logic.

The services use disposable output directories and contain no production
credentials. It is safe to rerun a failed service after making an in-scope fix.

## Container boundaries

- Never mount the Docker socket, the host home directory, SSH keys, or cloud
  credentials into a project service.
- Keep the `test` service network-disabled.
- Network access in `site-test` is limited to resolving and building the remote
  Jekyll theme.
- Keep the source and template mounts read-only in test services.
- Pin Python and Ruby dependencies and update their locks deliberately.

## Script conventions

- Use Bash strict mode and quote variable expansions.
- Keep host-friendly defaults but permit environment overrides for containers
  and CI.
- Validate deletion targets before recursive removal.
- Preserve unrelated working-tree changes.
