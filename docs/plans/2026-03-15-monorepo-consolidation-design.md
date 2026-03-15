# Monorepo Consolidation Design

**Date**: 2026-03-15
**Status**: Approved

## Problem

claude-misc 和 claude-squad 分散在三個 repo 維護，增加管理成本。claude-env 原本只是 meta-package，不含 plugin 原始碼。

## Decision

將兩個 plugin repo 整併進 claude-env，成為 monorepo。每個 plugin 保持獨立（各自 plugin.json、版本號、CHANGELOG）。

## 架構

```
claude-env/
├── .claude-plugin/
│   └── marketplace.json          ← source 改用相對路徑
├── plugins/
│   ├── misc/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── skills/ (5 skills)
│   │   ├── commands/ (1 command)
│   │   ├── CLAUDE.md
│   │   └── README.md
│   └── squad/
│       ├── .claude-plugin/plugin.json  ← 移除原本的 marketplace.json
│       ├── skills/ (7 skills)
│       ├── commands/ (1 command)
│       ├── hooks/
│       ├── config/
│       ├── scripts/
│       ├── CLAUDE.md
│       ├── README.md
│       └── CHANGELOG.md
├── settings.json
├── install.sh
├── mcp.template.json
└── CLAUDE.md                     ← 更新架構說明
```

## marketplace.json 格式

```json
{
  "name": "my-env",
  "owner": { "name": "EndeavorYen" },
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

相對路徑從 marketplace repo 根目錄解析。Claude Code 在 `claude plugin install` 時會 fetch 整個 marketplace repo，因此子目錄內的 plugin 可正確定位。

## 搬移策略

- 直接複製檔案進 `plugins/` 目錄，不用 git subtree
- 原始 repo 的 commit history 保留在 archive 的 repo 中
- squad 的 `.claude-plugin/marketplace.json` 移除（marketplace 在根目錄）

## 版本管理

- 每個 plugin 各自獨立版本（plugin.json version 欄位）
- squad 保留 scripts/bump-version.sh + CHANGELOG.md
- misc 未來需要時可加自己的版本腳本

## install.sh 改動

- `claude plugin install` 指令不變（`squad@my-env`, `misc@my-env`）
- marketplace 註冊指向同一個 repo，source 改為相對路徑後自動生效

## 原始 repo 處理

- EndeavorYen/claude-misc → Archive，README 加指向說明
- EndeavorYen/claude-squad → Archive，README 加指向說明

## 新增 plugin 流程

1. `mkdir -p plugins/<name>/.claude-plugin`
2. 建立 plugin.json + skills/commands
3. marketplace.json 加一筆 `"source": "./plugins/<name>"`
4. settings.json 加 `enabledPlugins`
5. install.sh 加 `claude plugin install <name>@my-env`
6. commit + push
