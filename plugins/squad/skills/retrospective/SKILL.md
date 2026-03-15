---
name: retrospective
description: Use during the RETRO stage after a squad mission completes. Guides reflection on efficiency, roles, tools, and process. Updates the persistent knowledge base to enable continuous improvement across missions.
---

# Retrospective — 反思進化

The mission is complete. Now reflect and evolve. This is where the squad gets smarter over time.

## Reflection Framework

Analyze the mission across four dimensions:

### 1. Efficiency (效率)

- Which tasks took longer than expected? What was the root cause?
- Was the task decomposition granularity appropriate? (too fine = coordination overhead, too coarse = blocked members)
- Were there unnecessary sequential dependencies that could have been parallel?
- Did any squad member's context grow too large, causing degraded performance?

### 2. Roles (角色)

- Which persona designs produced focused, effective work? What made them effective?
- Which personas were too vague, causing the member to make unnecessary decisions or go off-scope?
- Were the 禁止事項 (prohibitions) respected? If violated, what was missing from the persona?
- Did any member need expertise not included in their persona?

### 3. Tools (工具)

- Were there actions performed **3 or more times manually** that should be scripted?
- Did verification commands cover all necessary checks?
- Are there project-specific validations that should become permanent tools?
- Did the squad need to gather information in a pattern that could be automated?

### 4. Process (流程)

- Was the gate level appropriate? Did pauses slow things down unnecessarily, or did insufficient pauses miss issues?
- Did the 7-stage pipeline flow smoothly? Were any stages skipped, repeated, or felt unnecessary?
- Was communication between squad members and lead sufficient? Too much? Too little?
- Was squad size appropriate? Too many idle members or too few causing bottlenecks?

### 5. Integration (整合)

- Were the isolation strategies appropriate? Did worktree agents need to be in the main workspace instead, or vice versa?
- Did the conflict risk assessment in PLAN accurately predict actual conflicts in INTEGRATE?
- Were interface contracts sufficient? Did agents still produce incompatible changes?
- Was the merge order correct? Did any merge fail because of ordering issues?
- Did convoy mode (if used) effectively reduce context pressure?

### 6. Resilience (韌性)

- Were any agents stale at startup (no `contract-ack.md` within timeout)? How many?
- Did respawn succeed? If not, what was the likely root cause?
- Was fallback-to-direct-execution used? How did it affect mission quality and timing?
- Did any agent disconnect mid-execution (runtime timeout)? What was the recovery outcome?
- Were the resilience config values (`startup_timeout_minutes`, `max_respawns_per_task`) appropriate, or should they be adjusted for this project?

## Knowledge Base Updates

After reflection, update these files. **Create the file if it doesn't exist.**

### lessons.md

Append a dated entry:

```markdown
## {YYYY-MM-DD} — {Mission Name}
- {Concrete lesson, not vague platitude}
- {Another lesson}
```

Good lesson: "Splitting PixiJS renderer work and Zustand store work into separate members caused integration issues — next time assign both to one member when they share a tight interface."

Bad lesson: "Communication is important." (too vague to act on)

### role-patterns.md

If an effective persona was discovered, record it:

```markdown
## Pattern: {Descriptive Pattern Name}
**When to use:** {Specific situation where this persona works well}
**Key elements:**
- {What made this persona effective}
- {Specific constraints or instructions that helped}
**Persona template:**
{The effective prompt structure, with {placeholders} for mission-specific details}
**Proven in:** {mission name, date}
```

### tool-patterns.md

If a tool was created or an automation opportunity was identified:

```markdown
## Tool: {Tool Name}
**Type:** {bash script | skill | hook}
**Location:** {file path}
**Purpose:** {what it automates}
**Created:** {date}
**Used in:** {N} missions
**Promotion status:** {immediate-only | candidate-for-skill | promoted-to-skill}
```

### metrics.md

Append mission metrics:

```markdown
## {YYYY-MM-DD} — {Mission Name}
- Squad size: {N}
- Tasks: {completed}/{total}
- Verification: {pass|fail}
- Gate: {level}
- Deploy mode: {convoy|full}
- Isolation: worktree:{N}, boundary:{N}, none:{N}
- Integration conflicts: {count}
- Auto-fixed issues: {count}
- Context compaction events: {count}
- Stale agents detected: {count}
- Respawn attempts: {count} (success: {count})
- Fallback to direct execution: {yes|no}
- Baseline regression: {yes|no}
- New tools created: {count}
- Role patterns recorded: {count}
```

## Evolution Triggers

After updating the knowledge base, check these thresholds:

| Signal | Threshold | Action |
|--------|-----------|--------|
| Same lesson appears repeatedly | 3+ occurrences | Create a permanent skill or hook to prevent it |
| Bash script reused across missions | 2+ missions | Promote to formal skill (use tool-forging skill) |
| Role pattern used successfully | 3+ missions | Mark as "stable" in role-patterns.md |
| Verification gap caught late | 1 occurrence | Add to verify_commands in config |
| Gate level consistently overridden | 3+ missions | Suggest changing default_gate in config |
| Lesson not referenced for 10+ missions | 10 missions | Mark as `[archived]` and move to bottom of lessons.md |
| Role pattern fails 3 consecutive times | 3 failures | Mark as `[deprecated]` with failure reason |
| Tool unused for 5+ missions | 5 missions | Suggest removal or archival in RETRO output |

## Output

After completing RETRO, present a brief summary:

```
[RETRO] 反思完成。
📚 知識庫更新：
  - lessons.md: +{N} 條經驗
  - role-patterns.md: +{N} 個模式
  - tool-patterns.md: +{N} 個工具
  - metrics.md: 已記錄
🔧 {New tools/skills created, or "無新工具"}
📈 累計 {total} 次任務完成
```
