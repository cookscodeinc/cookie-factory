"""Validate the Cookie Factory's representative generated site."""

from __future__ import annotations

import sys
from pathlib import Path

import yaml


def main() -> None:
    """Validate routing, ownership, content, and template finalization."""
    project_root = Path(sys.argv[1])
    config_path = project_root / "_config.yml"
    if not config_path.is_file():
        raise SystemExit(f"Generated configuration is missing: {config_path}")

    config = yaml.safe_load(config_path.read_text(encoding="utf-8"))
    expected = {
        "baseurl": "/cookie-factory",
        "license": "GPL-3.0-or-later",
        "remote_theme": "just-the-docs/just-the-docs@v0.11.0",
        "repository": "jcook3701/cookie-factory",
        "site_type": "documentation",
        "theme_family": "just_the_docs",
        "url": "https://jcook3701.github.io",
    }
    actual = {key: config.get(key) for key in expected}
    if actual != expected:
        raise SystemExit(f"Unexpected GitHub Pages routing: {actual!r}")

    required_paths = (
        project_root / "Gemfile",
        project_root / "README.md",
        project_root / "_manual/introduction/getting-started.md",
        project_root / "_manual/setup-guide/requirements.md",
        project_root / "index.md",
    )
    missing = [str(path) for path in required_paths if not path.is_file()]
    if missing:
        raise SystemExit(f"Generated files are missing: {missing!r}")

    remaining_templates = [
        str(path) for path in project_root.rglob("*") if path.name.endswith(".j2")
    ]
    if remaining_templates:
        raise SystemExit(f"Jinja templates were not rendered: {remaining_templates!r}")


if __name__ == "__main__":
    main()
