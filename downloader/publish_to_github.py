#!/usr/bin/env python3
"""Commit and tag a ClassCodex update, then push to GitHub.

Runs after download_classcodex.py. It stages the ClassCodex/ folder and
only commits when there are real changes, tagging the commit with the
build id from downloader/.last_build. Authentication uses the git
credential helper (e.g. Windows Credential Manager) — no token in code.
"""
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
MARKER = Path(__file__).resolve().parent / ".last_build"
ADDON_DIR = REPO_ROOT / "ClassCodex"


def run_git(*args, check=True, capture=False):
    """Run a git command inside the repo."""
    result = subprocess.run(
        ("git", "-C", str(REPO_ROOT), *args),
        text=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.STDOUT if capture else None,
        check=False,
    )
    if check and result.returncode != 0:
        if capture and result.stdout:
            print(result.stdout, file=sys.stderr)
        raise SystemExit(result.returncode)
    return result


def main() -> int:
    if not MARKER.is_file():
        print("Nothing to publish: no .last_build marker.", file=sys.stderr)
        return 0

    build_id = MARKER.read_text(encoding="utf-8").strip()
    if not build_id:
        print("Nothing to publish: empty build id.", file=sys.stderr)
        return 0

    if not ADDON_DIR.is_dir():
        print(f"Error: addon folder not found: {ADDON_DIR}", file=sys.stderr)
        return 2

    # Stage only the addon folder.
    run_git("add", "ClassCodex")

    # If nothing changed, there is nothing to publish.
    diff = run_git("diff", "--cached", "--quiet", check=False)
    if diff.returncode == 0:
        print(f"No changes for build {build_id}; nothing to push.")
        return 0

    # An annotated tag named after the build id becomes the release.
    tag_result = run_git("tag", "-l", build_id, check=False, capture=True)
    if build_id in tag_result.stdout.split():
        print(f"Tag {build_id} already exists; nothing to push.")
        return 0

    run_git(
        "commit",
        "-m",
        f"chore(addon): update ClassCodex to build {build_id}",
    )
    run_git("tag", "-a", build_id, "-m", f"ClassCodex build {build_id}")

    try:
        run_git("push", "origin", "main")
        run_git("push", "origin", build_id)
    except SystemExit:
        print(
            "Push failed. Check git credentials "
            "(Windows Credential Manager) and network.",
            file=sys.stderr,
        )
        raise

    print(f"Published build {build_id}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())