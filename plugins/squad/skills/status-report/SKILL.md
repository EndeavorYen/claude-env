---
name: status-report
description: Use when generating the DEBRIEF mission report or when the user asks for /squad --status or --history. Defines the structured report format for squad missions.
---

# Status Report — 戰況報告

## Mission Report (DEBRIEF stage)

Write to `.claude/squad/reports/YYYY-MM-DD-{mission-slug}.md`:

```markdown
# Mission Report: {Mission Name}
> Date: {YYYY-MM-DD} | Gate: {level} | Duration: ~{N} min

## Objective
{Original objective as given by the 總統}

## Squad Composition
| Callsign | Forged Role | Tasks | Status |
|----------|-------------|-------|--------|
| Alpha | {specific role description} | #1, #3 | ✅ Complete |
| Bravo | {specific role description} | #2 | ✅ Complete |

## Task Breakdown
| # | Description | Owner | Status | Notes |
|---|-------------|-------|--------|-------|
| 1 | {specific task} | Alpha | ✅ | {blockers, pivots, timing} |
| 2 | {specific task} | Bravo | ✅ | |

## Execution Summary

### RECON
{What was discovered about the codebase — relevant architecture, existing patterns, potential risks}

### PLAN
{Key planning decisions — why this decomposition, why these roles, any alternatives considered}

### EXECUTE
{How execution went — any blockers hit, pivots made, communication between members}

### INTEGRATE
{How integration went — worktrees merged, conflicts found and resolved, cleanup status}

### VERIFY
{Verification results — baseline delta analysis, any new failures found and how they were fixed}

## Changes Made
{Group files by purpose}

**New files:**
- `path/to/new/file.ts` — {purpose}

**Modified files:**
- `path/to/modified/file.ts` — {what changed and why}

**Test files:**
- `path/to/test.test.ts` — {N new tests}

## Verification Results
- lint: ✅/❌ {details if failed}
- typecheck: ✅/❌ {details if failed}
- test: ✅/❌ ({before count} → {after count} tests)

## Lessons Learned
{Key insights from this mission — also written to knowledge/lessons.md}
- {Lesson 1}
- {Lesson 2}
```

### Report Naming

Slugify the mission objective for the filename:
- "Implement Phase 6.5 keyboard shortcuts" → `2026-02-28-keyboard-shortcuts.md`
- "Fix bug in audio scheduler" → `2026-03-01-fix-audio-scheduler-bug.md`

Keep slugs short (3-5 words max).

---

## --status Format (in-progress mission)

When the user asks `/squad --status`, present:

```
── Squad Status ─────────────────────
Mission: {objective}
Stage: {current stage} ({N}/{7} stages)
Gate: {level}

Tasks:
  ✅ #1 {description} (Alpha)
  🔄 #2 {description} (Bravo) — in progress
  ⏳ #3 {description} — blocked by #1
  ⬚ #4 {description} — pending

Squad:
  Alpha — {role}: idle (completed #1)
  Bravo — {role}: working on #2
─────────────────────────────────────
```

Status icons:
- ✅ completed
- 🔄 in progress
- ⏳ blocked (waiting for dependency)
- ⬚ pending (not started)

---

## --history Format

Read all files in `.claude/squad/reports/` and present:

```
── Mission History ──────────────────
| Date | Mission | Gate | Squad | Result |
|------|---------|------|-------|--------|
| 2026-02-28 | Keyboard shortcuts | standard | 3 | ✅ |
| 2026-03-01 | Dark theme | autonomous | 2 | ✅ |
| 2026-03-02 | Audio refactor | supervised | 4 | ✅ |

Total: {N} missions | Knowledge entries: {M}
─────────────────────────────────────
```

If no reports exist, say: "No mission history yet. Run `/squad \"objective\"` to start your first mission."
