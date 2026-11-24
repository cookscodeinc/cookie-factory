"""Protect the repository policies required for public contributions."""

from __future__ import annotations

import re
from pathlib import Path

import yaml

PROJECT_ROOT = Path(__file__).resolve().parents[1]


def test_cla_workflow_is_pinned_and_uses_dedicated_storage() -> None:
    """Keep the privileged CLA workflow immutable and off protected branches."""
    workflow_path = PROJECT_ROOT / ".github/workflows/cla.yml"
    workflow_text = workflow_path.read_text(encoding="utf-8")
    workflow = yaml.load(workflow_text, Loader=yaml.BaseLoader)
    job = workflow["jobs"]["CLAAssistant"]
    action = job["steps"][0]

    assert set(workflow["on"]) == {"issue_comment", "pull_request_target"}
    assert re.fullmatch(
        r"contributor-license/cla-action@[0-9a-f]{40}",
        action["uses"],
    )
    assert action["with"]["branch"] == "cla-signatures"
    assert action["with"]["path-to-signatures"] == "cla/v1/signatures.json"
    assert (
        action["with"]["path-to-document"]
        == "https://github.com/cookscodeinc/cookie-factory/blob/master/.github/CLA.md"
    )
    assert "checkout" not in workflow_text


def test_public_contribution_documents_are_present() -> None:
    """Keep contribution, licensing, privacy, and security guidance together."""
    required = {
        ".github/CLA.md",
        ".github/CLA_PRIVACY.md",
        ".github/CONTRIBUTING.md",
        ".github/SECURITY.md",
        "LICENSE.md",
    }
    assert all((PROJECT_ROOT / path).is_file() for path in required)


def test_dependabot_targets_integration_branch() -> None:
    """Keep automated dependency changes out of the release branch."""
    config = yaml.safe_load((PROJECT_ROOT / ".github/dependabot.yml").read_text(encoding="utf-8"))
    assert config["updates"]
    assert all(update["target-branch"] == "develop" for update in config["updates"])
