# claude-squad — Self-Evolving Agent Team Orchestrator

## 這是什麼

Claude Code plugin，用 `/squad "objective"` 指令啟動一支 AI agent 小隊，自動完成複雜的開發任務。核心概念是 **7-stage pipeline + 可配置 gate + 持續演化的知識庫 + agent 產出標準化**。

透過 [claude-env](https://github.com/EndeavorYen/claude-env) umbrella marketplace 安裝。

## 使用方式

```bash
/squad "implement dark mode for the app"
/squad "fix the authentication bug" --gate supervised
/squad "refactor database layer" --gate autonomous

# 子命令
/squad --status      # 查看最近任務狀態
/squad --history     # 列出歷史任務報告
/squad --knowledge   # 查看知識庫內容
/squad --abort       # 中止當前任務並清理
```

## 7-Stage Pipeline

```
RECON → PLAN → EXECUTE → INTEGRATE → VERIFY → DEBRIEF → RETRO
```

| Stage | 做什麼 | 產出 |
|-------|--------|------|
| **RECON** | 靜默讀取 CLAUDE.md、DESIGN.md、git log、知識庫 | 內部情報（不輸出） |
| **PLAN** | 分解任務 + 設計 agent 角色 + 隔離策略 + 呈現作戰計畫 | 任務清單 + 團隊編制 + 合併策略 |
| **EXECUTE** | 建立 Team、spawn agents（支援 convoy 批次部署）、監控執行 | Agent 產出（manifest.md + .complete） |
| **INTEGRATE** | 合併 worktree/file-boundary 成果、衝突偵測、additive merge | 整合後的程式碼 |
| **VERIFY** | 跑 lint/typecheck/test + 基線差異分析 | 驗證報告（與 pre-flight 基線比對） |
| **DEBRIEF** | 產生任務報告、更新 ROADMAP.md、容錯關閉團隊 | 報告檔案 |
| **RETRO** | 回顧得失（含整合維度）、更新知識庫、鍛造新工具 | 知識庫更新 |

### Gate Levels

| Level | PLAN 後 | EXECUTE 後 | INTEGRATE 後 | VERIFY 後 | 失敗時 |
|-------|---------|-----------|-------------|----------|--------|
| `supervised` | 暫停 | 暫停 | 暫停 | 暫停 | 一律暫停 |
| `standard`（預設） | 暫停 | 繼續 | 暫停 | 暫停 | 一律暫停 |
| `autonomous` | 繼續 | 繼續 | 繼續* | 繼續* | 一律暫停 |

*autonomous 模式下，INTEGRATE 若無衝突合併才繼續，VERIFY 若全部通過才繼續。另有動態升級規則：3+ 衝突檔案、20+ commit drift、基線迴歸均強制暫停。

## Plugin 結構

```
claude-squad/
├── .claude-plugin/
│   ├── plugin.json            ← name: "squad", version: "0.3.0"
│   └── marketplace.json       ← 本地 marketplace 定義（安裝用）
├── commands/
│   └── squad.md               ← /squad 主指令（完整 7-stage pipeline 邏輯）
├── skills/                    ← 7 個內部 skills（由 squad.md 調用）
│   ├── gate-check/            ← Gate 驗證邏輯（含動態升級規則）
│   ├── integration/           ← INTEGRATE 階段合併方法論（v0.2 新增）
│   ├── mission-planning/      ← 任務分解 + 隔離策略 + convoy 部署規劃
│   ├── role-forging/          ← Agent 角色設計（含 contract-ack + artifact typing）
│   ├── retrospective/         ← 回顧分析 + 知識萃取 + 知識老化機制
│   ├── status-report/         ← 任務報告格式化
│   └── tool-forging/          ← 自動創建工具（bash scripts / skills）
├── config/
│   ├── defaults.yaml          ← 預設設定（gate, team, deployment, integration, resilience）
│   └── bootstrap/             ← 首次運行時的知識庫模板
│       ├── lessons.md
│       ├── metrics.md
│       ├── role-patterns.md
│       └── tool-patterns.md
├── scripts/
│   ├── bump-version.sh        ← 自動版號管理（auto/patch/minor/major）
│   ├── update-changelog.py    ← CHANGELOG 產生器（從 conventional commits）
│   ├── install-hooks.sh       ← 安裝 git hooks
│   └── hooks/
│       └── post-commit        ← post-commit hook（feat:/fix: → auto bump）
├── CHANGELOG.md               ← 版本變更紀錄
└── hooks/
    └── hooks.json             ← Stop hook — 防止任務進行中被中斷
```

## 每個專案的知識庫

首次在某專案執行 `/squad` 時，會自動建立：

```
<project>/.claude/squad/
├── config.yaml              ← 從 defaults.yaml 複製，可客製化
├── knowledge/
│   ├── lessons.md           ← 累積的經驗教訓
│   ├── role-patterns.md     ← 驗證有效的 agent 角色設計
│   ├── tool-patterns.md     ← 可重用的工具配置
│   └── metrics.md           ← 跨任務績效追蹤
├── tools/                   ← 自動產生的 bash scripts
└── reports/                 ← 任務報告（YYYY-MM-DD-slug.md）
```

## 開發慣例

### 架構原則

- **squad.md 是唯一入口** — 所有 pipeline 邏輯集中在 `commands/squad.md`
- **Skills 是內部模組** — 由 squad.md 在對應 stage 調用，不直接對使用者暴露
- **Config 是 advisory** — defaults.yaml 提供預設值，各專案可在 `.claude/squad/config.yaml` 覆寫
- **Hooks 保護執行中任務** — Stop hook 檢查是否有活躍 mission，防止意外中斷

### 修改 Skill

1. 編輯 `skills/<name>/SKILL.md`
2. 測試：在一個專案中跑 `/squad "test objective" --gate supervised` 確認行為
3. Push：`git commit -am "improve: skill-name" && git push`
4. 其他機器：`claude plugin marketplace update my-env`

### 新增 Skill

1. 建立 `skills/new-skill/SKILL.md`（含 YAML frontmatter）
2. 在 `commands/squad.md` 的對應 stage 加入 `invoke new-skill skill` 調用
3. Push + update

### 版本管理

- **Single source of truth:** `.claude-plugin/plugin.json` 的 `version` 欄位
- 遵循 semver：breaking change → major, 新功能 → minor, 修復 → patch
- 變更紀錄在 `CHANGELOG.md`（遵循 [Keep a Changelog](https://keepachangelog.com/) 格式）
- 目前版本：`0.3.0`

**自動升版（推薦）：安裝 post-commit hook**

```bash
# 一次性安裝
bash scripts/install-hooks.sh

# 之後每次 feat:/fix: commit 都會自動 bump + tag
git commit -m "feat: add dark mode"
# → 自動產生 "chore: release v0.3.0" commit + v0.3.0 tag
```

**手動升版：**

```bash
./scripts/bump-version.sh auto              # 預覽：只更新檔案
./scripts/bump-version.sh auto --release    # 更新 + commit + tag
./scripts/bump-version.sh patch|minor|major # 指定 bump 類型
```

**Conventional commit → 自動版號對應：**

| Commit prefix | Bump | 範例 |
|--------------|------|------|
| `feat:` | minor | `feat: add convoy deployment` |
| `fix:` | patch | `fix: stale agent fallback` |
| `BREAKING CHANGE` 或 `feat!:` | major | `feat!: redesign pipeline` |
| `docs:`, `chore:`, `ci:` | 不升版 | `docs: update CLAUDE.md` |

## 關鍵設計決策

| 決策 | 選擇 | 原因 |
|------|------|------|
| Pipeline 控制流 | 單一 command (squad.md) | 一個檔案掌控全局，避免跨檔狀態管理 |
| Agent 命名 | NATO phonetic (Alpha~Foxtrot) | 簡短、無歧義、可讀性高 |
| 知識庫位置 | 各專案 `.claude/squad/` | 知識跟專案走，不同專案累積不同經驗 |
| Gate 機制 | 3 級 + 動態升級（supervised/standard/autonomous） | 平衡安全性與效率，異常情況自動升級 |
| Stop hook | prompt-based | 靈活判斷是否有活躍 mission，非硬編碼 |
| 團隊大小 | 最多 5 人（config 可調） | 避免 context 過載和協調成本 |
| 隔離策略 | worktree / file-boundary / none（按任務特性選擇） | 避免 agent 間衝突，同時支援共享檔案的 additive merge |
| Agent 產出標準化 | manifest.md + interface-changes.md + .complete | 讓 INTEGRATE 可靠地合併成果 |
| Contract 機制 | contract-ack.md（開工前寫、INTEGRATE 時驗） | 防止 agent 越界修改 |
| Convoy 部署 | 5+ agents 或 3+ waves 時分批部署 | 避免同時 spawn 太多 agent 導致資源爭搶 |

## 已知問題與對策

### Agent Stale After Deployment（v0.2 已修復）

**症狀：** Agent 透過 `Task` tool 部署後，在 team config 中顯示 `backendType: "in-process"` 但完全不執行任何工作。`.claude/squad/outputs/` 為空，`SendMessage` 無回應。

**根因：** `Task` tool 成功將 agent 註冊到 team config，但 agent process 從未啟動。屬於 experimental agent teams API 的已知不穩定行為。靜默失敗——沒有錯誤訊號。

**對策（已實作）：**
1. **Startup health check** — 部署後 3 分鐘內檢查 `contract-ack.md`（agent 的存活證明）
2. **Respawn** — Stale agent 自動重新部署一次
3. **Fallback to direct execution** — 若 respawn 仍失敗，Chief of Staff 接手直接執行所有任務
4. **Role-forging 強化** — agent persona 中明確標注 `contract-ack.md` 為最優先動作，包含存活警告

## 注意事項

- **需要 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` 環境變數** 才能使用 TeamCreate 等 API
- **Plugin name 是 `squad`** — 安裝指令：`claude plugin install squad@my-env --scope user`
- **squad.md 很長** — 修改前請完整閱讀，理解 7 個 stage 間的銜接邏輯
- **知識庫是 `.claude/squad/`** — 在各專案的 `.gitignore` 中決定是否追蹤
