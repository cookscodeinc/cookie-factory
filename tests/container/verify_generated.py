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
        "baseurl": "/cookscodeinc",
        "repository": "cookscodeinc/cookscodeinc",
        "url": "https://cookscodeinc.github.io",
    }
    actual = {key: config.get(key) for key in expected}
    if actual != expected:
        raise SystemExit(f"Unexpected GitHub Pages routing: {actual!r}")

    required_paths = (
        project_root / "Gemfile",
        project_root / "README.md",
        project_root / "_data/navigation.yml",
        project_root / "about.md",
        project_root / "index.md",
    )
    missing = [str(path) for path in required_paths if not path.is_file()]
    if missing:
        raise SystemExit(f"Generated files are missing: {missing!r}")

    remaining_templates = [
        str(path) for path in project_root.rglob("*") if path.name.endswith(".j2")
    ]
    if remaining_templates:
        raise SystemExit(f"Unfinalized Jinja templates remain: {remaining_templates!r}")


if __name__ == "__main__":
    main()
