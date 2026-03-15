# Monorepo Consolidation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Consolidate claude-misc and claude-squad into claude-env as a monorepo with independent plugins under `plugins/`.

**Architecture:** Each plugin lives in `plugins/<name>/` with its own `.claude-plugin/plugin.json`. The root `marketplace.json` uses relative paths (`"./plugins/<name>"`) to reference them. No git subtree — direct file copy.

**Tech Stack:** Bash, JSON, Git

**Design doc:** `docs/plans/2026-03-15-monorepo-consolidation-design.md`

---

### Task 1: Copy misc plugin files

**Files:**
- Create: `plugins/misc/` (entire directory tree from `D:\Code\claude-misc`)

**Step 1: Create plugins directory and copy misc**

```bash
mkdir -p plugins/misc
```

**Step 2: Copy all plugin files (excluding .git)**

```bash
# From claude-env root
cp -r /d/Code/claude-misc/.claude-plugin plugins/misc/
cp -r /d/Code/claude-misc/skills plugins/misc/
cp -r /d/Code/claude-misc/commands plugins/misc/
cp /d/Code/claude-misc/CLAUDE.md plugins/misc/
cp /d/Code/claude-misc/README.md plugins/misc/
```

**Step 3: Verify structure**

```bash
find plugins/misc -type f | sort
```

Expected: `.claude-plugin/plugin.json`, `CLAUDE.md`, `README.md`, 5 `SKILL.md` files, 1 `battle.md`, `.gitkeep`

**Step 4: Commit**

```bash
git add plugins/misc/
git commit -m "feat: import misc plugin from claude-misc repo"
```

---

### Task 2: Copy squad plugin files

**Files:**
- Create: `plugins/squad/` (entire directory tree from `D:\Code\claude-squad`)

**Step 1: Copy all plugin files (excluding .git and .claude/squad runtime state)**

```bash
cp -r /d/Code/claude-squad/.claude-plugin plugins/squad/
cp -r /d/Code/claude-squad/skills plugins/squad/
cp -r /d/Code/claude-squad/commands plugins/squad/
cp -r /d/Code/claude-squad/hooks plugins/squad/
cp -r /d/Code/claude-squad/config plugins/squad/
cp -r /d/Code/claude-squad/scripts plugins/squad/
cp -r /d/Code/claude-squad/docs plugins/squad/
cp /d/Code/claude-squad/CLAUDE.md plugins/squad/
cp /d/Code/claude-squad/README.md plugins/squad/
cp /d/Code/claude-squad/CHANGELOG.md plugins/squad/
cp /d/Code/claude-squad/LICENSE plugins/squad/
```

**Step 2: Remove squad's own marketplace.json (marketplace lives at root)**

```bash
rm plugins/squad/.claude-plugin/marketplace.json
```

Only `plugin.json` should remain in `plugins/squad/.claude-plugin/`.

**Step 3: Verify structure**

```bash
find plugins/squad -type f | head -30
```

Expected: `plugin.json` (no marketplace.json), 7 skills, 1 command, hooks.json, config files, scripts, docs.

**Step 4: Commit**

```bash
git add plugins/squad/
git commit -m "feat: import squad plugin from claude-squad repo"
```

---

### Task 3: Update marketplace.json to use relative paths

**Files:**
- Modify: `.claude-plugin/marketplace.json`

**Step 1: Replace marketplace.json content**

```json
{
  "name": "my-env",
  "owner": {
    "name": "EndeavorYen"
  },
  "plugins": [
    {
      "name": "squad",
      "source": "./plugins/squad",
      "description": "Self-evolving agent team orchestrator"
    },
    {
      "name": "misc",
      "source": "./plugins/misc",
      "description": "Personal miscellaneous skills and commands"
    }
  ]
}
```

**Step 2: Commit**

```bash
git add .claude-plugin/marketplace.json
git commit -m "refactor: switch marketplace sources from github to relative paths"
```

---

### Task 4: Update .gitignore

**Files:**
- Modify: `.gitignore`

**Step 1: Add squad runtime state exclusions**

Append to `.gitignore`:

```
# Squad runtime state (generated per-project, not tracked)
plugins/squad/.claude/
```

The `.battle_state.yaml` rule already exists at root level. Battle memory files (`.battle_memory.yaml`, `.battle_archive.md`) are tracked intentionally — they stay at root.

**Step 2: Commit**

```bash
git add .gitignore
git commit -m "chore: add squad runtime state to gitignore"
```

---

### Task 5: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

**Step 1: Update architecture section**

Replace the current architecture description to reflect monorepo structure:

- Change "不含原始碼" → "包含所有自己開發的 plugin 原始碼"
- Update directory tree to show `plugins/` structure
- Update "檔案說明" table to include `plugins/`
- Update "新增 plugin" section: source 格式從 GitHub 改為相對路徑
- Remove "不要把 plugin 原始碼放在這個 repo" 注意事項
- Add: plugin 各自獨立版本管理

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md for monorepo architecture"
```

---

### Task 6: Update README.md

**Files:**
- Modify: `README.md`

**Step 1: Update architecture diagram and description**

- Update "What's Inside" tree to show `plugins/` directory
- Update "Plugin Sources" diagram: remove separate repos, show monorepo structure
- Update "Added a new custom plugin" section: use relative path source format
- Add "Adding a New Plugin" section with the full workflow from design doc
- Update plugin count references

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: update README for monorepo architecture"
```

---

### Task 7: Verify plugin installation works

**Step 1: Update marketplace**

```bash
claude plugin marketplace update my-env
```

**Step 2: Reinstall plugins**

```bash
claude plugin install squad@my-env --scope user
claude plugin install misc@my-env --scope user
```

**Step 3: Verify**

Start a new Claude Code session and verify both plugins load (skills appear in available skills list).

If relative paths don't resolve correctly, fallback: keep GitHub source format but point all to `EndeavorYen/claude-env` with a `path` field if supported, or use `git-subdir` source type.

---

### Task 8: Archive original repos

**Step 1: Update README in claude-misc**

Add deprecation notice at the top of `D:\Code\claude-misc\README.md`:

```markdown
> ⚠️ **Archived** — This plugin has been consolidated into [claude-env](https://github.com/EndeavorYen/claude-env/tree/main/plugins/misc). All future development happens there.
```

Commit and push.

**Step 2: Update README in claude-squad**

Add deprecation notice at the top of `D:\Code\claude-squad\README.md`:

```markdown
> ⚠️ **Archived** — This plugin has been consolidated into [claude-env](https://github.com/EndeavorYen/claude-env/tree/main/plugins/squad). All future development happens there.
```

Commit and push.

**Step 3: Archive repos on GitHub**

```bash
gh repo archive EndeavorYen/claude-misc --yes
gh repo archive EndeavorYen/claude-squad --yes
```

---

### Task 9: Final commit and push

**Step 1: Push all changes**

```bash
git push origin main
```

**Step 2: Verify marketplace update works from remote**

```bash
claude plugin marketplace update my-env
claude plugin install squad@my-env --scope user
claude plugin install misc@my-env --scope user
```
