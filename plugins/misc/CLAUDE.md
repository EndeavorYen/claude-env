# claude-misc — 個人雜項 Skills & Commands 集合

## 這是什麼

這是一個 Claude Code plugin，收納不屬於任何特定 plugin 的零散 skills 和 commands。透過 [claude-env](https://github.com/EndeavorYen/claude-env) umbrella marketplace 安裝。

可以把它想像成一個工具箱 — 裡面放各種隨手可用的小工具，不需要為每個小 skill 都建一個獨立 repo。

## 工作準則

- **禁止敷衍或 workaround**：遇到問題時必須追查 root cause，不可以用「這是預期行為」「這只是 noise」等說法搪塞。如果當下無法確認，應該先驗證再回答，而非猜測一個看似合理的答案。
- **驗證優先於推測**：對任何異常現象（error log、非預期結果、edge case），先用程式碼或指令實際驗證，確認事實後再下結論。
- **質疑答案，不斷省思** : 會思考這就是最好的答案? 我已經拿出全力了? 還能夠更好嗎? 還有更好的答案嗎?

## Markdown 寫作原則

所有 Markdown 輸出（文件、對話回覆、comment）請以可讀性與可維護性為優先。

### 優先級

- **Repo 既有規範優先**：若專案已有 style guide、CONTRIBUTING、lint 規則或既有語氣，優先遵守。
- **本檔規範是預設 heuristics，不是硬性法律**：可依文件型態（README/API/教學/runbook）調整。

### Spacing（預設）

- Heading、段落、list、table、code block 之間留一行空行
- `---` 僅用於主要邏輯轉折，不要每段都加
- 避免大段無換行的文字牆

### Density（預設）

- 一段盡量聚焦一個主題，過長就拆段
- 長列表可加小節分組
- 比較資訊優先用 table，流程說明優先用段落
- 巢狀過深時重構結構，不強制固定層數

### Emphasis（預設）

- `Code` 用於路徑、指令、函式、設定鍵
- **Bold** 用於真正重要詞，避免整段過度加粗
- 避免每個 list item 都以 **Bold** 起手，除非它本身是掃描型列表（如 feature/definition list）

### 可驗證品質門檻

- 能跑檢查就跑：例如 `markdownlint`、link checker
- 不能跑檢查時，明確標示哪些連結/指令尚未工具驗證
- 交付前至少確認：
  - 開頭有說明「這是什麼、為什麼重要」
  - 只看標題也能理解文件結構
  - 指令與範例具備可複製性

## 結構

```
claude-misc/
├── .claude-plugin/
│   └── plugin.json          ← Plugin manifest（name: "misc"）
├── skills/
│   ├── skill-a/
│   │   └── SKILL.md         ← 一個 skill = 一個目錄 + SKILL.md
│   └── skill-b/
│       └── SKILL.md
├── commands/
│   └── command-a.md          ← 一個 command = 一個 .md 檔
└── CLAUDE.md
```

## 開發慣例

### 新增 Skill

1. 在 `skills/` 下建立目錄，名稱用 kebab-case：

```
skills/my-new-skill/SKILL.md
```

2. SKILL.md 必須包含 YAML frontmatter：

```markdown
---
name: my-new-skill
description: >
  觸發條件描述。寫清楚 WHEN to trigger，包含關鍵詞。
  例如：Use when the user says "do X", "run Y", "幫我Z".
---

## Instructions

Claude 收到觸發時該做什麼。
```

3. **description 是最重要的欄位** — 它決定 Claude 何時自動觸發這個 skill。請同時寫清楚「何時要觸發」與「何時不要觸發」（negative triggers），避免誤觸或漏觸。

### 新增 Command

1. 在 `commands/` 下建立 `.md` 檔：

```
commands/my-command.md
```

2. 必須包含 YAML frontmatter：

```markdown
---
name: my-command
description: /my-command 做什麼
arguments:
  - name: target
    description: 操作目標
    required: true
---

## Instructions

使用者執行 /my-command <target> 時 Claude 該做什麼。
```

### Skill vs Command 判斷

| 特性 | Skill | Command |
|------|-------|---------|
| 觸發方式 | Claude 自動判斷 | 使用者手動 `/command` |
| 適合 | 流程型（review, verify） | 動作型（commit, deploy） |
| 有參數 | 通常沒有 | 可以有 arguments |

### 發布更新

```bash
git add -A && git commit -m "add: my-new-skill" && git push
```

其他機器更新：

```bash
claude plugin marketplace update my-env
```

## 注意事項

- **Plugin name 是 `misc`** — 安裝指令：`claude plugin install misc@my-env --scope user`
- **Skill 目錄名 = skill name** — 保持一致，用 kebab-case
- **支援中英文觸發詞** — description 裡寫兩種語言的關鍵詞可以提高觸發率
- **每個 skill 只做一件事** — 如果一個 skill 變太大，考慮拆成獨立 plugin
- **可以放 helper 檔案** — skill 目錄下可以放額外的 `.md` 或腳本，SKILL.md 中引用它們
