# Serena MCP Server — Setup Guide for Claude Code

> 從踩坑到正確設定的完整指南。新環境照做一次即可。

## TL;DR

Serena 提供語義級程式碼導航（`find_symbol`、`find_referencing_symbols`、`get_symbols_overview`），比 Grep/Glob 精確得多。但它有三個隱性前提——少做任何一個，工具都會「靜默失敗」：返回空結果、不報錯、不亮燈。

---

## 安裝方式：Plugin vs `.mcp.json`

Serena 有兩種安裝途徑，差異如下：

| | Plugin（marketplace 安裝） | `.mcp.json`（專案級直裝） |
|---|---|---|
| 安裝方式 | `enabledPlugins` 裡啟用 | 專案根目錄放 `.mcp.json` |
| 工具前綴 | `mcp__plugin_serena_serena__*` | `mcp__serena__*` |
| 參數覆寫 | 需在 settings.json 用 `plugin:serena:serena` key 覆寫 | 直接在 `.mcp.json` 寫完整參數 |
| 作用範圍 | 全域（所有專案） | 僅該專案目錄 |
| 適合場景 | 想讓所有專案都用 Serena | 只有特定專案需要 |

**建議**：用 `.mcp.json` 方式。原因：
1. 參數直接寫在檔案裡，不需要覆寫 plugin cache
2. 不同專案可以有不同的 Serena 設定
3. `.mcp.json` 加進 `.gitignore`，不影響其他開發者

---

## Step 0：前置條件

```bash
# 確認 uvx 可用（uv 的工具執行器）
uvx --version

# 如果沒有，先裝 uv
# Windows: winget install astral-sh.uv
# macOS/Linux: curl -LsSf https://astral.sh/uv/install.sh | sh
```

---

## Step 1：建立 `.mcp.json`

在專案根目錄建立 `.mcp.json`：

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

### 兩個關鍵參數

| 參數 | 作用 | 不加的後果 |
|------|------|-----------|
| `--context claude-code` | 隱藏與 Claude Code 重複的工具（read_file、list_dir、execute_shell_command 等），工具數從 ~30 降到 ~19，每次對話省 ~1,200 tokens system prompt | 多出 ~6,000 tokens 的冗餘工具定義，擠壓有效 context |
| `--project-from-cwd` | 自動根據工作目錄 activate 專案 | 每次對話都要手動呼叫 `activate_project`，忘了的話所有語義工具靜默返回空結果 |

---

## Step 2：停用 Plugin 版（如果之前有裝）

在 `~/.claude/settings.json` 中：

```jsonc
{
  "enabledPlugins": {
    // 改為 false，避免 plugin 版和 .mcp.json 版同時啟動
    "serena@claude-plugins-official": false
  },
  "permissions": {
    "allow": [
      // 注意前綴變了！
      // Plugin 版: "mcp__plugin_serena_serena__*"
      // .mcp.json 版: "mcp__serena__*"
      "mcp__serena__*"
    ]
  }
}
```

> **命名規則**：Plugin 的工具前綴是 `mcp__plugin_<plugin>_<server>__`，`.mcp.json` 的是 `mcp__<server>__`。權限規則不改的話，新版工具每次都會彈確認框。

---

## Step 3：設定 `.serena/project.yml`

在專案根目錄建立 `.serena/project.yml`（如果還沒有的話）：

```yaml
project_name: "Your-Project-Name"

# 列出專案用到的所有程式語言
# JavaScript 用 typescript（同一個 LSP）
# C 用 cpp
languages:
- python
- typescript

encoding: "utf-8"

# Windows 專案建議明確設定
# line_ending: "crlf"   # 或 "lf" 如果用 git autocrlf

ignore_all_files_in_gitignore: true
ignored_paths: []
read_only: false
excluded_tools: []
```

### 語言選擇注意事項

