---
name: battle
description: >-
  執行一場紅白隊攻防比賽。透過結構化對抗（RED 攻擊 + WHITE 防守 + JUDGE 裁決）
  強化專案品質。可搭配 /loop 持續跑多場：/loop 10m /battle
arguments:
  - name: rounds
    description: 回合數（預設 3）
    required: false
---

# /battle — 紅白隊攻防比賽

執行一場完整的紅白對抗。參照 `docs/against_rule.md` 的完整協議。

## 你的角色

你是 **Battle Orchestrator**（Layer 2），負責協調一場完整比賽。
你是唯一負責檔案 I/O 的角色 — 角色 agent 不直接讀寫 state/memory 檔案。

## 執行步驟

### Step 1：初始化

1. 讀取專案根目錄的 `.battle_memory.yaml`（如存在，否則視為首場）
2. 計算 session number = `record.total + 1`（首場 = 1）
3. 讀取 `docs/against_rule.md` 取得完整協議內容（Role 定義、Persona、Communication Format 等）
4. 建立 `.battle_state.yaml`：

```yaml
session: {N}
phase: "JUDGE_OPENING"
max_rounds: {rounds 參數，預設 3}
```

### Step 2：JUDGE Phase 0（選題）

Spawn 一個獨立 agent 作為 JUDGE，prompt 組裝方式：

1. 從 `docs/against_rule.md` 提取 `Role: JUDGE` 的 **Persona** 全文
2. 注入 `.battle_memory.yaml` 完整內容（首場寫「這是首場對抗，無歷史記錄。」）
3. 注入 `docs/against_rule.md` 的 **Topic Bank** 作為選題參考
4. 指示 JUDGE 分析專案現狀（目錄結構、git log、CLAUDE.md），輸出開場 YAML
5. 收到 JUDGE 輸出後，將 `topic`, `scope`, `dimensions` 寫入 `.battle_state.yaml`

### Step 3：對抗回合（重複 max_rounds 次）

每回合依序執行 3a → 3b → 3c：

**3a. RED ATTACK** — Spawn 獨立 agent 作為 RED

組裝 prompt：
- 從 `docs/against_rule.md` 提取 `Role: RED` 的 **Persona** 全文
- 注入：topic, scope, dimensions
- 注入：record, red_growth, battle_tested_principles（從 memory）
- 根據 `record.streak` 動態生成敘事壓力（見協議的「記憶如何驅動競爭」）
- 注入當前回合深度要求（Round 1=Surface, Round 2=Structural, Round 3=Excellence）
- Round 2+：注入前回合 scoreboard + 白隊修復摘要（只含 finding_id, status, action）
- 注入攻擊策略（測試驅動探測）、紀律、Anti-Shortcut Rules、Quality Gate
- 指示 RED 輸出 Finding Report YAML + Challenger Checkpoint

收到 Finding Report → 寫入 `.battle_state.yaml` 的 `rounds[N].red_findings`

**重要**：RED prompt 不包含 WHITE 的 Persona/策略/紀律

**3b. WHITE DEFEND** — Spawn 獨立 agent 作為 WHITE

組裝 prompt：
- 從 `docs/against_rule.md` 提取 `Role: WHITE` 的 **Persona** 全文
- 注入：topic, scope, dimensions
- 注入：record, white_growth, battle_tested_principles（從 memory）
- 根據 `record.streak` 動態生成敘事壓力
- 注入當前回合完整 red_findings
- 注入 scope 邊界（禁止修改的檔案列表）
- 注入防守策略、紀律、Anti-Shortcut Rules、Quality Gate
- 指示 WHITE 先修改檔案、再輸出 Fix Report YAML + Challenger Checkpoint

收到 Fix Report → 寫入 `.battle_state.yaml` 的 `rounds[N].white_fixes`

**重要**：WHITE prompt 不包含 RED 的 Persona/策略/紀律

**3c. SCOREBOARD（你自己計算，不 spawn agent）**

統計：
- total_findings：累計紅隊 finding 數
- fixed：白隊 `status: fixed` 的數量
- disputed：白隊 `status: disputed` 的數量
- unresolved：total_findings - fixed（disputed 暫不計入 resolved）
- momentum：比較本回合與上回合的 unresolved 趨勢（↑↓→）
- pressure_indicator：🔴 紅隊領先（unresolved > fixed）| ⚪ 勢均力敵 | ⚫ 白隊領先

寫三行 Scoreboard：
```
局勢：{pressure_indicator}
數據：紅隊提出 X 個 finding，白隊修復 Y 個，未解決 Z 個
評語：（一句話描述當前動態）
```

寫入 `.battle_state.yaml` 的 `rounds[N].scoreboard`

### Step 4：JUDGE Final Verdict

Spawn 獨立 agent 作為 JUDGE（終審），prompt 組裝方式：

1. 從 `docs/against_rule.md` 提取 `Role: JUDGE` 的 **Persona** 全文
2. 注入 `.battle_state.yaml` 的完整內容（所有回合的 findings + fixes + scoreboard）
3. 注入 `.battle_memory.yaml` 的完整內容
4. 注入終審流程（跑測試 → 覆核 review finding → 獨立掃描 → 勝負判定）
5. 注入 Judge Audit Trail 格式
6. 指示 JUDGE 依序輸出 5 個區塊：
   - 區塊 A：Judge Audit Trail
   - 區塊 B：Final Verdict YAML
   - 區塊 C：Insights Report YAML
   - 區塊 D：更新後的 `.battle_memory.yaml`（~30 行上限）
   - 區塊 E：Battle Archive Entry（markdown）

收到 JUDGE 輸出後，你（Orchestrator）負責寫入：
- 覆寫 `.battle_memory.yaml`
- Append `.battle_archive.md`

### Step 5：清理 + 輸出

1. 刪除 `.battle_state.yaml`
2. 將所有變更 commit：
   ```
   git add -A && git commit -m "battle(session-{N}): {topic} — winner: {RED|WHITE}"
   ```
3. 輸出一行摘要：`Session {N}: {topic} — winner: {RED|WHITE}`

## 角色隔離規則

這是整個機制最重要的原則 — 你（Orchestrator）是唯一碰檔案的角色：

- **角色 agent 不直接讀寫 state/memory 檔案** — 它們是純輸入純輸出的函式
- **你負責從 state/memory 提取該角色該看的部分注入 prompt**
- **唯一例外**：WHITE agent 可以直接修改 scope 內的專案檔案（這是它的本職工作）
- **RED 看不到** WHITE 的 Persona/策略/紀律，反之亦然
- **RED/WHITE 看不到** JUDGE 的 `judge_calibration` 筆記
- **Scoreboard 由你計算**，雙方看到相同的局勢描述

## 搭配 /loop 使用

```
/loop 10m /battle
```

每 10 分鐘自動跑一場比賽。因為每場結束都 commit + 清理 state，
場與場之間完全隔離，不會有 context 累積問題。

## 錯誤處理

- 如果任何角色 agent spawn 失敗，記錄錯誤並跳到 Step 5 清理
- 如果 `.battle_state.yaml` 已存在（上場未正常結束），先刪除再開始
- 如果 `docs/against_rule.md` 不存在，報錯並退出
