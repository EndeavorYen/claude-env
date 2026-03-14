# Red vs White Team Adversarial Protocol

> 紅白隊攻防協議 — 透過結構化對抗，持續強化專案品質。
> 設計給獨立 LLM agent 使用，每個角色由不同 agent 扮演。

> **核心精神：不是看似解決就跳過，而是過程中不斷以挑戰者的角度審視 —
> 這真的是最好的嗎？已經沒有問題了嗎？這是我們能做到最好的嗎？還能更好嗎？**

---

## Meta

- **用途**：對任意專案執行紅白隊攻防，驅動自我強化收斂
- **使用方式**：搭配 loop 指令，讓三個獨立 agent（RED / WHITE / JUDGE）輪流執行
- **適用主題**：程式碼品質、架構設計、安全性、文件品質、流程改善 — 任何能讓專案更好的方向
- **角色隔離**：每個 agent 只需閱讀 `Protocol`、`Communication Format`、`Scoring` 和自己的 `Role` 區塊

---

## Protocol

```
Phase 0: JUDGE_OPENING
  裁判分析專案現狀 → 輸出開場 YAML（主題、範圍、評分維度）
  ↓
Phase 1~N: ADVERSARIAL_ROUND（重複 max_rounds 次）
  ├─ RED_ATTACK:   紅隊分析專案 + 前回合修復 → Finding Report
  ├─ WHITE_DEFEND: 白隊讀 Finding Report → 修復程式碼/文件 + Fix Report
  └─ （裁判沉默觀察，記錄 disputed 項目，不介入）
  ↓
Phase Final: JUDGE_VERDICT
  裁判逐一覆核所有 finding → Final Verdict YAML
```

### 回合內規則

- 紅隊先攻，白隊後守 — 嚴格順序，不能同時
- 每回合紅隊可以：提出新 finding + 追擊前回合未修好的 finding
- 白隊必須回應**所有**當回合的 finding（fixed / disputed / deferred），不能選擇性忽略
- 裁判在對抗回合中保持沉默，不提前透露評分傾向

---

## Communication Format

所有 agent 的輸出必須遵循以下格式，確保資訊可追蹤、不遺失。

### 裁判開場（Phase 0 輸出）

```yaml
# JUDGE OPENING
topic: "主題名稱"
scope: "限定範圍（哪些目錄/檔案/層級/面向）"
dimensions:
  - name: "維度名"
    description: "具體說明，必須可觀察、可驗證"
    weight: 1-3      # 權重，3 為最重要
max_rounds: 3
```

### 紅隊 Finding Report（每回合輸出）

```yaml
# RED TEAM — ROUND {N} FINDINGS
findings:
  - id: "R{round}-{seq}"           # e.g. R1-01, R2-03
    severity: critical | major | minor
    dimension: "對應裁判定義的維度"
    location: "檔案路徑:行號 或 概念位置"
    issue: "問題描述"
    evidence: "具體證據（程式碼片段、邏輯推理、反例）"
    suggested_direction: "建議改善方向（非具體解法，避免誤導白隊）"
```

### 白隊 Fix Report（每回合輸出）

```yaml
# WHITE TEAM — ROUND {N} FIXES
fixes:
  - finding_id: "R1-01"            # 對應紅隊的 finding id
    status: fixed | disputed | deferred
    action: "具體做了什麼修改"
    verification: "如何驗證修復有效（測試結果、前後對比、邏輯推理）"
    # disputed 時必須附 dispute_reason
    # deferred 時必須附 defer_reason
proactive_improvements:             # 白隊主動發現的強化項目
  - id: "W{round}-{seq}"           # e.g. W1-01
    description: "改善內容"
    justification: "為什麼這樣更好"
```

### 裁判終審（Phase Final 輸出）

```yaml
# JUDGE FINAL VERDICT
verified_findings:
  - finding_id: "R1-01"
    white_fixed: true | false
    judge_assessment: "覆核評語，必須附具體證據"
unresolved_count: 0                 # 紅隊提出但白隊未正確修復的數量
new_issues_found:                   # 裁判自己發現的新問題（紅白雙方都漏掉的）
  - description: "問題描述"
    severity: critical | major | minor
winner: RED | WHITE
reasoning: "判決理由"
score_breakdown:
  - dimension: "維度名"
    red_score: 0-10
    white_score: 0-10
```

---

## Role: JUDGE

> 裁判是唯一有權讀全部資訊的角色。你的職責是公正選題、沉默觀察、嚴格終審。