- **JavaScript** → 用 `typescript`（TypeScript LSP 涵蓋 JS）
- **C** → 用 `cpp`
- **Free Pascal** → 用 `pascal`
- 第一個語言是 default fallback，建議放主要語言
- 完整語言列表見 [Serena Language Support](https://oraios.github.io/serena/01-about/020_programming-languages.html)

---

## Step 4：加 `.gitignore`

```gitignore
# --- MCP ---
.mcp.json
```

`.mcp.json` 包含個人的 MCP server 配置，不應進版控。

> `.serena/` 目錄建議**追蹤**，因為 `project.yml` 是專案共享設定，`memories/` 裡的架構知識對團隊有用。

---

## Step 5：Onboarding（首次設定）

**開一個新的 Claude Code 對話**（讓 Serena 以新參數啟動），然後依序執行：

### 5.1 驗證啟動狀態

```
→ 呼叫 get_current_config
```

確認輸出中：
- ✅ `active_project` 不是空的，顯示你的專案名稱
- ✅ `context` 顯示 `claude-code`
- ✅ 工具列表不包含 `read_file`、`list_dir` 等重複工具

### 5.2 檢查 Onboarding 狀態

```
→ 呼叫 check_onboarding_performed
```

- 如果回傳 `false`，繼續下一步
- 如果回傳 `true`，跳到 Step 6

### 5.3 執行 Onboarding

```
→ 呼叫 onboarding
```

Serena 會：
1. 掃描專案目錄結構
2. 辨識建置/測試指令
3. 記錄架構資訊到 `.serena/memories/`
4. 建立專案的語義索引

> ⚠️ Onboarding 蠻吃 context window。完成後**開一個新對話**再開始工作。

---

## Step 6：驗證語義功能

在新對話中測試：

```
→ 呼叫 find_symbol，搜尋你專案中已知的 class 或 function 名稱
→ 呼叫 get_symbols_overview，指定一個已知的 .py 或 .ts 檔案
```

如果能正確返回符號定義和位置，代表一切就緒。

---

## 常見問題排查

### Q: `find_symbol` 返回空結果

1. 確認 `get_current_config` 的 `active_project` 不是空的
2. 確認 `project.yml` 的 `languages` 有列出該檔案的語言
3. 試呼叫 `restart_language_server` 重啟 LSP

### Q: 工具呼叫需要手動確認

檢查 `~/.claude/settings.json` 的 `permissions.allow`，確認前綴正確：
- `.mcp.json` 方式 → `"mcp__serena__*"`
- Plugin 方式 → `"mcp__plugin_serena_serena__*"`

### Q: Serena 工具完全沒出現

1. 確認 `.mcp.json` 在專案根目錄
2. 確認 `uvx` 可用（`uvx --version`）
3. 開新對話（MCP server 只在對話開始時啟動）

### Q: Plugin 版和 .mcp.json 版衝突

不會衝突。Plugin 停用（`false`）後，只有 `.mcp.json` 的版本會啟動。如果兩個都啟用，會有兩組 Serena 工具（不同前綴），浪費 token。

---

## 設定文件速查

| 檔案 | 位置 | 用途 |
|------|------|------|
| `.mcp.json` | 專案根目錄 | Serena MCP server 啟動參數 |
| `.serena/project.yml` | 專案根目錄 | 語言、編碼、忽略路徑等專案設定 |
| `.serena/memories/` | 專案根目錄 | Onboarding 產生的專案知識（自動生成） |
| `~/.claude/settings.json` | 使用者家目錄 | Plugin 開關、權限規則 |

---

## Serena 語義工具速查（claude-code context 下）

| 工具 | 用途 | 何時用 |
|------|------|--------|
| `find_symbol` | 全域搜尋符號（class、function、variable） | 找定義、跳轉到實作 |
| `get_symbols_overview` | 列出檔案中的頂層符號 | 快速了解檔案結構，不需讀全檔 |
| `find_referencing_symbols` | 找出引用某符號的所有位置 | 重構前影響分析 |
| `replace_symbol_body` | 替換整個符號定義 | 重寫整個 function/method |
| `insert_before_symbol` / `insert_after_symbol` | 在符號前/後插入程式碼 | 新增 method、import 等 |
| `onboarding` | 掃描專案建立知識庫 | 首次設定、專案大幅變動後 |
| `read_memory` / `write_memory` | 讀寫專案記憶 | 跨對話保留架構知識 |
| `rename_symbol` | 語義級重新命名 | 比 find-replace 安全 |
| `restart_language_server` | 重啟 LSP | 外部編輯後語義功能失靈時 |

---

## 定期健檢清單

每隔一段時間（建議每月），花 5 分鐘確認：

- [ ] `get_current_config` → active project 正確嗎？
- [ ] `find_symbol` 隨便搜一個已知符號 → 有結果嗎？
- [ ] `.serena/project.yml` 的 languages → 跟專案實際使用的語言一致嗎？
- [ ] `~/.claude/settings.json` 的權限前綴 → 跟安裝方式匹配嗎？

> 靜默失敗最可怕。10 分鐘的健檢可能省下幾百萬 tokens 和無數次「奇怪為什麼找不到」的困惑。
