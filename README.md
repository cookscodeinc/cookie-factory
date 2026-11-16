# Cookie Factory

Cookie Factory provides repeatable project-generation wrappers for Cook's Code,
Inc. Development and verification run in containers so the host does not need a
project-specific Python virtual environment, Ruby installation, Jekyll, or
ShellCheck.

## Development environment

The supported interactive environment is the VS Code Dev Containers extension.
It uses the `dev` service in `compose.yaml` and installs the Python, ShellCheck,
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

Run deterministic verification without runtime network access:

```shell
make test
```

This runs ShellCheck, the complete upstream `feat-024` pytest suite, a real
Cookie Factory generation, and assertions over the generated GitHub Pages
routing and content.

Run a real Jekyll remote-theme build when network verification is required:

```shell
make site-test
```

Run both stages:

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

The current representative build generates a company website using Minimal
Mistakes and GitHub Project Pages routing.

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
