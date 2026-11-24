#!/usr/bin/env python3
"""List, validate, generate, and test Cookie Factory templates."""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path
from typing import Any

import yaml
from cookiecutter.main import cookiecutter

PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CATALOG = PROJECT_ROOT / "cookiecutters.yml"


class CatalogError(RuntimeError):
    """Report an invalid template catalog or selection."""


def validate_repository_owner(document: dict[str, Any]) -> None:
    """Require one safe GitHub owner for every cataloged template source."""
    repository_owner = document.get("repository_owner")
    if not isinstance(repository_owner, str) or Path(repository_owner).name != repository_owner:
        raise CatalogError("cookiecutters.yml must declare one safe repository_owner")


def template_root() -> Path:
    """Return the configured parent directory containing template checkouts."""
    configured = os.environ.get("COOKIECUTTER_ROOT")
    if configured:
        return Path(configured).expanduser().resolve()
    return (Path.home() / "Documents/git_repo").resolve()


def load_catalog(path: Path = DEFAULT_CATALOG) -> list[dict[str, Any]]:
    """Load and structurally validate the template catalog."""
    try:
        document = yaml.safe_load(path.read_text(encoding="utf-8"))
    except (OSError, yaml.YAMLError) as error:
        raise CatalogError(f"Unable to read template catalog {path}: {error}") from error

    if not isinstance(document, dict) or document.get("schema_version") != 1:
        raise CatalogError("cookiecutters.yml must use schema_version: 1")
    validate_repository_owner(document)
    templates = document.get("templates")
    if not isinstance(templates, list) or not templates:
        raise CatalogError("cookiecutters.yml must contain a nonempty templates list")

    required = {"directory", "enabled", "id", "name", "ref", "repository", "upstream_tests"}
    identifiers: set[str] = set()
    directories: set[str] = set()
    for index, template in enumerate(templates, start=1):
        if not isinstance(template, dict):
            raise CatalogError(f"template entry {index} must be a mapping")
        missing = sorted(required - template.keys())
        if missing:
            raise CatalogError(f"template entry {index} is missing: {', '.join(missing)}")

        identifier = template["id"]
        directory = template["directory"]
        if not isinstance(identifier, str) or not identifier:
            raise CatalogError(f"template entry {index} has an invalid id")
        if identifier in identifiers:
            raise CatalogError(f"duplicate template id: {identifier}")
        identifiers.add(identifier)

        if not isinstance(directory, str) or Path(directory).name != directory:
            raise CatalogError(f"template {identifier} has an unsafe directory: {directory!r}")
        if directory in directories:
            raise CatalogError(f"duplicate template directory: {directory}")
        directories.add(directory)

        if not isinstance(template["enabled"], bool) or not isinstance(
            template["upstream_tests"], bool
        ):
            raise CatalogError(f"template {identifier} enable/test flags must be booleans")
        if not template["enabled"] and not template.get("disabled_reason"):
            raise CatalogError(f"disabled template {identifier} requires disabled_reason")
    return templates


def select_template(templates: list[dict[str, Any]], identifier: str) -> dict[str, Any]:
    """Return one catalog entry by stable identifier."""
    for template in templates:
        if template["id"] == identifier:
            return template
    choices = ", ".join(template["id"] for template in templates)
    raise CatalogError(f"unknown template {identifier!r}; choose one of: {choices}")


def resolve_template_path(template: dict[str, Any], root: Path | None = None) -> Path:
    """Resolve one template beneath the configured root without path traversal."""
    resolved_root = root or template_root()
    path = (resolved_root / template["directory"]).resolve()
    if path.parent != resolved_root:
        raise CatalogError(f"template path escapes {resolved_root}: {path}")
    return path


def validate_paths(templates: list[dict[str, Any]], root: Path) -> None:
    """Require every enabled local checkout and its test interface."""
    if not root.is_dir():
        raise CatalogError(f"template root does not exist: {root}")

    for template in templates:
        path = resolve_template_path(template, root)
        if not template["enabled"]:
            continue
        if not (path / "cookiecutter.json").is_file():
            raise CatalogError(f"{template['id']} is missing {path / 'cookiecutter.json'}")
        if template["upstream_tests"] and not (path / "tests").is_dir():
            raise CatalogError(f"{template['id']} is missing its upstream tests directory")


