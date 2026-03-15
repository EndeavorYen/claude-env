# claude-env — Claude Code 開發環境管理

## 這是什麼

這是一個 **monorepo** — plugin 原始碼和環境設定都在這裡：

1. `plugins/` 包含所有自己開發的 plugin 原始碼
2. `marketplace.json` 指向 `plugins/` 子目錄（本地相對路徑）
3. `settings.json` 備份完整的 Claude Code 環境設定（一鍵還原）

## 架構

```
claude-env (this repo)          ← monorepo：plugin 原始碼 + 環境設定
    │
    ├── plugins/                ← 所有自己開發的 plugin
    │   ├── squad/              (agent team orchestrator)
    │   ├── misc/               (miscellaneous skills/commands)
    │   └── battle/             (red-white adversarial quality battle)
    │
    ├── .claude-plugin/
    │   └── marketplace.json    ← 指向 plugins/ 子目錄（相對路徑）
    │
    ├── settings.json           ← 完整環境快照
    │   ├── enabledPlugins      (26 official enabled + 1 disabled + 3 custom)
    │   ├── extraKnownMarketplaces
    │   ├── permissions         (allow/deny — 權限的唯一 source of truth)
    │   ├── autoUpdatesChannel
    │   └── effortLevel
    │
    ├── mcp.template.json       ← MCP server 設定範本（install.sh 部署到 ~/.claude/）
    │
    └── install.sh              ← 安裝/同步工具（setup 和 sync 兩種模式）
```

## Config Topology

Claude Code 的設定分兩層，這個 repo 只管全域層：

| 層級 | 檔案 | 由誰管理 | 說明 |
|------|------|---------|------|
| **全域** | `~/.claude/settings.json` | 本 repo（`install.sh` 還原） | plugins、permissions、preferences |
| **專案級** | `<project>/.mcp.json` | 各專案自己管 | MCP server 設定（serena 等），可能含 tokens |
| **專案級** | `<project>/.serena/` | 各專案自己管 | Serena 專案設定 + memories |

**為什麼 serena 在 enabledPlugins 裡是 `false`**：Serena 用 `.mcp.json` 方式更好（不同專案可以不同設定）。Plugin 版停用避免兩組 MCP server 同時啟動。詳見 [Serena setup guide](docs/serena-setup-guide.md)。

**MCP server 設定不在這個 repo 裡**：`.mcp.json` 是專案級檔案，可能含 tokens，不進版控。本 repo 提供 `mcp.template.json` 作為起點。

## 檔案說明

| 檔案 | 用途 | 何時更新 |
|------|------|---------|
| `plugins/` | 所有自己開發的 plugin 原始碼 | 新增/修改 plugin 時 |
| `.claude-plugin/marketplace.json` | Plugin 目錄，指向 `plugins/` 子目錄 | 新增/移除 plugin 時 |
| `settings.json` | `~/.claude/settings.json` 的備份（含完整 permissions） | 環境變動時（裝新 plugin、改權限、改設定） |
| `mcp.template.json` | `.mcp.json` 範本（install.sh 自動部署到 `~/.claude/`） | MCP server 設定變動時 |
| `install.sh` | 安裝/同步工具 | marketplace.json 新增 plugin 時同步加 install 行 |

## install.sh 使用方式

```bash
# 新機器首次安裝
bash install.sh setup

# 同步到已有的機器（非破壞性合併）
bash install.sh sync
```

- `setup`：完整安裝（git HTTPS 設定 + marketplace 註冊 + settings 還原 + plugin 安裝 + MCP template 部署）
- `sync`：同步更新（marketplace 更新 + settings 合併 + plugin 重裝 + MCP template 更新）
- sync 模式的 settings 合併策略（需 jq）：
  - 純量/物件 key：local 覆蓋 repo（`jq *` 語意）
  - `permissions.allow` / `permissions.deny`：**array union**（repo 和 local 的規則都保留，不會互相覆蓋）
  - 沒有 jq 時先備份再覆蓋
- 非互動環境（piped / CI / SSH without TTY）自動選擇模式，不會卡住等 input
- 所有步驟的錯誤都會顯示，不會被靜默吃掉

## 開發慣例

### 新增一個 plugin

1. 建立 plugin 目錄結構：

```bash
mkdir -p plugins/<name>/.claude-plugin
```

2. 在 `plugins/<name>/.claude-plugin/` 建立 `plugin.json` 以及對應的 skills/commands 檔案。

3. 在 `.claude-plugin/marketplace.json` 的 `plugins` 陣列加一筆：

```json
{
  "name": "new-plugin-name",
  "source": "./plugins/<name>",
  "description": "What it does"
}
```

4. 在 `settings.json` 的 `enabledPlugins` 加一行：

```json
"new-plugin-name@my-env": true
```

如果 plugin 提供 MCP tools，也要在 `permissions.allow` 加對應的 `mcp__` 規則。

5. 在 `install.sh` 的 setup 和 sync 兩個區塊都加一行：

```bash
claude plugin install new-plugin-name@my-env --scope user
```

6. Commit + push。

### 環境快照更新

```bash
cp ~/.claude/settings.json ./settings.json
git add settings.json && git commit -m "update: env snapshot" && git push
```

### 注意事項

- **每個 plugin 各自獨立版本管理** — 各自的 `plugin.json` version
- **settings.json 不含 MCP tokens** — MCP 設定在各專案的 `.mcp.json` 裡（已 gitignore）
- **permissions 的唯一 source of truth 是 settings.json** — 不要另外維護 settings.local.json
- **marketplace name 是 `my-env`** — 所有 plugin 安裝時用 `@my-env` 後綴
- **GitHub 存取用 HTTPS** — install.sh 會自動設定 `git config --global url."https://github.com/".insteadOf "git@github.com:"`
