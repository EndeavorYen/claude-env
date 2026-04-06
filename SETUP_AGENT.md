# Claude Code Environment — Agent Setup Guide

## 這份文件的用途

這份文件專為 agent（Claude）設計。當你在一台新機器上讀到這份文件，代表你需要還原 EndeavorYen 的 Claude Code 開發環境。請依照下方步驟逐一執行。

**適用情境：**
- 全新機器首次安裝 → 執行 [Setup 模式](#setup-模式全新安裝)
- 已有 Claude Code 環境、需要同步最新設定 → 執行 [Sync 模式](#sync-模式同步更新)

---

## Prerequisites

執行前確認以下條件均已滿足：

| 條件 | 確認方式 |
|------|---------|
| Claude Code CLI 已安裝 | `claude --version` 有輸出 |
| git 可用 | `git --version` 有輸出 |
| 網路可連 GitHub | `curl -s https://github.com` 有回應 |
| jq 可用（可選） | `jq --version`；沒有也可以，sync 時 settings 用覆蓋策略 |

若 Claude Code CLI 尚未安裝，請先參考官方文件安裝後再繼續。

---

## Setup 模式（全新安裝）

### Step 1 — Clone 這個 repo

```bash
git clone https://github.com/EndeavorYen/claude-env.git
cd claude-env
```

### Step 2 — 執行安裝腳本

```bash
bash install.sh setup
```

這個指令會自動完成以下所有動作：

1. **Git HTTPS 設定** — 全域設定 `git@github.com:` → HTTPS rewrite，避免 SSH key 問題
2. **Marketplace 註冊** — 將 `my-env` marketplace 加到 Claude Code
3. **Settings 還原** — 將 `settings.json` 複製到 `~/.claude/settings.json`（若已存在會先備份）
4. **Custom plugins 安裝** — 安裝 squad、misc、battle、chrome-cdp-ex
5. **MCP template 部署** — 將 `mcp.template.json` 複製到 `~/.claude/mcp.template.json`

### Step 3 — 驗證安裝

```bash
claude plugin list
```

確認輸出包含以下 plugins（缺任何一個代表安裝有問題）：

**Custom plugins（my-env marketplace）：**
- `squad@my-env`
- `misc@my-env`
- `battle@my-env`
- `chrome-cdp-ex@my-env`

**Official plugins（claude-plugins-official）：**
- `superpowers@claude-plugins-official`
- `frontend-design@claude-plugins-official`
- `context7@claude-plugins-official`
- `code-review@claude-plugins-official`
- `feature-dev@claude-plugins-official`
- `code-simplifier@claude-plugins-official`
- `ralph-loop@claude-plugins-official`
- `typescript-lsp@claude-plugins-official`
- `playwright@claude-plugins-official`
- `commit-commands@claude-plugins-official`
- `security-guidance@claude-plugins-official`
- `pr-review-toolkit@claude-plugins-official`
- `claude-md-management@claude-plugins-official`
- `pyright-lsp@claude-plugins-official`
- `agent-sdk-dev@claude-plugins-official`
- `claude-code-setup@claude-plugins-official`
- `plugin-dev@claude-plugins-official`
- `explanatory-output-style@claude-plugins-official`
- `learning-output-style@claude-plugins-official`
- `greptile@claude-plugins-official`
- `hookify@claude-plugins-official`
- `rust-analyzer-lsp@claude-plugins-official`
- `skill-creator@claude-plugins-official`
- `semgrep@claude-plugins-official`
- `qodo-skills@claude-plugins-official`
- `github@claude-plugins-official`

---

## Sync 模式（同步更新）

已有環境、只需同步最新設定時：

```bash
cd claude-env
git pull
bash install.sh sync
```

Sync 模式的行為：
- **Marketplace** — 更新 `my-env` registry
- **Settings** — 若有 jq，用 array-union 策略合併（repo + local 規則都保留）；沒有 jq 則備份後覆蓋
- **Custom plugins** — 重裝（idempotent，安全重複執行）
- **MCP template** — 更新 `~/.claude/mcp.template.json`

---

## 安裝內容說明

### Custom Plugins

| Plugin | 版本 | 功能 |
|--------|------|------|
| **squad** | 0.3.0 | Self-evolving agent team orchestrator。`/squad "objective"` 啟動 7-stage pipeline（RECON→PLAN→EXECUTE→INTEGRATE→VERIFY→DEBRIEF→RETRO），支援 convoy 部署、gate levels、持續演化知識庫 |
| **misc** | 0.3.0 | 個人零散 skills 集合。包含：`code-review`、`write-doc`、`verify`、`challenge`、`test-gen`、`scaffold-feature`、`design-check` |
| **battle** | 0.1.0 | 紅白隊攻防品質對抗。`/battle` 觸發 RED（攻擊）+ WHITE（防守）+ JUDGE（裁決）三角色對抗，支援 `/loop` 持續執行 |
| **chrome-cdp-ex** | — | Chrome CDP 瀏覽器自動化。截圖、DOM 檢查、表單操作、console 監控，連接本機 Chrome session |

### Official Plugins 說明

| Plugin | 功能摘要 |
|--------|---------|
| superpowers | 多 agent 編排、planning、debugging、TDD、code review 等工作流 skill 集合 |
| frontend-design | 高品質前端 UI 生成 |
| context7 | 即時抓取外部 library 文件（React、Next.js 等），提供 MCP tools |
| code-review | PR 程式碼審查 |
| feature-dev | 引導式功能開發，含 codebase 理解與架構規劃 |
| code-simplifier | 重構程式碼使其更清晰簡潔 |
| ralph-loop | 自我迭代執行迴圈，直到任務完成 |
| typescript-lsp | TypeScript Language Server 整合 |
| playwright | Playwright 瀏覽器自動化，提供 MCP tools |
| commit-commands | `/commit`、`/commit-push-pr` 等 git 指令 |
| security-guidance | 安全漏洞偵測指引 |
| pr-review-toolkit | PR 全面審查工具組（code、test、type、silent failure） |
| claude-md-management | CLAUDE.md 建立與改善工具 |
| pyright-lsp | Python Pyright Language Server 整合 |
| agent-sdk-dev | Claude Agent SDK 應用開發工具 |
| claude-code-setup | Claude Code 自動化設定建議 |
| plugin-dev | Plugin 開發工具（skill、command、hook、agent） |
| explanatory-output-style | 輸出風格：教育性解說模式 |
| learning-output-style | 輸出風格：互動學習模式 |
| greptile | Greptile codebase 搜尋整合，提供 MCP tools |
| hookify | 建立 hooks 防止不想要的行為 |
| rust-analyzer-lsp | Rust Analyzer Language Server 整合 |
| skill-creator | 建立、修改、測試 skills |
| semgrep | Semgrep 靜態分析整合 |
| qodo-skills | Qodo PR review 整合 |
| github | GitHub CLI 整合 |

---

## Settings 說明

還原後的 `~/.claude/settings.json` 包含：

### 全域行為設定

```json
{
  "effortLevel": "max",
  "autoUpdatesChannel": "latest"
}
```

- `effortLevel: max` — Claude 以最高思考深度回應
- `autoUpdatesChannel: latest` — 自動更新到最新版

### Permissions

**Allow（自動核准，不需使用者確認）：**

| 規則 | 說明 |
|------|------|
| `Bash(*)` | 所有 shell 指令（rm 系列例外，見 deny） |
| `Read` / `Write` / `Edit` / `Glob` / `Grep` | 檔案操作全部自動允許 |
| `WebFetch` / `WebSearch` | 網路查詢自動允許 |
| `TodoWrite` / `NotebookEdit` / `Agent` / `Skill` | 工具操作自動允許 |
| `mcp__plugin_context7_context7__*` | context7 MCP tools 全部允許 |
| `mcp__plugin_greptile_greptile__*` | greptile MCP tools 全部允許 |
| `mcp__plugin_playwright_playwright__*` | playwright MCP tools 全部允許 |

**Deny（永遠拒絕）：**

```
rm、rmdir、del、Remove-Item
rm -rf、rm -r、rm -f
指令鏈中含 rm（| rm、&& rm、; rm）
```

---

## MCP Server 設定

### Plugin 提供的 MCP（自動，無需設定）

以下 MCP tools 在安裝對應 plugin 後自動可用：

| MCP Tools | 來源 Plugin |
|-----------|------------|
| `mcp__plugin_context7_context7__*` | context7 |
| `mcp__plugin_playwright_playwright__*` | playwright |
| `mcp__plugin_greptile_greptile__*` | greptile |

### 專案級 MCP（需手動設定）

若特定專案需要額外 MCP server（例如 Serena），請使用 template：

```bash
cp ~/.claude/mcp.template.json /path/to/project/.mcp.json
```

然後編輯 `.mcp.json`，在 `mcpServers` 中加入該專案需要的 server 設定。

**注意：**
- `.mcp.json` 可能含有 tokens，不應進版控
- 不同專案可以有不同的 MCP server 設定
- `mcp.template.json` 是無 token 的起點範本

---

## Troubleshooting

### `claude plugin marketplace add` 失敗

```bash
# 改用 update（marketplace 可能已存在）
claude plugin marketplace update my-env
```

### Plugin 安裝失敗

```bash
# 單獨安裝特定 plugin
claude plugin install squad@my-env --scope user
claude plugin install misc@my-env --scope user
claude plugin install battle@my-env --scope user
claude plugin install chrome-cdp-ex@my-env --scope user
```

### Settings 沒有生效

確認 `~/.claude/settings.json` 存在且內容正確：

```bash
cat ~/.claude/settings.json
```

若不存在，手動複製：

```bash
cp /path/to/claude-env/settings.json ~/.claude/settings.json
```

### Sync 後 permissions 遺失

Sync 模式在有 jq 時會做 array-union 合併（兩邊規則都保留）。若沒有 jq 則直接覆蓋。安裝 jq 後重新 sync 可確保安全合併：

```bash
# macOS
brew install jq
# Ubuntu/Debian
apt-get install jq
# Windows (scoop)
scoop install jq

bash install.sh sync
```

---

## Machine-Specific Plugins（需手動安裝）

以下 plugins 因為依賴本機路徑或 OS 特定設定，**不會被 `install.sh` 自動安裝**。
setup/sync 完成後，請提醒使用者依需求手動安裝：

| Plugin | 功能 | 安裝指令 | 備註 |
|--------|------|---------|------|
| **oh-my-claudecode** | Status line HUD & theme 客製化 | `claude plugin marketplace add https://github.com/Yeachan-Heo/oh-my-claudecode.git` → `claude plugin install oh-my-claudecode@omc --scope user` | 安裝後需在 `~/.claude/settings.json` 設定 `statusLine`（路徑因 OS 而異），詳見 [oh-my-claudecode repo](https://github.com/Yeachan-Heo/oh-my-claudecode) |

**Agent 注意事項：**
- `install.sh` 結束後會印出 machine-specific plugins 清單，請逐一提醒使用者
- `statusLine` 的 `command` 路徑是 OS 相關的（macOS: `~/.claude/...`, Windows: `C:/Users/<user>/.claude/...`），不要硬寫
- 這些 plugin 的 marketplace 已在 `settings.json` 的 `extraKnownMarketplaces` 中預登錄

---

## 完成後驗證

開一個新的 Claude Code session，確認：

1. `/squad help` 有回應
2. `/battle` 指令存在
3. `context7` MCP tools 可用（在 session 中詢問任何 library 文件）
4. Settings 中 `effortLevel` 為 `max`

所有項目通過代表環境還原成功。