def parse_context(values: list[str]) -> dict[str, Any]:
    """Parse repeatable KEY=VALUE context overrides using YAML scalar types."""
    context: dict[str, Any] = {}
    for value in values:
        key, separator, raw_value = value.partition("=")
        if not separator or not key:
            raise CatalogError(f"context override must use KEY=VALUE syntax: {value!r}")
        context[key] = yaml.safe_load(raw_value)
    return context


def list_templates(templates: list[dict[str, Any]]) -> None:
    """Print the complete catalog, including intentionally disabled entries."""
    print(f"{'ID':<18} {'STATUS':<10} {'REF':<12} DIRECTORY")
    for template in templates:
        status = "enabled" if template["enabled"] else "disabled"
        print(f"{template['id']:<18} {status:<10} {template['ref']:<12} {template['directory']}")
        if not template["enabled"]:
            print(f"  reason: {template['disabled_reason']}")


def generate_project(args: argparse.Namespace, templates: list[dict[str, Any]]) -> None:
    """Generate one project from a selected enabled local template."""
    template = select_template(templates, args.template)
    if not template["enabled"]:
        raise CatalogError(f"template {args.template} is disabled: {template['disabled_reason']}")

    path = resolve_template_path(template)
    validate_paths([template], template_root())
    output_dir = Path(args.output_dir).expanduser().resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    if args.ci:
        os.environ["CI"] = "1"

    project_path = cookiecutter(
        str(path),
        no_input=True,
        output_dir=str(output_dir),
        extra_context=parse_context(args.context),
        overwrite_if_exists=args.overwrite,
    )
    print(f"Generated {args.template}: {project_path}")


def run_upstream_tests(templates: list[dict[str, Any]], root: Path) -> None:
    """Run each enabled template's own bake suite in the current container."""
    validate_paths(templates, root)
    tested = 0
    for template in templates:
        if not template["enabled"]:
            print(f"==> Skipping disabled template: {template['id']}")
            continue
        if not template["upstream_tests"]:
            raise CatalogError(f"enabled template {template['id']} has no verification interface")

        path = resolve_template_path(template, root)
        print(f"==> Upstream template tests: {template['id']}", flush=True)
        subprocess.run(
            [
                sys.executable,
                "-m",
                "pytest",
                "--quiet",
                "-p",
                "no:cacheprovider",
                "--template",
                str(path),
                str(path / "tests"),
            ],
            check=True,
            env={**os.environ, "CI": "1"},
        )
        tested += 1
    print(f"Validated {tested} enabled Cookiecutter templates.")


def build_parser() -> argparse.ArgumentParser:
    """Create the command-line interface."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--catalog", type=Path, default=DEFAULT_CATALOG)
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("list", help="List enabled and disabled templates.")

    validate_parser = subparsers.add_parser("validate", help="Validate catalog structure.")
    validate_parser.add_argument("--require-paths", action="store_true")

    path_parser = subparsers.add_parser("path", help="Print one local template path.")
    path_parser.add_argument("template")

    generate_parser = subparsers.add_parser("generate", help="Generate from one template.")
    generate_parser.add_argument("template")
    generate_parser.add_argument("--output-dir", default=str(PROJECT_ROOT / "build/generated"))
    generate_parser.add_argument("--set", dest="context", action="append", default=[])
    generate_parser.add_argument("--overwrite", action="store_true")
    generate_parser.add_argument("--ci", action="store_true", help="Skip post-generation setup.")

    subparsers.add_parser("test-all", help="Run every enabled upstream bake suite.")
    return parser


def main() -> None:
    """Run the selected catalog operation with concise errors."""
    parser = build_parser()
    args = parser.parse_args()
    try:
        templates = load_catalog(args.catalog)
        if args.command == "list":
            list_templates(templates)
        elif args.command == "validate":
            if args.require_paths:
                validate_paths(templates, template_root())
            print(f"Template catalog is valid: {len(templates)} entries")
        elif args.command == "path":
            template = select_template(templates, args.template)
            print(resolve_template_path(template))
        elif args.command == "generate":
            generate_project(args, templates)
        elif args.command == "test-all":
            run_upstream_tests(templates, template_root())
    except (CatalogError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Cookie Factory error: {error}\n")


if __name__ == "__main__":
    main()
