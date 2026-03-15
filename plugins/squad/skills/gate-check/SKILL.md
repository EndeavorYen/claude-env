---
name: gate-check
description: Use when reaching a gate point in the squad pipeline (after PLAN, EXECUTE, INTEGRATE, or VERIFY). Determines whether to pause for user confirmation or proceed automatically based on the configured gate level.
---

# Gate Check

Gate checks are decision points in the squad pipeline where the lead must decide whether to pause for user confirmation or proceed automatically. The behavior depends on the configured gate level and whether any override conditions are met.

## Gate Level Table

| Gate Level | After PLAN | After EXECUTE | After INTEGRATE | After VERIFY |
|------------|-----------|---------------|-----------------|--------------|
| **supervised** | Pause | Pause | Pause | Pause |
| **standard** | Pause | Proceed | Pause | Pause |
| **autonomous** | Proceed | Proceed | Proceed | Proceed |

- **supervised** — pause at all three gate points. Best for unfamiliar codebases, high-risk changes, or when the user wants full control.
- **standard** — pause after PLAN (to confirm approach) and after VERIFY (to confirm results), but let EXECUTE run without interruption. This is the recommended default. INTEGRATE pauses in standard mode because merge results should be reviewed before running verification.
- **autonomous** — no pauses. The squad runs the full pipeline end-to-end. Best for well-understood, low-risk tasks with high test coverage.

## Pause Presentation Format

When pausing at a gate point, present a structured summary so the user can make an informed decision quickly.

### After PLAN

```
## Gate: Plan Review

**Mission**: {one-line mission description}
**Approach**: {strategy summary}

### Planned Tasks
1. {task} — assigned to {member}
2. {task} — assigned to {member}
...

### Files to be modified
- {file path} — {what changes}
...

### Risks
- {risk description}

Proceed? (yes / no / adjust)
```

### After EXECUTE

```
## Gate: Execution Review

**Mission**: {one-line mission description}
**Status**: {N}/{M} tasks completed

### Member Results
| Member | Task | Status | Notes |
|--------|------|--------|-------|
| {name} | {task} | done/partial/blocked | {brief note} |
...

### Changed Files
- {file path} — {summary of change}
...

### Issues Encountered
- {issue description, if any}

Proceed to VERIFY? (yes / no / retry)
```

### After INTEGRATE

```
## Gate: Integration Review

**Mission**: {one-line mission description}
**Worktrees merged**: {N}/{M}

### Merge Results
| Agent | Isolation | Files | Conflicts | Status |
|-------|-----------|-------|-----------|--------|
| {name} | {worktree/boundary/none} | {N} | {count} | {done/failed} |

### Contract Compliance
- {agent}: ✅ within bounds / ⚠️ {N} out-of-bounds modifications

### Artifact Verification
- {agent}: ✅ all artifacts exist / ❌ missing: {file list}

### Conflict Resolutions
- {file}: {how the conflict was resolved}

### Worktree Cleanup
- {status of each worktree removal}

Proceed to VERIFY? (yes / no / revert)
```

### After VERIFY

```
## Gate: Verification Review

**Mission**: {one-line mission description}

### Verification Results
| Check | Result | Details |
|-------|--------|---------|
| Lint | pass/fail | {error count or clean} |
| Typecheck | pass/fail | {error count or clean} |
| Tests | pass/fail | {passed}/{total}, {failed} failures |

### Summary
- {what was accomplished}
- {any remaining concerns}

Accept and complete? (yes / no / fix)
```

## Override Rules

**ALWAYS pause regardless of gate level** if any of the following conditions are detected:

1. **Verification fails** — if lint, typecheck, or tests fail after VERIFY, the lead must pause and present the failures to the user before proceeding. Never silently continue past a failed verification.

2. **Unresolvable blocker** — if a member reports a blocker that cannot be resolved within the squad (e.g., missing credentials, unclear requirements, external dependency down), pause and escalate to the user.

3. **Scope change detected** — if during EXECUTE the squad discovers that the actual work differs significantly from the plan (new files not anticipated, architectural changes needed, touching more modules than planned), pause and re-confirm with the user.

4. **Destructive actions needed** — if the mission requires destructive operations (force push, database migration, deleting files, resetting state), pause and get explicit user confirmation regardless of gate level. List exactly what will be destroyed.

5. **Integration conflicts** — if INTEGRATE detects 3 or more files with conflicting changes (not additive), pause regardless of gate level and present the conflict details for user resolution.

6. **Worktree drift** — if any agent's worktree base commit is more than 20 commits behind the current HEAD, pause and warn about potential drift issues before proceeding with integration.

7. **Verification regression** — if VERIFY detects new failures that were not in the pre-flight baseline, pause regardless of gate level. Present the baseline comparison showing exactly which failures are new.

8. **Direct execution fallback** — if the Chief of Staff executed any tasks directly due to agent deployment failure (stale agents that could not be respawned), pause after EXECUTE regardless of gate level. The user should review the directly-executed work since it lacked the normal agent isolation and contract-ack safeguards.

When an override triggers a pause, prepend the summary with:

```
> **Override: {reason}** — pausing for confirmation regardless of gate level.
```
