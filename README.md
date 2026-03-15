# claude-env

My Claude Code development environment. One repo to restore everything on any machine.

## What's Inside

```
claude-env/
├── plugins/
│   ├── misc/                  ← Personal miscellaneous skills & commands
│   │   ├── .claude-plugin/plugin.json
│   │   ├── skills/ (5 skills)
│   │   └── commands/ (1 command)
│   └── squad/                 ← Self-evolving agent team orchestrator
│       ├── .claude-plugin/plugin.json
│       ├── skills/ (7 skills)
│       ├── commands/ (1 command)
│       ├── hooks/
│       └── config/
├── .claude-plugin/
│   └── marketplace.json       ← Points to plugins via relative paths
├── settings.json              ← Environment snapshot (plugins + permissions + preferences)
├── mcp.template.json          ← MCP server config template
└── install.sh                 ← Setup and sync tool (two modes)
```

## Architecture

### Config Topology

Claude Code reads configuration from multiple layers. This repo manages the global layer:

```
Layer 1: Global (this repo manages)
  ~/.claude/settings.json
  ├── enabledPlugins       26 official enabled + 1 disabled (serena) + 2 custom
  ├── extraKnownMarketplaces
  ├── permissions          allow/deny rules (single source of truth)
  ├── autoUpdatesChannel
  └── effortLevel

Layer 2: Per-project (NOT managed by this repo)
  <project>/.mcp.json      MCP server configs (serena, etc.)
  <project>/.serena/        Serena project settings + memories
```

**Why serena is disabled in enabledPlugins**: Serena works better as a per-project `.mcp.json` config (different projects need different settings). The plugin version is disabled to avoid duplicate MCP servers. See [Serena setup guide](docs/serena-setup-guide.md).

**MCP servers are per-project**: This repo provides `mcp.template.json` as a starting point, but actual `.mcp.json` files live in each project and are gitignored (they may contain tokens).

### Plugin Sources

```
                    claude-env (this repo)
                    Monorepo + Marketplace
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
         plugins/squad  plugins/misc  settings.json
         (in-repo)      (in-repo)     (official plugins
                                       + permissions
                                       + preferences)
```

All plugins live directly in this repo under `plugins/`. The marketplace references them via relative paths:

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

See [Serena setup guide](docs/serena-setup-guide.md) and [Claude Code setup guide](docs/claude-code-setup-guide.md) for full details.

## Daily Operations

### Environment changed (installed new plugin, changed settings, etc.)

```bash
# Save current environment
cp ~/.claude/settings.json ~/claude-env/settings.json
cd ~/claude-env
git add settings.json && git commit -m "update: env snapshot" && git push
```

### Adding a New Plugin

1. Create the plugin directory structure:

```
plugins/<name>/.claude-plugin/
```

2. Add `plugin.json` in that directory:

```json
{
  "name": "<name>",
  "version": "0.1.0",
  "description": "What it does",
  "author": { "name": "EndeavorYen" }
}
```

3. Add skills and/or commands directories with content under `plugins/<name>/`.

4. Add entry to `.claude-plugin/marketplace.json`:

```json
{
  "name": "<name>",
  "source": "./plugins/<name>",
  "description": "What it does"
}
```

5. Add to `settings.json`'s `enabledPlugins`:

```json
"<name>@my-env": true
```

If the plugin provides MCP tools, also add a `mcp__` permission rule in `permissions.allow`.

6. Add install line to `install.sh` (in both `setup` and `sync` sections):

```bash
claude plugin install <name>@my-env --scope user
```

7. Push:

```bash
git add -A && git commit && git push
```

### Update all plugins to latest

```bash
claude plugin marketplace update my-env
claude plugin marketplace update claude-plugins-official
```

## Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
- Git with HTTPS access to GitHub (install.sh configures this automatically)
- `jq` (optional, for non-destructive settings merge during sync)
