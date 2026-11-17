"""Exercise release validation without creating tags or GitHub Releases."""

from __future__ import annotations

import os
import shutil
import subprocess
from pathlib import Path

import pytest
import yaml

PROJECT_ROOT = Path(__file__).resolve().parents[1]
RELEASE_SCRIPT = PROJECT_ROOT / "scripts/release.sh"


def run(
    *args: str, cwd: Path, env: dict[str, str] | None = None
) -> subprocess.CompletedProcess[str]:
    """Run a command with captured output."""
    return subprocess.run(
        args,
        cwd=cwd,
        env=env,
        text=True,
        capture_output=True,
        check=False,
    )


def git(repo: Path, *args: str) -> None:
    """Run a Git command and require success."""
    subprocess.run(["git", *args], cwd=repo, check=True, capture_output=True)


@pytest.fixture
def release_repository(tmp_path: Path) -> tuple[Path, dict[str, str]]:
    """Create a clean master repository with fake offline release tools."""
    repo = tmp_path / "repository"
    fake_bin = tmp_path / "bin"
    repo.mkdir()
    fake_bin.mkdir()

    git(repo, "init", "--initial-branch=master")
    git(repo, "config", "user.name", "Release Test")
    git(repo, "config", "user.email", "release@example.com")
    shutil.copy(RELEASE_SCRIPT, repo / "release.sh")
    (repo / "VERSION").write_text("0.1.0\n", encoding="utf-8")
    (repo / "cliff.toml").write_text("[changelog]\n", encoding="utf-8")
    (repo / "project.txt").write_text("initial\n", encoding="utf-8")
    git(repo, "add", ".")
    git(repo, "commit", "-m", "feat: initial release")

    git_cliff = fake_bin / "git-cliff"
    git_cliff.write_text(
        """#!/usr/bin/env bash
set -euo pipefail
output=""
while (($#)); do
    if [[ "$1" == "--output" ]]; then
        output="$2"
        shift 2
    else
        shift
    fi
done
case "${FAKE_CLIFF_MODE:-valid}" in
    empty) : >"$output" ;;
    invalid) printf 'No changes\n' >"$output" ;;
    *) printf '## Features\n\n- Initial release (`abc1234`)\n' >"$output" ;;
esac
""",
        encoding="utf-8",
    )
    git_cliff.chmod(0o755)

    gh = fake_bin / "gh"
    gh.write_text(
        """#!/usr/bin/env bash
if [[ "${FAKE_GH_DUPLICATE:-0}" == "1" ]]; then
    exit 0
fi
printf 'release not found\n' >&2
exit 1
""",
        encoding="utf-8",
    )
    gh.chmod(0o755)

    env = os.environ.copy()
    env.update(
        {
            "ALLOW_PRERELEASE": "false",
            "CHECK_REMOTE_RELEASE": "false",
            "MASTER_REF": "master",
            "PATH": f"{fake_bin}:{env['PATH']}",
            "RELEASE_COMMIT": "HEAD",
            "RELEASE_NOTES_FILE": "release-notes.md",
            "RELEASE_TAG": "v0.1.0",
            "REQUIRE_MASTER_BRANCH": "true",
            "REQUIRE_TAG": "false",
        }
    )
    return repo, env


def test_valid_release_candidate(release_repository: tuple[Path, dict[str, str]]) -> None:
    """Accept a clean semantic version on master."""
    repo, env = release_repository
    result = run(str(repo / "release.sh"), "check", cwd=repo, env=env)
    assert result.returncode == 0, result.stderr
    assert "Release candidate validated" in result.stdout


def test_invalid_semantic_version_is_rejected(
    release_repository: tuple[Path, dict[str, str]],
) -> None:
    """Reject leading zeros and malformed semantic version tags."""
    repo, env = release_repository
    env["RELEASE_TAG"] = "v01.0.0"
    result = run(str(repo / "release.sh"), "check", cwd=repo, env=env)
    assert result.returncode != 0
    assert "strict semantic version" in result.stderr


def test_prerelease_requires_explicit_configuration(
    release_repository: tuple[Path, dict[str, str]],
) -> None:
    """Only accept prerelease identifiers after an explicit opt-in."""
    repo, env = release_repository
    (repo / "VERSION").write_text("1.0.0-rc.1\n", encoding="utf-8")
    git(repo, "add", "VERSION")
    git(repo, "commit", "-m", "chore: prepare release candidate")
    env["RELEASE_TAG"] = "v1.0.0-rc.1"

    rejected = run(str(repo / "release.sh"), "check", cwd=repo, env=env)
    assert rejected.returncode != 0
    assert "ALLOW_PRERELEASE=true" in rejected.stderr

    env["ALLOW_PRERELEASE"] = "true"
    accepted = run(str(repo / "release.sh"), "check", cwd=repo, env=env)
    assert accepted.returncode == 0, accepted.stderr


def test_duplicate_release_is_rejected(
    release_repository: tuple[Path, dict[str, str]],
) -> None:
    """Reject a version that GitHub already published."""
    repo, env = release_repository
    env.update(
        {
            "CHECK_REMOTE_RELEASE": "true",
            "FAKE_GH_DUPLICATE": "1",
            "GH_TOKEN": "test-token",
            "GITHUB_REPOSITORY": "example/cookie-factory",
        }
    )
    result = run(str(repo / "release.sh"), "check", cwd=repo, env=env)
    assert result.returncode != 0
    assert "already exists" in result.stderr


