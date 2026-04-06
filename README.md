# claude-env

My Claude Code development environment. One repo to restore everything on any machine.

## What's Inside

```
claude-env/
├── plugins/
│   ├── squad/                 ← in-repo: Self-evolving agent team orchestrator
│   ├── misc/                  ← in-repo: Personal miscellaneous skills & commands
│   └── battle/                ← in-repo: Adversarial quality battle system
├── .claude-plugin/
│   └── marketplace.json       ← Points to plugins (in-repo paths or external URLs)
├── settings.json              ← Environment snapshot (plugins + permissions + preferences)
├── mcp.template.json          ← MCP server config template
└── install.sh                 ← Setup and sync tool
```

## Architecture

### Config Topology

Claude Code reads configuration from multiple layers. This repo manages the global layer:

```
Layer 1: Global (this repo manages)
  ~/.claude/settings.json
  ├── enabledPlugins       26 official enabled + 4 custom
  ├── extraKnownMarketplaces
  ├── permissions          allow/deny rules (single source of truth)
  ├── autoUpdatesChannel
  └── effortLevel

Layer 2: Per-project (NOT managed by this repo)
  <project>/.mcp.json      MCP server configs
```

**MCP servers are per-project**: This repo provides `mcp.template.json` as a starting point, but actual `.mcp.json` files live in each project and are gitignored (they may contain tokens).

### Plugin Sources

Plugins can be sourced two ways in `marketplace.json`:

| Type | Example | When to use |
|------|---------|-------------|
| **In-repo** (relative path) | `"source": "./plugins/squad"` | Small/personal plugins that live in this repo |
| **External URL** | `"source": {"source": "url", "url": "https://..."}` | Independently maintained plugins in their own repos |

`chrome-cdp-ex` uses the URL source type — it's fetched directly from its own repo when the marketplace is updated, with no submodule needed.

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
4. Install custom plugins (squad, misc, battle, chrome-cdp-ex)
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
3. Add to `.claude-plugin/marketplace.json`:
   ```json
   { "name": "<name>", "source": "./plugins/<name>", "description": "What it does" }
   ```
4. Add `"<name>"` to the `CUSTOM_PLUGINS` array in `install.sh`
5. Add `"<name>@my-env": true` to `settings.json`'s `enabledPlugins`

#### Option B: External repo via URL (for independently maintained plugins)

1. Add to `.claude-plugin/marketplace.json`:
   ```json
   {
     "name": "<name>",
     "source": { "source": "url", "url": "https://github.com/<owner>/<repo>.git" },
     "description": "What it does"
   }
   ```
2. Add `"<name>"` to the `CUSTOM_PLUGINS` array in `install.sh`
3. Add `"<name>@my-env": true` to `settings.json`'s `enabledPlugins`
4. Push — the marketplace update step in `install.sh` will fetch it automatically.

### Update all plugins to latest

```bash
claude plugin marketplace update my-env
claude plugin marketplace update claude-plugins-official
```

## Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
- Git with HTTPS access to GitHub (install.sh configures this automatically)
- `jq` (optional, for non-destructive settings merge during sync)
