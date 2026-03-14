# Claude Code — 新環境設定手冊

> 照做一次，所有工具免確認、Serena 語義導航正常、MCP 最佳化。

---

## Step 1：安裝

```bash
# Claude Code
npm install -g @anthropic-ai/claude-code

# uv（Serena 需要）
# Windows
winget install astral-sh.uv
# macOS/Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# 驗證
claude --version
uvx --version
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
| `enabledPlugins` | 26 個 official plugin 啟用 + serena 停用（改用 .mcp.json）+ 2 個 custom |
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

或手動建立：

```json
{
  "mcpServers": {
    "serena": {
      "command": "uvx",
      "args": [
        "--from", "git+https://github.com/oraios/serena",
        "serena", "start-mcp-server",
        "--context", "claude-code",
        "--project-from-cwd"
      ]
    }
  }
}
```

`--context claude-code` → 隱藏重複工具，省 ~1,200 tokens/對話。
`--project-from-cwd` → 自動 activate 專案，不用手動呼叫。

### 3b. `.serena/project.yml`

```yaml
project_name: "Your-Project-Name"
languages:
- python        # 主語言放第一（fallback）
- typescript    # JavaScript 也用這個
encoding: "utf-8"
ignore_all_files_in_gitignore: true
ignored_paths: []
read_only: false
excluded_tools: []
included_optional_tools: []
fixed_tools: []
```

語言對照：JavaScript → `typescript`、C → `cpp`、Free Pascal → `pascal`。

### 3c. `.gitignore` 加一行

```gitignore
# --- MCP ---
.mcp.json
```

---

## Step 4：Serena Onboarding

開**新對話**（MCP server 只在對話啟動時啟動），依序執行：

```
1. 呼叫 get_current_config
   → 確認 active_project 有值、context = claude-code

2. 呼叫 check_onboarding_performed
   → 如果 false，繼續下一步

3. 呼叫 onboarding
   → Serena 掃描專案，結果存入 .serena/memories/

4. 開新對話（onboarding 吃很多 context）
```

---

## Step 5：驗證

在新對話中跑三個測試：

| 測試 | 操作 | 預期結果 |
|------|------|---------|
| Serena | `find_symbol` 搜一個已知的 class/function | 返回檔案位置和定義 |
| Context7 | 問一個 library 文件問題 | 自動查詢最新文件 |
| 權限 | 隨便用幾個工具（Read、Bash、Edit、Agent） | 全部免確認 |

全部通過 = 設定完成。

---

## 踩坑備忘

### MCP 工具前綴

改安裝方式後，permissions 裡的前綴必須跟著改：

```
Plugin 安裝 → mcp__plugin_serena_serena__*
.mcp.json  → mcp__serena__*     ← 我們用這個
```

前綴錯 = 每次呼叫都要手動確認，跟沒設權限一樣。

### Config Topology

```
全域層（本 repo 管理）
  ~/.claude/settings.json     ← install.sh 還原，permissions 唯一 source of truth

專案層（各專案自己管）
  <project>/.mcp.json         ← MCP server 設定，可能含 tokens，不進版控
  <project>/.serena/          ← Serena 專案設定 + memories
```

- **permissions 全部在 settings.json** — 不需要 settings.local.json
- **MCP 設定在各專案的 .mcp.json** — 用 mcp.template.json 作為起點
- settings.json 和 settings.local.json 的 permissions 會**合併**，但為了避免分裂，我們把所有規則集中在 settings.json

### Serena 靜默失敗

Serena 在沒 activate 專案時**不報錯**，只是返回空結果。如果 `find_symbol` 什麼都找不到：

```
1. get_current_config → 看 active_project 是不是空的
2. 空的 → 檢查 .mcp.json 有沒有 --project-from-cwd
3. 有值但找不到 → 檢查 project.yml 的 languages 有沒有列對
4. 都對 → restart_language_server
```

### Windows 編碼

所有 `read_text()` / `write_text()` 必須加 `encoding="utf-8"`。
所有 `subprocess.run(text=True)` 必須加 `encoding="utf-8", errors="replace"`。
不加的話 Windows 會用 cp950，CJK 字元全部亂碼。
