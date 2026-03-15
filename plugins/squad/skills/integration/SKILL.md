---
name: integration
description: Use during the INTEGRATE stage after all agents complete execution. Teaches how to merge agent outputs from worktrees and file-boundary isolation back into the main workspace, handling conflicts through additive merge strategies.
---

# Integration — 成果整合術

所有 agent 已完成執行。現在將分散的成果整合回主工作區。這是整個 pipeline 中唯一需要全局視角的節點。

## 前提條件

開始 INTEGRATE 前，確認：
- 所有 agent 已完成（檢查 `.claude/squad/outputs/{callsign}/.complete` 標記）
- 已讀取 pre-flight baseline（`.claude/squad/state/baseline.md`）

## Phase 1 — 清點（Inventory）

讀取每個 agent 的輸出目錄：

```
.claude/squad/outputs/{callsign}/
  contract-ack.md    — 開工前的契約確認
  manifest.md        — 完成狀態、artifact 清單、修改/新建的檔案清單
  interface-changes.md — 對共享檔案的結構性變更描述
  .complete          — 完成標記
```

建立整合清單：

1. 列出每個 agent 修改/新建的所有檔案
2. 建立 **衝突矩陣**：哪些檔案被多個 agent 觸及
3. 確認每個 agent 的隔離方式（worktree / file-boundary / none）
4. **契約比對**：讀取 `contract-ack.md`，比對 `manifest.md` 中實際修改的檔案是否在契約範圍內。超出契約的修改標記為「越界警告」
5. **Artifact 存在性驗證**：確認 manifest.md Artifacts 區塊列出的每個檔案在 worktree 或主工作區中實際存在

### 越界警告處理

如果 agent 修改了未在 contract-ack.md 中聲明的檔案：
- 記錄警告但不自動回退
- 在 INTEGRATE gate 報告中標注越界項目
- 讓使用者決定是否接受越界修改

### Artifact 驗證失敗處理

如果 manifest.md 列出的 artifact 檔案不存在：
- 標記該 task 為 `incomplete`
- 在 INTEGRATE gate 報告中標注缺失的 artifact
- 暫停等待使用者決定（即使在 autonomous 模式）

## Phase 2 — 衝突偵測

對衝突矩陣中的每個共享檔案：

1. 讀取各 agent 的 `interface-changes.md` 中關於此檔案的變更描述
2. 分類變更類型：
   - **Additive（相容）**：不同 agent 新增不同欄位/exports → 可自動合併
   - **Conflicting（衝突）**：同一欄位/函式被多個 agent 修改 → 需要手動決策
3. 產出衝突報告

```
衝突偵測結果：
• useSettingsStore.ts
  - Delta: additive（+showFingering, +language）
  - Echo: read-only
  → 類型：Additive，可自動合併

• index.ts
  - Alpha: additive（+export ComponentA）
  - Bravo: additive（+export ComponentB）
  → 類型：Additive，可自動合併（不同 export）

• Router.tsx
  - Alpha: mutative（修改路由結構）
  - Bravo: mutative（新增路由條目）
  → 類型：Conflicting，需手動決策
```

## Phase 3 — 合併執行

按 dependency wave 順序處理（Wave 1 agent 先合併）。

### Worktree Agent 合併

對每個 worktree agent（按 wave 順序）：

0. **確認 worktree 實際存在**：檢查 `.claude/worktrees/agent-{callsign}/` 是否存在。
   - 若目錄不存在：表示 EXECUTE 階段中 `git worktree add` 失敗並已降級為 `file-boundary`，但降級狀態未被追蹤到此。**將此 agent 視為 file-boundary agent 處理**（執行下方 File-Boundary 合併流程）。
   - 若目錄存在：繼續以下 worktree 合併步驟。

1. **讀取 manifest.md** 取得檔案清單和 artifact 類型
2. **新建的檔案**（不在主工作區存在的）：
   - 來源路徑：`.claude/worktrees/agent-{callsign}/{relative_file_path}`（相對路徑來自 manifest.md）
   - 直接複製到主工作區的對應相對路徑
   - 建立目標目錄（如果不存在）
3. **修改的獨佔檔案**（只有此 agent 觸及的）：
   - 直接從 worktree 複製覆蓋主工作區版本
4. **修改的共享檔案**（多個 agent 觸及的）：
   - **不複製覆蓋**
   - 讀取 agent 的 `interface-changes.md` 確認要新增的內容
   - 用 **additive merge** 策略：
     a. 讀取主工作區中的現有檔案
     b. 在適當位置新增 agent 的新 types、fields、exports、functions
     c. 保持現有結構完整不變
   - 如果是 Conflicting 類型 → 暫停，呈現兩個版本讓使用者決定

### File-Boundary Agent 合併

無需合併——已在主工作區作業。執行邊界驗證：
- 讀取 agent 的 manifest.md 和 contract-ack.md
- 確認 agent 只修改了其被分配的檔案（契約範圍內）
- 如果發現越界修改 → 警告（但不回退）

### None 隔離 Agent 合併

複製產出檔案到目標位置：
- 讀取 manifest.md 取得新建檔案清單
- 複製到主工作區對應路徑

### 合併失敗處理

如果合併過程中發生錯誤（檔案不存在、目錄結構不匹配等）：

1. 停止合併
2. 還原主工作區：`git checkout -- .`
3. **保留 worktrees 不清理**（讓使用者可以重試或手動處理）
4. 報告失敗原因和建議的修復步驟
5. 暫停等待使用者決定（無論 gate level）

## Phase 4 — 清理

合併成功後：

1. 刪除 worktrees：對每個 worktree agent 執行 `git worktree remove .claude/worktrees/agent-{callsign}`
2. 如果 remove 失敗（directory not empty）→ `rm -rf .claude/worktrees/agent-{callsign}`
3. 執行 `git worktree prune`
4. 驗證 `.claude/worktrees/` 目錄為空（或不存在）
5. 清理 outputs：保留 `.claude/squad/outputs/` 到 DEBRIEF 結束後再清理（報告需要引用）

## 常見問題

### Base Commit Drift

如果 worktree 的 base commit 與主工作區 HEAD 差距很大：
- **不要**用 `git diff main` 看 worktree 變更——會顯示大量不相關的 diff
- **要**用 `git diff HEAD` 在 worktree 內部看變更，或讀取 manifest.md
- 在 INTEGRATE gate 報告中標注 drift 距離

### Store / Config 合併

共享的 state store（如 Zustand store、Redux reducer、config 檔案）是最常見的衝突來源：
- 優先用 additive merge（新增欄位到現有結構）
- 永遠不覆蓋整個檔案
- 如果 agent 重建了 store（建立了新的簡化版本），從中提取新增的 field/type/action 手動合併到現有版本

### Artifact 類型與處理

根據 manifest.md 中的 artifact 類型標記，INTEGRATE 可以分類處理：

| 類型 | 合併注意事項 |
|------|------------|
| `[code]` | 檢查 import paths 是否需要調整（worktree vs 主工作區路徑可能不同） |
| `[test]` | 確認 test 依賴的 mock/fixture 也已複製 |
| `[spec]` | interface-changes.md 用於指導 additive merge，不複製到主工作區 |
| `[doc]` | 直接複製，通常無衝突 |
| `[config]` | 高衝突風險——優先用 additive merge |
