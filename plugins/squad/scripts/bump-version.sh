#!/usr/bin/env bash
set -euo pipefail

# bump-version.sh — Update squad plugin version across all files
#
# Usage:
#   ./scripts/bump-version.sh auto      # determine bump from conventional commits
#   ./scripts/bump-version.sh patch     # 0.2.0 → 0.2.1
#   ./scripts/bump-version.sh minor     # 0.2.0 → 0.3.0
#   ./scripts/bump-version.sh major     # 0.2.0 → 1.0.0
#   ./scripts/bump-version.sh 0.4.2     # set explicit version
#
# With --release flag: also commits, tags, and pushes
#   ./scripts/bump-version.sh auto --release

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PLUGIN_JSON="$ROOT_DIR/.claude-plugin/plugin.json"
CLAUDE_MD="$ROOT_DIR/CLAUDE.md"
CHANGELOG="$ROOT_DIR/CHANGELOG.md"

DO_RELEASE=false
for arg in "$@"; do
  [[ "$arg" == "--release" ]] && DO_RELEASE=true
done

# ── Read current version ──────────────────────────────────────────────
current_version=$(sed -n 's/.*"version"\s*:\s*"\([0-9]*\.[0-9]*\.[0-9]*\)".*/\1/p' "$PLUGIN_JSON")
if [[ -z "$current_version" ]]; then
  echo "ERROR: Could not read version from $PLUGIN_JSON"
  exit 1
fi

IFS='.' read -r major minor patch <<< "$current_version"

# ── Find last version tag ────────────────────────────────────────────
last_tag=$(git -C "$ROOT_DIR" tag -l 'v*' --sort=-v:refname | head -1 || true)
if [[ -z "$last_tag" ]]; then
  # No tags yet — use first commit
  commit_range="HEAD"
else
  commit_range="${last_tag}..HEAD"
fi

# ── Auto-detect bump type from conventional commits ──────────────────
auto_detect_bump() {
  local range="$1"
  local has_breaking=false
  local has_feat=false
  local has_fix=false

  while IFS= read -r msg; do
    # BREAKING CHANGE in body/footer or ! after type
    if echo "$msg" | grep -qiE 'BREAKING[ _-]CHANGE|^[a-z]+(\(.+\))?!:'; then
      has_breaking=true
    fi
    if echo "$msg" | grep -qE '^feat(\(.+\))?:'; then
      has_feat=true
    fi
    if echo "$msg" | grep -qE '^fix(\(.+\))?:'; then
      has_fix=true
    fi
  done < <(git -C "$ROOT_DIR" log "$range" --pretty=format:"%s" 2>/dev/null)

  if $has_breaking; then
    echo "major"
  elif $has_feat; then
    echo "minor"
  elif $has_fix; then
    echo "patch"
  else
    echo "none"
  fi
}

# ── Python + Changelog helper ────────────────────────────────────────
if python3 -c "pass" 2>/dev/null; then
  PYTHON=python3
else
  PYTHON=python
fi
UPDATE_CHANGELOG_PY="$SCRIPT_DIR/update-changelog.py"

# ── Calculate new version ─────────────────────────────────────────────
bump_type="${1:-}"

if [[ -z "$bump_type" ]]; then
  echo "Usage: $0 <auto|patch|minor|major|X.Y.Z> [--release]"
  echo ""
  echo "Current version: $current_version"
  echo "Last tag: ${last_tag:-none}"
  echo ""
  echo "Commits since last tag:"
  git -C "$ROOT_DIR" log "$commit_range" --pretty=format:"  %s" 2>/dev/null || echo "  (none)"
  echo ""
  detected=$(auto_detect_bump "$commit_range")
  echo "Auto-detected bump: $detected"
  exit 0
fi

if [[ "$bump_type" == "auto" ]]; then
  bump_type=$(auto_detect_bump "$commit_range")
  if [[ "$bump_type" == "none" ]]; then
    echo "No version-relevant commits found since ${last_tag:-initial commit}."
    echo "Only docs/chore/ci/build/test commits detected — no bump needed."
    exit 0
  fi
  echo "Auto-detected bump type: $bump_type"
fi

case "$bump_type" in
  patch) new_version="$major.$minor.$((patch + 1))" ;;
  minor) new_version="$major.$((minor + 1)).0" ;;
  major) new_version="$((major + 1)).0.0" ;;
  [0-9]*.[0-9]*.[0-9]*)
    new_version="$bump_type"
    ;;
  --release)
    # User passed --release without a bump type
    echo "ERROR: --release requires a bump type. Usage: $0 auto --release"
    exit 1
    ;;
  *)
    echo "ERROR: Invalid argument '$bump_type'. Use auto, patch, minor, major, or X.Y.Z"
    exit 1
    ;;
esac

echo "Bumping version: $current_version → $new_version"
echo ""

# ── Update plugin.json ────────────────────────────────────────────────
sed -i "s/\"version\": \"$current_version\"/\"version\": \"$new_version\"/" "$PLUGIN_JSON"
echo "  updated .claude-plugin/plugin.json"

# ── Update CLAUDE.md ──────────────────────────────────────────────────
if [[ -f "$CLAUDE_MD" ]]; then
  sed -i "s/version: \"$current_version\"/version: \"$new_version\"/" "$CLAUDE_MD"
  sed -i "s/目前版本：\`$current_version\`/目前版本：\`$new_version\`/" "$CLAUDE_MD"
  echo "  updated CLAUDE.md"
fi

# ── Update CHANGELOG.md ─────────────────────────────────────────────
if [[ -f "$CHANGELOG" ]] && [[ -f "$UPDATE_CHANGELOG_PY" ]]; then
  $PYTHON "$UPDATE_CHANGELOG_PY" "$CHANGELOG" "$new_version" "$commit_range"
fi

echo ""

# ── Release mode: commit, tag, push ─────────────────────────────────
if $DO_RELEASE; then
  echo "Releasing v$new_version..."
  cd "$ROOT_DIR"
  git add -A
  git commit -m "chore: release v$new_version"
  git tag "v$new_version"
  echo ""
  echo "  committed and tagged v$new_version"
  echo ""
  echo "Run 'git push && git push --tags' to publish."
else
  echo "Done. Files updated locally."
  echo ""
  echo "Next steps:"
  echo "  1. Review CHANGELOG.md"
  echo "  2. git add -A && git commit -m \"chore: release v$new_version\""
  echo "  3. git tag v$new_version"
  echo "  4. git push && git push --tags"
  echo ""
  echo "Or use --release flag to auto-commit and tag:"
  echo "  $0 $1 --release"
fi
