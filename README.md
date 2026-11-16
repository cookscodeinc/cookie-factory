# Cookie Factory

Cookie Factory provides repeatable project-generation wrappers for Cook's Code,
Inc. Development and verification run in containers so the host does not need a
project-specific Python virtual environment, Ruby installation, Jekyll, Node.js,
or linting tools.

## Development environment

The supported interactive environment is the VS Code Dev Containers extension.
It uses the `dev` service in `compose.yml` and installs the Python, ShellCheck,
YAML, and Codex extensions inside that environment.

1. Copy `.env.example` to `.env`.
2. Set `GITHUB_DOCS_TEMPLATE_DIR` to an absolute path containing a clean checkout
   of `github-doc-cookiecutter`.
3. In VS Code, run **Dev Containers: Reopen in Container**.

The development container mounts Cookie Factory read/write and the GitHub Docs
template read-only. It does not mount the Docker socket, host home directory,
SSH keys, or cloud credentials.

## Verification

Build the toolchain once:

```shell
make build
```

Run the complete lint suite without runtime network access:

```shell
make lint
```

This checks Bash, Python, YAML, GitHub Actions, Dockerfiles, Markdown, spelling,
JSON, and repository formatting. Apply the supported automatic formatting with
`make format`; semantic lint findings still require a deliberate fix.

Run the pre-commit policy against every tracked file:

```shell
make pre-commit
```

The hooks reuse the pinned tools in the development image, run without network
access, and apply safe staged-file fixes for whitespace, line endings, Ruff, and
Prettier. Standard checks also cover syntax, merge markers, large files,
symlinks, executable permissions, debug statements, and private keys.

To enable automatic Git hooks, run this once from a terminal inside the VS Code
Dev Container:

```shell
pre-commit install --install-hooks
```

That installs both `pre-commit` and `pre-push` because the hook types are
declared in `.pre-commit-config.yaml` (the filename required by pre-commit). Run
commits from the same container; for
host-side commits, install pre-commit on the host or use `make pre-commit`.

Run deterministic tests without runtime network access:

```shell
make test
```

This runs the complete upstream `feat-024` pytest suite, a real Cookie Factory
generation, and assertions over the generated GitHub Pages routing and content.

Run a real Jekyll remote-theme build when network verification is required:

```shell
make site-test
```

Run pre-commit, linting, and both test stages:

```shell
make verify
```

GitHub Actions uses the same image and Compose services, so local and CI
verification share one contract.

## GitHub Docs generation

The host-friendly defaults still work when the Nutri-Matic virtual environment
is present:

```shell
./github-docs-cookie.sh
```

Container and CI callers override paths without modifying the script:

```shell
CI=1 \
COOKIE_REPO=/template \
BRANCH= \
PYTHON_ACTIVATE= \
OUTPUT_DIR=/output \
./github-docs-cookie.sh
```

The representative build generates Cookie Factory documentation using the
pinned Just the Docs theme and GitHub Project Pages routing. Regenerate the
checked-in site from the mounted `github-doc-cookiecutter` checkout with:

```shell
make docs-generate
```

The generated source is installed at `docs/jekyll`. Review the resulting diff
before committing an upstream template update. The published site is available
at [jcook3701.github.io/cookie-factory](https://jcook3701.github.io/cookie-factory).

## Other generators

- `cookie-cookie.sh`: Cookiecutter template projects
- `ansible-galaxy-cookie.sh`: Ansible Galaxy projects
- `python-3-cookie.sh`: Python projects
- `template-generator.sh`: legacy configurable template wrapper

## Kubernetes

Kubernetes is intentionally not part of the default workflow. This repository
does not deploy a Kubernetes workload, so Compose is the smaller and more
reproducible execution boundary. If a generated project later ships Kubernetes
manifests, add an optional `kind` end-to-end stage without replacing the fast
Compose test path.

## Maintainer

Maintained by Jared Cook as part of the Cook's Code cookiecutter ecosystem.

## License

Cookie Factory is free software licensed under the GNU General Public License,
version 3 or later (`GPL-3.0-or-later`). See [LICENSE.md](LICENSE.md) for the
complete license terms.
