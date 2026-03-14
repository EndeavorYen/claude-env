# claude-env

My Claude Code development environment. One repo to restore everything on any machine.

## What's Inside

```
claude-env/
├── .claude-plugin/
│   └── marketplace.json   ← Points to all my custom plugin repos
├── settings.json          ← Environment snapshot (plugins + permissions + preferences)
├── mcp.template.json      ← MCP server config template (copy to projects as .mcp.json)
└── install.sh             ← Setup and sync tool (two modes)
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
                    Umbrella marketplace
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
         claude-squad  claude-misc   settings.json
         (own repo)    (own repo)    (official plugins
                                      + permissions
                                      + preferences)
```

Repo references use different formats because each consumer requires its own syntax:

| File | Format | Example | Why |
|------|--------|---------|-----|
| `marketplace.json` | GitHub shorthand | `"source": "github", "repo": "EndeavorYen/claude-squad"` | Plugin system requires `github` source type |
| `settings.json` | Git URL | `"source": "git", "url": "https://github.com/EndeavorYen/claude-env.git"` | Marketplace registration requires `git` source type |
| `install.sh` | Bare HTTPS | `https://github.com/EndeavorYen/claude-env.git` | CLI `marketplace add` command takes a URL string |

All three resolve to the same GitHub HTTPS endpoint. The format differences are dictated by their respective consumers, not a consistency issue.

## New Machine Setup

```bash
git clone https://github.com/EndeavorYen/claude-env.git
cd claude-env
bash install.sh setup
```

This will:
1. Configure git for HTTPS
2. Register the umbrella marketplace
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

### Added a new custom plugin repo

1. Add entry to `.claude-plugin/marketplace.json`:

```json
{
  "name": "my-new-plugin",
  "source": {
    "source": "github",
    "repo": "EndeavorYen/claude-my-new-plugin",
    "ref": "main"
  },
  "description": "What it does"
}
```

2. Add to `settings.json`'s `enabledPlugins`:

```json
"my-new-plugin@my-env": true
```

If the plugin provides MCP tools, also add a `mcp__` permission rule in `permissions.allow`.

3. Add install line to `install.sh` (in both `setup` and `sync` sections):

```bash
claude plugin install my-new-plugin@my-env --scope user
```

4. Push and update:

```bash
git add -A && git commit -m "add: my-new-plugin" && git push
claude plugin marketplace update my-env
claude plugin install my-new-plugin@my-env --scope user
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
