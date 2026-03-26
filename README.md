# claude-env

My Claude Code development environment. One repo to restore everything on any machine.

## What's Inside

```
claude-env/
├── plugins/
│   ├── squad/                 ← in-repo: Self-evolving agent team orchestrator
│   ├── misc/                  ← in-repo: Personal miscellaneous skills & commands
│   ├── battle/                ← in-repo: Adversarial quality battle system
│   └── chrome-cdp/            ← submodule → EndeavorYen/chrome-cdp-ex
├── .claude-plugin/
│   └── marketplace.json       ← Points to plugins via relative paths (submodule or in-repo)
├── settings.json              ← Environment snapshot (plugins + permissions + preferences)
├── mcp.template.json          ← MCP server config template
└── install.sh                 ← Setup and sync (handles submodule init automatically)
```

## Architecture

### Config Topology

Claude Code reads configuration from multiple layers. This repo manages the global layer:

```
Layer 1: Global (this repo manages)
  ~/.claude/settings.json
  ├── enabledPlugins       26 official enabled + 2 custom
  ├── extraKnownMarketplaces
  ├── permissions          allow/deny rules (single source of truth)
  ├── autoUpdatesChannel
  └── effortLevel

Layer 2: Per-project (NOT managed by this repo)
  <project>/.mcp.json      MCP server configs
```

**MCP servers are per-project**: This repo provides `mcp.template.json` as a starting point, but actual `.mcp.json` files live in each project and are gitignored (they may contain tokens).

### Plugin Sources

```
                    claude-env (this repo)
                    Monorepo + Marketplace
                           │
         ┌─────────────────┼─────────────────┐
         ▼                 ▼                  ▼
    plugins/ (in-repo)  plugins/ (submodule)  settings.json
    squad, misc,        chrome-cdp →          (official plugins
    battle              external repo          + permissions)
```

Plugins live under `plugins/` — either directly in-repo or as **git submodules** pointing to external repos. The marketplace references all of them identically via relative paths. `install.sh` handles submodule initialization automatically in both the local checkout and the marketplace clone.

| File | Format | Example | Why |
|------|--------|---------|-----|
| `marketplace.json` | Relative path | `"source": "./plugins/squad"` | Plugin lives in same repo, relative path resolves from marketplace root |
| `settings.json` | Git URL | `"source": "git", "url": "https://github.com/EndeavorYen/claude-env.git"` | Marketplace registration requires `git` source type |
| `install.sh` | Bare HTTPS | `https://github.com/EndeavorYen/claude-env.git` | CLI `marketplace add` command takes a URL string |

## New Machine Setup

```bash
git clone https://github.com/EndeavorYen/claude-env.git
cd claude-env
bash install.sh setup
```

This will:
1. Configure git for HTTPS
2. Register the monorepo marketplace
3. Restore `settings.json` (backs up existing if present)
4. Install custom plugins (squad, misc)
5. Deploy `mcp.template.json` to `~/.claude/` for easy project setup

## Sync on Another Machine

```bash
cd ~/claude-env && git pull
bash install.sh sync
```

Sync mode merges settings non-destructively with array-union semantics: `permissions.allow` and `permissions.deny` rules from both repo and local are combined (neither side's rules are dropped). Scalar keys use local-wins strategy. Requires `jq`; falls back to overwrite with backup if unavailable. Works in non-interactive contexts (CI, piped execution).

## Setting Up MCP in a Project

`install.sh` automatically deploys `mcp.template.json` to `~/.claude/mcp.template.json` during both setup and sync. To use it in a project:

```bash
# Copy from the deployed location (or directly from this repo)
cp ~/.claude/mcp.template.json /path/to/project/.mcp.json

# Make sure .mcp.json is gitignored in that project
echo ".mcp.json" >> /path/to/project/.gitignore
```

See [Claude Code setup guide](docs/claude-code-setup-guide.md) for full details.

## Daily Operations

### Environment changed (installed new plugin, changed settings, etc.)

```bash
# Save current environment
cp ~/.claude/settings.json ~/claude-env/settings.json
cd ~/claude-env
git add settings.json && git commit -m "update: env snapshot" && git push
```

### Adding a New Plugin

#### Option A: In-repo plugin (simple, for small/personal plugins)

1. Create `plugins/<name>/.claude-plugin/plugin.json`
2. Add skills/commands under `plugins/<name>/`
3. Add entry to `.claude-plugin/marketplace.json`
4. Add install line to `install.sh` (both `setup` and `sync` sections)
5. Add `"<name>@my-env": true` to `settings.json`'s `enabledPlugins`

#### Option B: External repo via submodule (for independently maintained plugins)

```bash
# 1. Add submodule
git submodule add https://github.com/<owner>/<repo>.git plugins/<name>

# 2. The external repo must have .claude-plugin/plugin.json at its root
```

3. Add entry to `.claude-plugin/marketplace.json` (same as in-repo):

```json
{
  "name": "<name>",
  "source": "./plugins/<name>",
  "description": "What it does"
}
```

4. Add install line to `install.sh` (both `setup` and `sync` sections)
5. Add `"<name>@my-env": true` to `settings.json`'s `enabledPlugins`
6. Push:

```bash
git add -A && git commit && git push
```

`install.sh` handles submodule initialization automatically — no manual `git submodule update` needed.

### Update all plugins to latest

```bash
claude plugin marketplace update my-env
claude plugin marketplace update claude-plugins-official
```

## Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
- Git with HTTPS access to GitHub (install.sh configures this automatically)
- `jq` (optional, for non-destructive settings merge during sync)
