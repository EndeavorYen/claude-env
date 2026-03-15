#!/usr/bin/env python3
"""Update CHANGELOG.md: move [Unreleased] content into a new version section,
then auto-generate entries from git commit messages."""

import re
import subprocess
import sys
from datetime import date
from pathlib import Path


def get_commits(root: str, commit_range: str) -> list[str]:
    result = subprocess.run(
        ["git", "-C", root, "log", commit_range, "--pretty=format:%s"],
        capture_output=True, text=True
    )
    return [line for line in result.stdout.strip().splitlines() if line]


def categorize(messages: list[str]) -> dict[str, list[str]]:
    cats: dict[str, list[str]] = {"Added": [], "Changed": [], "Fixed": []}
    for msg in messages:
        # Strip conventional commit prefix
        entry = re.sub(r'^[a-z]+(\([^)]+\))?!?:\s*', '', msg)
        if re.match(r'^feat(\(.+\))?:', msg):
            cats["Added"].append(entry)
        elif re.match(r'^fix(\(.+\))?:', msg):
            cats["Fixed"].append(entry)
        elif re.match(r'^(refactor|perf|style)(\(.+\))?:', msg):
            cats["Changed"].append(entry)
        # docs/chore/ci/build/test → skip
    return {k: v for k, v in cats.items() if v}


def build_version_block(version: str, categories: dict[str, list[str]]) -> str:
    today = date.today().isoformat()
    lines = [f"## [{version}] - {today}", ""]
    for cat, entries in categories.items():
        lines.append(f"### {cat}")
        lines.append("")
        for e in entries:
            lines.append(f"- {e}")
        lines.append("")
    return "\n".join(lines)


def main():
    if len(sys.argv) < 4:
        print("Usage: update-changelog.py <changelog_path> <new_version> <commit_range>")
        sys.exit(1)

    changelog_path = Path(sys.argv[1])
    new_version = sys.argv[2]
    commit_range = sys.argv[3]
    root = str(changelog_path.parent)

    if not changelog_path.exists():
        print(f"CHANGELOG not found: {changelog_path}")
        sys.exit(1)

    commits = get_commits(root, commit_range)
    categories = categorize(commits)
    if not categories:
        print("No user-facing changes to add to changelog.")
        sys.exit(0)

    content = changelog_path.read_text(encoding="utf-8")
    version_block = build_version_block(new_version, categories)

    # Replace [Unreleased] section: keep the header, clear its content,
    # insert new version block between [Unreleased] and the next ## [
    pattern = r'(## \[Unreleased\]).*?(\n## \[)'
    replacement = f"\\1\n\n{version_block}\n\\2"

    new_content, count = re.subn(pattern, replacement, content, count=1, flags=re.DOTALL)

    if count == 0:
        # No [Unreleased] section — insert before first ## [
        new_content = re.sub(
            r'(\n## \[)',
            f"\n{version_block}\n\\1",
            content,
            count=1
        )

    changelog_path.write_text(new_content, encoding="utf-8")
    print(f"  updated CHANGELOG.md (auto-generated from {len(commits)} commits)")


if __name__ == "__main__":
    main()