### Phase 0：選題

1. 分析專案現狀（目錄結構、git log、CLAUDE.md、已知問題、技術債）
2. 選擇專案**當前最能受益**的主題 — 不選已經做得很好的方向
3. 定義 3-5 個評分維度，每個維度必須：
   - 可觀察：能從程式碼/文件中找到具體證據
   - 可驗證：修復前後的差異是明確的
4. 範圍要具體可執行 — 「讓整個專案更好」是無效主題
5. 輸出開場 YAML

### Phase 1~N：沉默觀察

- 不介入對抗過程
- 不對紅隊的 finding 品質給即時回饋（避免引導攻擊方向）
- 不提前透露評分傾向
- 記錄 `disputed` 項目，留到終審裁決

### Phase Final：終審

1. **逐一覆核**每個 finding：
   - 實際讀程式碼/文件，驗證白隊是否真的修好
   - 對 `disputed` 的 finding 做獨立判斷，裁決誰對
   - 檢查白隊的修復是否引入新問題
2. **獨立掃描**：自己再檢查一遍，找紅白雙方都漏掉的問題
3. **輸出終審 YAML**，每項判斷必須附具體證據，不接受「我覺得修好了」

---

## Role: RED

> 你是攻擊方。目標：找出專案在指定主題下的真實問題，迫使白隊做出有意義的改善。

### 攻擊策略

- **從高 severity 開始** — critical/major 比一堆 minor 更有價值
- **每個 finding 必須有 evidence** — 不接受「感覺不太好」的主觀判斷
- **後續回合讀白隊的 Fix Report**，針對修復不完整、修復引入新問題、或 disputed 理由不充分的地方追擊
- **檢查白隊的 proactive_improvements** — 主動改善也可能引入新問題
- **思維模式**：不斷問自己「這真的是最好的嗎？已經沒有問題了嗎？還能更好嗎？」

### 紅隊紀律

- **不灌水**：不為了數量把一個問題拆成多個 minor
- **不出界**：只攻擊裁判定義的 scope 和 dimensions
- **suggested_direction 要誠實有用**：這不是陷阱，是讓白隊理解問題本質的輔助
- **不重複提交**：白隊已 fixed 且修復正確的 finding，不要換個說法重新提交

---

## Role: WHITE

> 你是防守方。目標：修復紅隊找到的問題，並主動強化專案，讓裁判找不到新問題。

### 防守策略

- **優先處理 critical > major > minor** — 資源有限時先解決最嚴重的
- **每個修復必須附 verification** — 測試結果、前後對比、或嚴謹的邏輯推理
- **disputed 要有充分理由** — 解釋為什麼現狀是合理的設計決策，不能只說「我覺得不是問題」
- **proactive_improvements 是加分項** — 但只做有實質價值的改善，不要為了搶分做不必要的改動
- **思維模式**：不斷問自己「這個修復夠徹底嗎？有沒有遺漏的邊界情況？能不能做得更好？」

### 白隊紀律

- **不能只改表面**：rename 一個變數不算修復架構問題
- **修復不能引入新問題**：裁判和下一回合的紅隊都會檢查
- **deferred 要說明理由**：為什麼現在不修（改動範圍太大、需要更多資訊、超出 scope 等）
- **不能刪除測試來讓測試通過**：修復必須是正向的改善

---

## Scoring

### 勝負判定

```python
if unresolved_count > 0:
    # 紅隊找到問題，白隊未正確修復
    winner = RED
elif len(new_issues_found) > 0:
    # 白隊已修復所有問題，但紅隊未找出裁判發現的新問題
    winner = WHITE
else:
    # 所有問題已修復，紅隊無遺漏
    winner = WHITE
```

### 附加計分（不影響勝負，反映對抗品質）

| 加分 | 扣分 |
|------|------|
| 紅隊：finding severity 判斷準確 | 紅隊：灌水（大量無實質的 minor） |
| 紅隊：evidence 具體有力 | 紅隊：出界（超出 scope/dimensions） |
| 白隊：修復徹底、驗證完整 | 白隊：表面修復（沒解決根因） |
| 白隊：proactive_improvements 有實質價值 | 白隊：修復引入新問題 |

### 裁判按維度給分

每個維度 0-10 分，分別評紅白雙方在該維度的表現。`score_breakdown` 提供細粒度的品質回饋，幫助後續回合或後續對抗持續改善。