def test_commit_outside_master_is_rejected(
    release_repository: tuple[Path, dict[str, str]],
) -> None:
    """Reject tags whose commits are not reachable from master."""
    repo, env = release_repository
    git(repo, "switch", "--create", "feature")
    (repo / "project.txt").write_text("feature\n", encoding="utf-8")
    git(repo, "add", "project.txt")
    git(repo, "commit", "-m", "feat: unmerged change")
    env["REQUIRE_MASTER_BRANCH"] = "false"
    result = run(str(repo / "release.sh"), "check", cwd=repo, env=env)
    assert result.returncode != 0
    assert "not reachable from master" in result.stderr


@pytest.mark.parametrize("mode", ["empty", "invalid"])
def test_invalid_release_notes_are_rejected(
    release_repository: tuple[Path, dict[str, str]], mode: str
) -> None:
    """Reject missing or structurally invalid git-cliff output."""
    repo, env = release_repository
    env["FAKE_CLIFF_MODE"] = mode
    result = run(str(repo / "release.sh"), "notes", cwd=repo, env=env)
    assert result.returncode != 0
    assert "release notes" in result.stderr


def test_real_git_cliff_dry_run_creates_no_tag(tmp_path: Path) -> None:
    """Generate real notes without creating a tag or GitHub Release."""
    if shutil.which("git-cliff") is None:
        pytest.skip("git-cliff is provided by the project container")

    repo = tmp_path / "real-cliff"
    repo.mkdir()
    git(repo, "init", "--initial-branch=master")
    git(repo, "config", "user.name", "Release Test")
    git(repo, "config", "user.email", "release@example.com")
    shutil.copy(RELEASE_SCRIPT, repo / "release.sh")
    shutil.copy(PROJECT_ROOT / "cliff.toml", repo / "cliff.toml")
    (repo / "release.sh").chmod(0o755)
    (repo / "VERSION").write_text("0.1.0\n", encoding="utf-8")
    (repo / "project.txt").write_text("release automation\n", encoding="utf-8")
    git(repo, "add", ".")
    git(repo, "commit", "-m", "feat: add verified release automation")

    env = os.environ.copy()
    env.update(
        {
            "CHECK_REMOTE_RELEASE": "false",
            "MASTER_REF": "master",
            "RELEASE_NOTES_FILE": "build/release-notes.md",
            "RELEASE_TAG": "v0.1.0",
            "REQUIRE_MASTER_BRANCH": "true",
        }
    )
    tags_before = run("git", "tag", cwd=repo, env=env).stdout
    result = run(str(repo / "release.sh"), "dry-run", cwd=repo, env=env)
    tags_after = run("git", "tag", cwd=repo, env=env).stdout

    assert result.returncode == 0, result.stderr
    assert "## Features" in (repo / "build/release-notes.md").read_text(encoding="utf-8")
    assert "No tag or GitHub Release was created" in result.stdout
    assert tags_after == tags_before == ""


def test_release_workflow_cannot_publish_from_branch_pushes() -> None:
    """Require tag-only publishing after the reusable verification job."""
    workflow_path = PROJECT_ROOT / ".github/workflows/release.yml"
    workflow = yaml.load(workflow_path.read_text(encoding="utf-8"), Loader=yaml.BaseLoader)
    trigger = workflow["on"]
    assert set(trigger) == {"push"}
    assert "tags" in trigger["push"]
    assert "branches" not in trigger["push"]

    jobs = workflow["jobs"]
    assert jobs["verify"]["uses"] == "./.github/workflows/container-tests.yml"
    publish_needs = jobs["publish"]["needs"]
    assert set(publish_needs) == {"validate", "verify"}
    assert "if" not in jobs["publish"]


def test_ci_keeps_auxiliary_checkout_outside_source_tree() -> None:
    """Keep foreign template files outside the repository lint boundary."""
    workflow_path = PROJECT_ROOT / ".github/workflows/container-tests.yml"
    workflow_text = workflow_path.read_text(encoding="utf-8")
    workflow = yaml.load(workflow_text, Loader=yaml.BaseLoader)
    verify = workflow["jobs"]["verify"]
    steps = {step["name"]: step for step in verify["steps"]}

    assert verify["defaults"]["run"]["working-directory"] == "cookie-factory"
    assert steps["Check out Cookie Factory"]["with"]["path"] == "cookie-factory"
    auxiliary_paths = {
        step["with"]["path"]
        for step in verify["steps"]
        if step["name"].startswith("Check out ") and step["name"] != "Check out Cookie Factory"
    }
    assert auxiliary_paths == {
        "templates/ansible-galaxy-cookiecutter",
        "templates/cookiecutter-cookiecutter",
        "templates/github-doc-cookiecutter",
        "templates/python3-cookiecutter",
        "templates/sphinx-cookiecutter",
    }
    build_inputs = steps["Build test toolchain"]["with"]
    assert build_inputs["context"] == "./cookie-factory"
    assert build_inputs["file"] == "./cookie-factory/docker/Dockerfile"
    assert "docker compose run --rm hooks" not in workflow_text
