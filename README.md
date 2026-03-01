# claude-env

My Claude Code development environment. One repo to restore everything on any machine.

## What's Inside

```
claude-env/
├── .claude-plugin/
│   └── marketplace.json   ← Points to all my custom plugin repos
├── settings.json          ← Full environment snapshot (plugins + MCP servers)
└── install.sh             ← One-command setup
```

## Architecture

```
                    claude-env (this repo)
                    Umbrella marketplace
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
         claude-squad  claude-misc   settings.json
         (own repo)    (own repo)    (official plugins
                                      + MCP servers)
```

- **Official plugins** (superpowers, hookify, etc.) — from `anthropics/claude-plugins-official`, managed via `settings.json`
- **My plugins** (squad, misc) — from my own repos, referenced in `marketplace.json`
- **MCP servers** (context7, greptile, playwright) — configured in `settings.json`

## New Machine Setup

```bash
git clone https://github.com/EndeavorYen/claude-env.git
cd claude-env
bash install.sh
```

That's it. Start a new Claude Code session and everything is ready.

## Daily Operations

### Environment changed (installed new plugin, changed MCP config, etc.)

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

2. Add install line to `install.sh`:

```bash
claude plugin install my-new-plugin@my-env --scope user
```

3. Push and update:

```bash
git add -A && git commit -m "add: my-new-plugin" && git push
claude plugin marketplace update my-env
claude plugin install my-new-plugin@my-env --scope user
```

### Sync on another machine

```bash
cd ~/claude-env && git pull
bash install.sh
```

### Update all plugins to latest

```bash
claude plugin marketplace update my-env
claude plugin marketplace update claude-plugins-official
```

## Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
- Git with HTTPS access to GitHub (install.sh configures this automatically)
