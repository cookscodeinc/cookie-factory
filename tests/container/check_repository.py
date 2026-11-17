"""Perform non-mutating repository hygiene checks for CI."""

from __future__ import annotations

import json
import stat
import subprocess
import tomllib
from pathlib import Path

MAX_FILE_SIZE = 500 * 1024
PRIVATE_KEY_MARKERS = (
    *(
        b"-----BEGIN " + key_type + b" PRIVATE KEY-----"
        for key_type in (b"DSA", b"EC", b"OPENSSH", b"RSA")
    ),
    b"-----BEGIN " + b"PGP PRIVATE KEY BLOCK-----",
)
CONFLICT_MARKERS = (b"<<<<<<< ", b"=======", b">>>>>>> ")


def repository_files(root: Path) -> list[Path]:
    """Return tracked and non-ignored untracked repository files."""
    result = subprocess.run(
        [
            "git",
            "ls-files",
            "--cached",
            "--others",
            "--exclude-standard",
            "-z",
        ],
        cwd=root,
        check=False,
        capture_output=True,
    )
    if result.returncode:
        details = result.stderr.decode(errors="replace").strip()
        raise SystemExit(f"Unable to enumerate repository files with Git:\n{details}")
    return [root / path.decode() for path in result.stdout.split(b"\0") if path]


def check_text(path: Path, content: bytes) -> list[str]:
    """Validate line endings, whitespace, markers, and executable metadata."""
    errors: list[str] = []
    relative_path = path.relative_to(Path.cwd())

    if content.startswith(b"\xef\xbb\xbf"):
        errors.append(f"{relative_path}: contains a UTF-8 byte order marker")
    if b"\r" in content:
        errors.append(f"{relative_path}: contains a carriage return")
    if content and not content.endswith(b"\n"):
        errors.append(f"{relative_path}: does not end with a newline")

    for line_number, line in enumerate(content.splitlines(), start=1):
        if line.endswith((b" ", b"\t")):
            errors.append(f"{relative_path}:{line_number}: trailing whitespace")
        if line.startswith(CONFLICT_MARKERS):
            errors.append(f"{relative_path}:{line_number}: merge-conflict marker")

    is_executable = bool(path.stat().st_mode & stat.S_IXUSR)
    has_shebang = content.startswith(b"#!")
    if is_executable and not has_shebang:
        errors.append(f"{relative_path}: executable text file has no shebang")
    if has_shebang and not is_executable:
        errors.append(f"{relative_path}: shebang script is not executable")

    if any(marker in content for marker in PRIVATE_KEY_MARKERS):
        errors.append(f"{relative_path}: appears to contain a private key")
    return errors


def check_structured_file(path: Path, content: bytes) -> list[str]:
    """Parse every JSON and TOML file."""
    relative_path = path.relative_to(Path.cwd())
    try:
        if path.suffix == ".json":
            json.loads(content)
        elif path.suffix == ".toml":
            tomllib.loads(content.decode())
    except (UnicodeDecodeError, json.JSONDecodeError, tomllib.TOMLDecodeError) as error:
        return [f"{relative_path}: invalid {path.suffix[1:].upper()}: {error}"]
    return []


def main() -> None:
    """Validate repository files without modifying the working tree."""
    root = Path.cwd()
    files = repository_files(root)
    errors: list[str] = []
    normalized_paths: dict[str, Path] = {}

    for path in files:
        relative_path = path.relative_to(root)
        normalized_path = str(relative_path).casefold()
        if previous_path := normalized_paths.get(normalized_path):
            if previous_path != relative_path:
                errors.append(f"case conflict: {previous_path} and {relative_path}")
        else:
            normalized_paths[normalized_path] = relative_path

        if path.is_symlink():
            if not path.exists():
                errors.append(f"{relative_path}: broken symbolic link")
            continue
        if not path.is_file():
            continue
        if path.stat().st_size > MAX_FILE_SIZE:
            errors.append(f"{relative_path}: exceeds {MAX_FILE_SIZE // 1024} KiB")

        content = path.read_bytes()
        if b"\0" in content:
            continue
        errors.extend(check_text(path, content))
        errors.extend(check_structured_file(path, content))

    if errors:
        raise SystemExit("Repository hygiene failed:\n" + "\n".join(errors))
    print(f"Repository hygiene passed for {len(files)} files.")


if __name__ == "__main__":
    main()
