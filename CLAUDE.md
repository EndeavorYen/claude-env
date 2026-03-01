# claude-env — Claude Code 開發環境管理

## 這是什麼

這是一個 **umbrella marketplace repo** — 本身不含任何 plugin 原始碼，只做兩件事：

1. `marketplace.json` 指向所有自己開發的 plugin repos（統一入口）
2. `settings.json` 備份完整的 Claude Code 環境設定（一鍵還原）

就像 Linux 的 meta-package — `apt install build-essential` 本身沒有 gcc，只是一份依賴清單。

## 架構

```
claude-env (this repo)          ← 不含原始碼，只有指向
    │
    ├── marketplace.json        ← 指向各 plugin repos
    │   ├── → EndeavorYen/claude-squad    (agent team orchestrator)
    │   └── → EndeavorYen/claude-misc     (miscellaneous skills/commands)
    │
    ├── settings.json           ← 完整環境快照
    │   ├── enabledPlugins      (official 24 個 + 自己的)
    │   ├── mcpServers          (context7, greptile, playwright...)
    │   └── extraKnownMarketplaces
    │
    └── install.sh              ← 新機器一鍵安裝
```

## 檔案說明

| 檔案 | 用途 | 何時更新 |
|------|------|---------|
| `.claude-plugin/marketplace.json` | Plugin 目錄，指向各 GitHub repo | 新增/移除自己的 plugin repo 時 |
| `settings.json` | `~/.claude/settings.json` 的備份 | 環境變動時（裝新 plugin、改 MCP、改設定） |
| `install.sh` | 新機器安裝腳本 | marketplace.json 新增 plugin 時同步加 install 行 |

## 開發慣例

### 新增一個自己開發的 plugin repo

1. 在 `.claude-plugin/marketplace.json` 的 `plugins` 陣列加一筆：

```json
{
  "name": "new-plugin-name",
  "source": {
    "source": "github",
    "repo": "EndeavorYen/claude-new-plugin",
    "ref": "main"
  },
  "description": "What it does"
}
```

2. 在 `install.sh` 加一行：

```bash
claude plugin install new-plugin-name@my-env --scope user
```

3. Commit + push。

### 環境快照更新

```bash
cp ~/.claude/settings.json ./settings.json
git add settings.json && git commit -m "update: env snapshot" && git push
```

### 注意事項

- **不要把 plugin 原始碼放在這個 repo** — 每個 plugin 有自己的 repo
- **settings.json 可能含敏感資訊**（MCP server tokens）— 如果 repo 公開，注意脫敏
- **marketplace name 是 `my-env`** — 所有 plugin 安裝時用 `@my-env` 後綴
- **GitHub 存取用 HTTPS** — install.sh 會自動設定 `git config --global url."https://github.com/".insteadOf "git@github.com:"`
