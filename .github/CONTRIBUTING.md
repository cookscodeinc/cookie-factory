# Contributing to Cookie Factory

Contributions are welcome. By participating, you agree to follow the
[Cook's Code, Inc. Code of Conduct](https://github.com/cookscodeinc/.github/blob/main/CODE_OF_CONDUCT.md).

## Before you begin

- Report vulnerabilities privately according to the [security policy](SECURITY.md).
- Open an issue before starting a large change or changing a public interface.
- Do not include credentials, personal data, generated build output, or changes
  to sibling template repositories.
- Read and accept the [Contributor License Agreement](CLA.md). The CLA workflow
  will provide signing instructions on your first pull request.

## Development workflow

1. Fork the repository and branch from `develop`.
2. Make a focused change with tests and documentation where appropriate.
3. Keep dependencies pinned and update lockfiles deliberately.
4. Run the repository's containerized checks:

   ```shell
   make verify
   make pre-commit
   ```

5. Use a focused conventional commit and open a pull request against `develop`.

The host does not need project-specific Python, Ruby, Node.js, or linting tools.
Docker Compose provides the canonical toolchain used by GitHub Actions.

## Project constraints

- Keep the test service network-disabled and source/template mounts read-only.
- Never mount the Docker socket, home directory, SSH keys, or cloud credentials
  into project services.
- Treat `cookiecutters.yml` as the only template catalog.
- Preserve Bash strict mode, quote expansions, and validate recursive deletion
  targets.
- License new project contributions under `GPL-3.0-or-later`. Identify and
  preserve the licenses of any permitted third-party material.

Maintainers promote reviewed changes from `develop` to `master`.
