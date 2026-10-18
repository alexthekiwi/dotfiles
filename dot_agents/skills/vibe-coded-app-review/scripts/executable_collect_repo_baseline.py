#!/usr/bin/env python3
"""Collect a non-executing, secret-safe repository baseline for an app review."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
from collections import Counter
from pathlib import Path
from typing import Any


IGNORED_DIRS = {
    ".git",
    ".next",
    ".nuxt",
    ".turbo",
    ".expo",
    ".venv",
    "build",
    "coverage",
    "dist",
    "node_modules",
    "target",
    "vendor",
}

MANIFESTS = {
    "package.json",
    "package-lock.json",
    "pnpm-lock.yaml",
    "yarn.lock",
    "bun.lock",
    "bun.lockb",
    "composer.json",
    "composer.lock",
    "pyproject.toml",
    "requirements.txt",
    "Cargo.toml",
    "Cargo.lock",
    "pubspec.yaml",
    "pubspec.lock",
    "build.gradle",
    "build.gradle.kts",
    "settings.gradle",
    "settings.gradle.kts",
}

RISKY_NAME_MARKERS = (
    ".env",
    "credential",
    "gitleaks",
    "secret",
    "service-account",
    "service_account",
)

DIAGNOSTIC_MARKERS = ("crash", "gitleaks", "logcat", "trace")
TEST_MARKERS = ("/__tests__/", "/test/", "/tests/", ".test.", ".spec.")


def run_git(root: Path, *args: str) -> str | None:
    try:
        result = subprocess.run(
            ["git", "-C", str(root), *args],
            check=True,
            capture_output=True,
            text=True,
            timeout=10,
        )
        return result.stdout.strip()
    except (FileNotFoundError, subprocess.CalledProcessError, subprocess.TimeoutExpired):
        return None


def iter_files(root: Path):
    for directory, dirnames, filenames in os.walk(root):
        dirnames[:] = sorted(d for d in dirnames if d not in IGNORED_DIRS)
        base = Path(directory)
        for filename in sorted(filenames):
            path = base / filename
            try:
                relative = path.relative_to(root)
            except ValueError:
                continue
            yield path, relative


def load_package_json(path: Path) -> dict[str, Any] | None:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
        return value if isinstance(value, dict) else None
    except (OSError, UnicodeDecodeError, json.JSONDecodeError):
        return None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repo", type=Path, help="Repository root")
    parser.add_argument("--markdown", action="store_true", help="Emit compact Markdown instead of JSON")
    args = parser.parse_args()

    root = args.repo.expanduser().resolve()
    if not root.is_dir():
        parser.error(f"Not a directory: {root}")

    files: list[str] = []
    extensions: Counter[str] = Counter()
    manifests: list[str] = []
    ci_files: list[str] = []
    test_files: list[str] = []
    migration_files: list[str] = []
    instruction_files: list[str] = []
    risky_names: list[str] = []
    diagnostics: list[str] = []

    for path, relative_path in iter_files(root):
        relative = relative_path.as_posix()
        lower = relative.lower()
        files.append(relative)
        extensions[path.suffix.lower() or "<none>"] += 1
        if path.name in MANIFESTS:
            manifests.append(relative)
        if lower.startswith(".github/workflows/") or lower in {".gitlab-ci.yml", "bitbucket-pipelines.yml"}:
            ci_files.append(relative)
        framed = f"/{lower}"
        if any(marker in framed for marker in TEST_MARKERS):
            test_files.append(relative)
        if "/migrations/" in framed or lower.startswith("migrations/"):
            migration_files.append(relative)
        if path.name in {"AGENTS.md", "CLAUDE.md", "README.md"}:
            instruction_files.append(relative)
        if any(marker in path.name.lower() for marker in RISKY_NAME_MARKERS):
            risky_names.append(relative)
        if any(marker in path.name.lower() for marker in DIAGNOSTIC_MARKERS):
            diagnostics.append(relative)

    tracked_raw = run_git(root, "ls-files", "-z")
    tracked = set(tracked_raw.split("\0")) if tracked_raw else set()

    package = load_package_json(root / "package.json")
    dependencies: dict[str, str] = {}
    scripts: dict[str, str] = {}
    if package:
        for key in ("dependencies", "devDependencies", "peerDependencies"):
            values = package.get(key)
            if isinstance(values, dict):
                dependencies.update({str(name): str(version) for name, version in values.items()})
        raw_scripts = package.get("scripts")
        if isinstance(raw_scripts, dict):
            scripts = {str(name): str(command) for name, command in raw_scripts.items()}

    tracked_risky = sorted(name for name in risky_names if name in tracked)
    tracked_diagnostics = sorted(name for name in diagnostics if name in tracked)

    prompts: list[str] = []
    if not ci_files:
        prompts.append("No CI workflow detected")
    if not test_files:
        prompts.append("No test files detected")
    if package and not any(name in scripts for name in ("test", "typecheck", "lint")):
        prompts.append("package.json has no test, typecheck or lint quality gate")
    if not migration_files:
        prompts.append("No migration files detected; verify whether the live schema is reproducible")
    if tracked_risky:
        prompts.append("Tracked files have secret-related names; inspect safely without printing contents")
    if tracked_diagnostics:
        prompts.append("Tracked diagnostic or scan reports may contain sensitive data")

    result = {
        "root": str(root),
        "git": {
            "branch": run_git(root, "branch", "--show-current"),
            "head": run_git(root, "rev-parse", "--short=12", "HEAD"),
            "status": (run_git(root, "status", "--short") or "").splitlines(),
            "remotes": (run_git(root, "remote", "-v") or "").splitlines(),
        },
        "inventory": {
            "file_count": len(files),
            "extensions": dict(extensions.most_common(20)),
            "manifests": sorted(manifests),
            "instructions": sorted(instruction_files),
            "ci_files": sorted(ci_files),
            "test_file_count": len(test_files),
            "test_files_sample": sorted(test_files)[:30],
            "migration_file_count": len(migration_files),
            "migration_files_sample": sorted(migration_files)[:30],
            "tracked_risky_filenames": tracked_risky,
            "tracked_diagnostic_filenames": tracked_diagnostics,
        },
        "package_json": {
            "present": package is not None,
            "scripts": scripts,
            "dependencies": dict(sorted(dependencies.items())),
        },
        "review_prompts": prompts,
    }

    if args.markdown:
        print("# Repository baseline")
        print(f"\n- Root: `{root}`")
        print(f"- Git: `{result['git']['branch'] or 'unknown'}` at `{result['git']['head'] or 'unknown'}`")
        print(f"- Files inspected by name: {len(files)}")
        print(f"- Manifests: {', '.join(f'`{x}`' for x in sorted(manifests)) or 'none'}")
        print(f"- Tests: {len(test_files)} files")
        print(f"- Migrations: {len(migration_files)} files")
        print(f"- CI: {', '.join(f'`{x}`' for x in sorted(ci_files)) or 'none'}")
        if prompts:
            print("\n## Review prompts")
            for prompt in prompts:
                print(f"\n- {prompt}")
        if tracked_risky or tracked_diagnostics:
            print("\n## Tracked filenames to inspect safely")
            for name in sorted(set(tracked_risky + tracked_diagnostics)):
                print(f"\n- `{name}`")
    else:
        print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
