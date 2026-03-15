#!/usr/bin/env bash
set -euo pipefail

# install-hooks.sh — Install git hooks for auto-versioning

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_DIR="$ROOT_DIR/.git/hooks"

echo "Installing git hooks for auto-versioning..."

cp "$SCRIPT_DIR/hooks/post-commit" "$HOOKS_DIR/post-commit"
chmod +x "$HOOKS_DIR/post-commit"
echo "  installed post-commit hook"

echo ""
echo "Done. Auto-versioning is now active."
echo "  feat: commits → minor bump"
echo "  fix:  commits → patch bump"
echo "  feat!: or BREAKING CHANGE → major bump"
echo ""
echo "To disable: rm .git/hooks/post-commit"
