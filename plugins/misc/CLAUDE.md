# claude-misc — 個人雜項 Skills & Commands 集合

## 這是什麼

這是一個 Claude Code plugin，收納不屬於任何特定 plugin 的零散 skills 和 commands。透過 [claude-env](https://github.com/EndeavorYen/claude-env) umbrella marketplace 安裝。

可以把它想像成一個工具箱 — 裡面放各種隨手可用的小工具，不需要為每個小 skill 都建一個獨立 repo。

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

3. **description 是最重要的欄位** — 它決定 Claude 何時自動觸發這個 skill。寫不好 = 永遠不會被觸發。

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
