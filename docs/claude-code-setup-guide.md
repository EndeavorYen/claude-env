# Claude Code — 新環境設定手冊

> 照做一次，所有工具免確認、MCP 最佳化。

---

## Step 1：安裝

```bash
# Claude Code
npm install -g @anthropic-ai/claude-code

# 驗證
claude --version
```

---

## Step 2：全域設定

### 使用 install.sh 一鍵設定

```bash
git clone https://github.com/EndeavorYen/claude-env.git
cd claude-env
bash install.sh setup
```

這會自動完成：
- 設定 git HTTPS
- 註冊 umbrella marketplace
- 還原 `~/.claude/settings.json`（含完整 permissions）
- 安裝 custom plugins（squad, misc）

### settings.json 包含什麼

| 區塊 | 內容 |
|------|------|
| `enabledPlugins` | 26 個 official plugin 啟用 + custom plugins |
| `permissions.allow` | Bash、Read、Write、Edit、Glob、Grep、WebFetch、WebSearch、TodoWrite、NotebookEdit、Agent、Skill + MCP 工具 |
| `permissions.deny` | 完整的刪除防護（含管道組合 `*\| rm *`、`*&& rm *`、`*; rm *` 等） |
| `autoUpdatesChannel` | latest |
| `effortLevel` | max |

**permissions 的唯一 source of truth 是 `settings.json`**。不需要另外維護 `settings.local.json`。所有權限（包括 Agent、Skill、完整的 deny 規則）都已合併在這一個檔案裡。

---

## Step 3：專案級設定

以下在專案根目錄操作。

### 3a. `.mcp.json`（MCP Server 設定）

從 claude-env repo 複製範本：

```bash
cp ~/claude-env/mcp.template.json /path/to/project/.mcp.json
```

然後在 `.mcp.json` 裡加入你需要的 MCP server 設定。

### 3b. `.gitignore` 加一行

```gitignore
# --- MCP ---
.mcp.json
```

---

## Step 4：驗證

在新對話中跑測試：

| 測試 | 操作 | 預期結果 |
|------|------|---------|
| Context7 | 問一個 library 文件問題 | 自動查詢最新文件 |
| 權限 | 隨便用幾個工具（Read、Bash、Edit、Agent） | 全部免確認 |

全部通過 = 設定完成。

---

## 踩坑備忘

### MCP 工具前綴

不同安裝方式會產生不同的工具前綴，permissions 裡的前綴必須跟著改：

```
Plugin 安裝 → mcp__plugin_<name>_<name>__*
.mcp.json  → mcp__<name>__*
```

前綴錯 = 每次呼叫都要手動確認，跟沒設權限一樣。

### Config Topology

```
全域層（本 repo 管理）
  ~/.claude/settings.json     ← install.sh 還原，permissions 唯一 source of truth

專案層（各專案自己管）
  <project>/.mcp.json         ← MCP server 設定，可能含 tokens，不進版控
```

- **permissions 全部在 settings.json** — 不需要 settings.local.json
- **MCP 設定在各專案的 .mcp.json** — 用 mcp.template.json 作為起點
- settings.json 和 settings.local.json 的 permissions 會**合併**，但為了避免分裂，我們把所有規則集中在 settings.json

### Windows 編碼

所有 `read_text()` / `write_text()` 必須加 `encoding="utf-8"`。
所有 `subprocess.run(text=True)` 必須加 `encoding="utf-8", errors="replace"`。
不加的話 Windows 會用 cp950，CJK 字元全部亂碼。
