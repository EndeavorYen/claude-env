# squad — Self-Evolving Agent Team Orchestrator

Claude Code plugin that dispatches an AI agent squad to plan, execute, verify, and deliver complex development tasks.

## Quick Start

```bash
# Install via claude-env marketplace
claude plugin install squad@my-env --scope user

# Use
/squad "implement dark mode for the app"
/squad "fix the authentication bug" --gate supervised
/squad "refactor database layer" --gate autonomous
```

## 7-Stage Pipeline

```
RECON → PLAN → EXECUTE → INTEGRATE → VERIFY → DEBRIEF → RETRO
```

| Stage | What it does |
|-------|-------------|
| **RECON** | Silently reads CLAUDE.md, DESIGN.md, git log, knowledge base |
| **PLAN** | Decomposes tasks, designs agent roles, isolation strategy |
| **EXECUTE** | Spawns agents (supports convoy batching), monitors execution |
| **INTEGRATE** | Merges worktree/file-boundary outputs, conflict detection |
| **VERIFY** | Runs lint/typecheck/test, baseline diff analysis |
| **DEBRIEF** | Generates mission report, updates ROADMAP.md |
| **RETRO** | Retrospective analysis, updates knowledge base |

## Gate Levels

| Level | Behavior |
|-------|----------|
| `supervised` | Pauses after every stage |
| `standard` (default) | Pauses after PLAN, INTEGRATE, VERIFY |
| `autonomous` | Only pauses on conflicts or failures |

## Version Management

This project uses **automatic versioning** based on [conventional commits](https://www.conventionalcommits.org/).

### Setup (one-time)

```bash
bash scripts/install-hooks.sh
```

This installs a `post-commit` git hook. After installation, version bumps happen automatically:

```bash
git commit -m "feat: add dark mode toggle"
# → auto-creates "chore: release v0.3.0" commit + v0.3.0 tag

git commit -m "fix: handle null session"
# → auto-creates "chore: release v0.3.1" commit + v0.3.1 tag

git commit -m "docs: update README"
# → no version bump (docs are not user-facing changes)
```

### How it works

```
feat: commit  ──→  post-commit hook  ──→  bump-version.sh auto  ──→  minor bump + tag
fix:  commit  ──→  post-commit hook  ──→  bump-version.sh auto  ──→  patch bump + tag
feat!: commit ──→  post-commit hook  ──→  bump-version.sh auto  ──→  major bump + tag
docs: commit  ──→  post-commit hook  ──→  (no bump)
```

The hook uses an environment variable (`SQUAD_BUMPING`) to prevent recursion — the auto-generated `chore: release` commit won't trigger itself.

### Commit prefix → version mapping

| Prefix | Bump | Example |
|--------|------|---------|
| `feat:` | minor (0.x.0) | `feat: add convoy deployment` |
| `fix:` | patch (0.0.x) | `fix: stale agent fallback` |
| `feat!:` or `BREAKING CHANGE` | major (x.0.0) | `feat!: redesign pipeline` |
| `docs:`, `chore:`, `ci:`, `test:` | no bump | `docs: update CLAUDE.md` |

### Manual versioning

If you prefer not to use the hook, or need to bump manually:

```bash
# Show current status (version, unreleased commits, detected bump type)
./scripts/bump-version.sh

# Auto-detect and bump (updates files only)
./scripts/bump-version.sh auto

# Auto-detect, bump, commit, and tag
./scripts/bump-version.sh auto --release

# Explicit bump type
./scripts/bump-version.sh patch
./scripts/bump-version.sh minor
./scripts/bump-version.sh major

# Set exact version
./scripts/bump-version.sh 1.0.0
```

### Files involved

| File | Role |
|------|------|
| `.claude-plugin/plugin.json` | Source of truth for version number |
| `CHANGELOG.md` | Auto-generated release history ([Keep a Changelog](https://keepachangelog.com/) format) |
| `CLAUDE.md` | Version references updated automatically |
| `scripts/bump-version.sh` | Main versioning script |
| `scripts/update-changelog.py` | CHANGELOG generator (called by bump script) |
| `scripts/hooks/post-commit` | Git hook for auto-bump on commit |
| `scripts/install-hooks.sh` | One-time hook installer |

### Disabling auto-versioning

```bash
rm .git/hooks/post-commit
```

## Development

See [CLAUDE.md](CLAUDE.md) for architecture details, design decisions, and contribution guidelines.

## License

MIT
