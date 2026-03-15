# battle — 紅白隊攻防品質對抗 Plugin

## 這是什麼

透過結構化的紅白對抗（RED 攻擊 + WHITE 防守 + JUDGE 裁決）強化專案品質。每場比賽自動 commit，支援 `/loop` 持續執行。

## 結構

```
plugins/battle/
├── .claude-plugin/
│   └── plugin.json          ← Plugin manifest（name: "battle"）
├── commands/
│   └── battle.md            ← /battle 指令
├── docs/
│   └── against_rule.md      ← 完整對抗協議（角色定義、Topic Bank 等）
└── CLAUDE.md
```

## 使用方式

```
/battle           # 執行一場（預設 3 回合）
/battle 5         # 指定 5 回合
/loop 10m /battle # 每 10 分鐘自動跑一場
```

## 運作機制

- **Orchestrator**：讀寫所有 state/memory 檔案，協調三個角色
- **RED**：攻擊方，找出專案弱點（測試驅動探測）
- **WHITE**：防守方，修復 RED 發現的問題
- **JUDGE**：裁判，選題 + 終審判定勝負

角色之間完全隔離 — RED 看不到 WHITE 的策略，反之亦然。

## 專案級檔案（由 /battle 在目標專案產生）

| 檔案 | 用途 |
|------|------|
| `.battle_memory.yaml` | 跨場記憶（戰績、成長軌跡） |
| `.battle_archive.md` | 歷史紀錄（每場摘要 append） |
| `.battle_state.yaml` | 單場狀態（比賽結束後刪除） |

## 注意事項

- **Plugin name 是 `battle`** — 安裝指令：`claude plugin install battle@my-env --scope user`
- **`against_rule.md` 是核心協議** — 修改前請確認理解整個對抗流程
- **角色隔離是最重要的原則** — Orchestrator 是唯一碰 state 檔案的角色
