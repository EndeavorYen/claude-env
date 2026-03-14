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

### 2a. `~/.claude/settings.json`

整個檔案貼上：

```json
{
  "enabledPlugins": {
    "frontend-design@claude-plugins-official": true,
    "context7@claude-plugins-official": true,
    "code-review@claude-plugins-official": true,
    "github@claude-plugins-official": true,
    "feature-dev@claude-plugins-official": true,
    "code-simplifier@claude-plugins-official": true,
    "ralph-loop@claude-plugins-official": true,
    "playwright@claude-plugins-official": true,
    "commit-commands@claude-plugins-official": true,
    "security-guidance@claude-plugins-official": true,
    "pr-review-toolkit@claude-plugins-official": true,
    "claude-md-management@claude-plugins-official": true,
    "agent-sdk-dev@claude-plugins-official": true,
    "claude-code-setup@claude-plugins-official": true,
    "plugin-dev@claude-plugins-official": true,
    "explanatory-output-style@claude-plugins-official": true,
    "greptile@claude-plugins-official": true,
    "hookify@claude-plugins-official": true,
    "learning-output-style@claude-plugins-official": true,
    "skill-creator@claude-plugins-official": true,
    "squad@my-env": true,
    "superpowers@claude-plugins-official": true,
    "misc@my-env": true,
    "semgrep@claude-plugins-official": true,
    "serena@claude-plugins-official": false,
    "qodo-skills@claude-plugins-official": true
  },
  "extraKnownMarketplaces": {
    "my-env": {
      "source": {
        "source": "git",
        "url": "https://github.com/EndeavorYen/claude-env.git"
      }
    }
  },
  "autoUpdatesChannel": "latest",
  "effortLevel": "max",
  "permissions": {
    "allow": [
      "Bash(*)",
      "Read",
      "Write",
      "Edit",
      "Glob",
      "Grep",
      "WebFetch",
      "WebSearch",
      "TodoWrite",
      "NotebookEdit",
      "mcp__serena__*",
      "mcp__plugin_context7_context7__*",
      "mcp__plugin_playwright_playwright__*"
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(rm -r *)",
      "Bash(rmdir *)",
      "Bash(del *)",
      "Bash(rd *)"
    ]
  }
}
```

### 2b. `~/.claude/settings.local.json`

整個檔案貼上：

```json
{
  "permissions": {
    "allow": [
      "Bash(*)",
      "Read",
      "Write",
      "Edit",
      "Glob",
      "Grep",
      "WebFetch",
      "WebSearch",
      "NotebookEdit",
      "Agent",
      "TodoWrite",
      "Skill",
      "mcp__plugin_context7_context7__*",
      "mcp__plugin_playwright_playwright__*",
      "mcp__serena__*"
    ],
    "deny": [
      "Bash(rm:*)",
      "Bash(rmdir:*)",
      "Bash(del:*)",
      "Bash(Remove-Item:*)",
      "Bash(*rm -rf*)",
      "Bash(*rm -r *)",
      "Bash(*rm -f *)",
      "Bash(*| rm *)",
      "Bash(*&& rm *)",
      "Bash(*; rm *)"
    ]
  }
}
```

### 為什麼有兩個檔案？

| 檔案 | 差異 |
|------|------|
| `settings.json` | plugins + marketplace + 偏好 + 基本權限 |
| `settings.local.json` | 補充 `Agent`、`Skill` 權限 + 更完整的刪除防護（含管道組合） |

兩邊的 permissions 會**合併**，不會互相覆蓋。

---

## Step 3：專案級設定

以下在專案根目錄操作。

### 3a. `.mcp.json`（Serena MCP Server）

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
| 權限 | 隨便用幾個工具（Read、Bash、Edit） | 全部免確認 |

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

### settings.json vs settings.local.json

- 兩邊的 allow/deny **合併**，不是覆蓋
- Plugin 只能在 `settings.json` 裡設
- `settings.local.json` 不進版控，適合放機器特有的東西

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
