"""Validate the manifest-driven Cookie Factory catalog."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import yaml

PROJECT_ROOT = Path(__file__).resolve().parents[1]
CATALOG_PATH = PROJECT_ROOT / "cookiecutters.yml"
CATALOG_SCRIPT = PROJECT_ROOT / "scripts/cookie_factory.py"


def catalog_templates() -> list[dict[str, object]]:
    """Return the checked-in catalog entries."""
    document = yaml.safe_load(CATALOG_PATH.read_text(encoding="utf-8"))
    assert document["schema_version"] == 1
    return document["templates"]


def test_catalog_covers_every_local_cookiecutter() -> None:
    """Keep the intended repository inventory explicit and reviewable."""
    templates = catalog_templates()
    assert {template["id"] for template in templates} == {
        "ansible-galaxy",
        "cookiecutter",
        "github-docs",
        "python3",
        "sphinx",
        "typescript",
    }
    enabled = {template["id"] for template in templates if template["enabled"]}
    assert enabled == {"ansible-galaxy", "cookiecutter", "github-docs", "python3", "sphinx"}


def test_typescript_is_explicitly_disabled() -> None:
    """Do not silently claim support for the structurally incomplete template."""
    typescript = next(
        template for template in catalog_templates() if template["id"] == "typescript"
    )
    assert typescript["enabled"] is False
    assert typescript["upstream_tests"] is False
    assert "NonTemplatedInputDirException" in typescript["disabled_reason"]

    result = subprocess.run(
        [sys.executable, str(CATALOG_SCRIPT), "generate", "typescript", "--ci"],
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode == 1
    assert "template typescript is disabled" in result.stderr


def test_ci_checkouts_match_enabled_catalog() -> None:
    """Keep GitHub's sibling checkouts aligned with the canonical catalog."""
    workflow_path = PROJECT_ROOT / ".github/workflows/container-tests.yml"
    workflow = yaml.load(workflow_path.read_text(encoding="utf-8"), Loader=yaml.BaseLoader)
    steps = workflow["jobs"]["verify"]["steps"]
    auxiliary = {
        step["with"]["path"].removeprefix("templates/"): step["with"]
        for step in steps
        if step.get("with", {}).get("path", "").startswith("templates/")
    }

    enabled_templates = [template for template in catalog_templates() if template["enabled"]]
    enabled = {template["directory"]: template for template in enabled_templates}
    assert set(auxiliary) == set(enabled)
    for directory, template in enabled.items():
        checkout = auxiliary[directory]
        assert checkout["repository"].endswith(f"/{template['repository']}")
        assert checkout["ref"] == template["ref"]
