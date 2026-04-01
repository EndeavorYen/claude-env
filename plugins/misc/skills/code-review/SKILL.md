---
name: code-review
description: >-
  Deep file-level code review against the project's own architecture conventions.
  Use when the user says "review", "code review", "審查", "check quality",
  "review this file", "review my changes", or asks you to look at code for
  issues. Also trigger proactively after completing a significant feature.
---

# Code Review — Deep File Audit

Review files against the project's **actual** conventions — not textbook rules,
not your preferences, not what "best practice blogs" say. Every finding must be
calibrated to patterns **this codebase already uses**.

> **A review that floods the author with 20 nitpicks while missing the one
> architectural violation is worse than no review at all.**

---

## Three Iron Laws

Internalize these before you read a single line of code:

1. **Signal > Noise**: Every issue you raise competes for the author's attention.
   Ten minor style nits bury the one critical bug. If you can't explain why a
   finding **matters to this project**, don't report it.

2. **Codebase > Textbook**: If the project consistently uses pattern X and you
   prefer pattern Y, **X is correct here**. Your job is to enforce the project's
   conventions, not evangelize your own. The only exception is when pattern X
   creates a demonstrable bug or security hole.

3. **Actionable > Directional**: "Consider improving error handling" is not a
   finding. "L42: `JSON.parse` can throw on malformed input but the caller
   has no try/catch — add one or propagate the error" is a finding.

---

## Anti-Pattern Self-Check

Before writing your report, verify you're not falling into these traps:

| Trap | Symptom | Consequence |
|------|---------|-------------|
| 🔬 **Nitpick Flood** | 15+ minor style issues, zero architectural insights | Author ignores everything, including the real problems |
| 🦜 **Parrot Reviewer** | Repeating generic rules ("avoid magic numbers", "add JSDoc") without checking if the project even follows those conventions | Wastes time, erodes trust |
| 🌳 **Missing the Forest** | Obsessing over variable names while a circular dependency or data race sits in plain sight | The dangerous stuff ships unchecked |
| 🎭 **Performative Rigor** | Inventing issues to appear thorough when the code is actually clean | Adds unnecessary complexity, delays shipping |
| 😴 **Rubber Stamp** | "LGTM" with zero analysis because the code looks reasonable at a glance | Misses genuinely important issues |

**If your review smells like any of the above, stop and recalibrate.**

---

## Input Modes

| Invocation | Behavior |
|------------|----------|
| `/code-review` (no args) | Review files changed in `git diff` (staged + unstaged) |
| `/code-review <path>` | Review a specific file or all source files in a directory |

---

## Execution Steps

### Phase 0: Learn the Project (Before Reviewing Anything)

You cannot review code you don't have context for. Before touching the target
files, quickly scan:

- `CLAUDE.md` / `CONTRIBUTING.md` / `DESIGN.md` for documented conventions
- 2-3 existing files **in the same directory** to see established patterns
- Config files (`tsconfig.json`, `eslintrc`, `biome.json`, `pyproject.toml`) for
  enforced rules — don't manually flag what a linter already catches

> **If the project has a linter rule for it, it's not a review finding.**

### Phase 1: Identify Target Files

Parse args or run `git diff --name-only`. Skip generated files, lockfiles, and
vendored code.

### Phase 2: Read and Analyze

Read each target file in full. Run the checklist below, **skipping categories
that don't apply** to this file or language.

### Phase 3: Triage and Report

Apply severity, enforce quantity limits, and produce the report.

---

## Review Dimensions (6 Categories)

### 1. Architecture & Structure

Does the file respect the project's architectural boundaries?

- **Correct layer**: Is the file in the right directory for what it does?
- **No layer violations**: Does it import from layers it shouldn't? (e.g., UI
  importing data layer, logic layer importing UI)
- **Separation of concerns**: One job per file, or mixing responsibilities?
- **Module boundaries**: Cross-module imports going through public APIs, not
  reaching into internal files?
- **Naming consistency**: Do file/class/function names follow this project's
  naming conventions (not generic conventions)?

### 2. Type Safety

Applicable to TypeScript, Flow, or other typed languages.

- **No unsafe casts**: `as any`, `@ts-ignore`, or equivalent without
  justification?
- **Proper null handling**: Nullable values checked before use?
- **Consistent type locations**: Types defined where the project convention
  expects them?
- **Generic usage**: Appropriately scoped — not too broad, not too restrictive?
- **Return types**: Explicit where the project convention requires them?

### 3. State Management

Applicable if the project uses state management (Zustand, Redux, Pinia, MobX,
Context, signals, etc.).

- **Immutable updates**: Mutations done correctly per the library's conventions?
- **Derived state**: Computed values calculated, not stored redundantly?
- **Cleanup**: Subscriptions, listeners, side effects cleaned up on
  unmount/dispose?
- **State shape**: Following the project's established patterns?

### 4. Test Quality

- **Test file exists**: Does the module have a corresponding test file?
- **Test isolation**: State freshly created in `beforeEach`, not shared?
- **Edge cases**: Boundary values and error paths tested?
- **Meaningful assertions**: Testing behavior, not just "doesn't throw"?
- **No flaky patterns**: Timers, random data, or external services without
  proper mocking?

### 5. Performance

- **Resource cleanup**: Event listeners, timers, observers removed on cleanup?
- **Unnecessary re-renders**: In UI frameworks — missing memo, wrong dependency
  arrays?
- **Efficient data structures**: `Map`/`Set` where O(1) lookup matters?
- **Lazy loading**: Heavy imports or computations deferred when possible?

### 6. Security

- **No hardcoded secrets**: API keys, tokens, passwords in code?
- **Input validation**: User input validated/sanitized before use?
- **XSS prevention**: User-provided content properly escaped in UI?
- **SQL injection**: Queries parameterized, not string-concatenated?
- **Dependency safety**: Known vulnerable dependencies?

---

## Severity & Quantity Limits

### Severity Levels

| Level | Definition | Examples |
|-------|-----------|----------|
| **Critical** | Will cause bugs, data loss, or security holes in production | Architecture violations on boundaries, type safety holes on public APIs, security issues, resource leaks |
| **Important** | Won't break production but significantly hurts maintainability | Missing test coverage for complex logic, unclear abstractions, duplicated business logic |
| **Minor** | Cosmetic or stylistic, low impact | Naming inconsistencies, missing docs for internal functions, minor perf concerns |

### Quantity Limits

- **Critical**: Report all. No limit.
- **Important**: Maximum 5 per file. Prioritize by impact.
- **Minor**: Maximum 3 per file. Only if there are fewer than 3 important issues.
  **If there are 3+ important/critical issues, skip minor issues entirely** —
  the author has bigger things to fix.

> **A review with 2 critical findings and nothing else is more valuable than
> one with 2 critical findings buried under 15 minor nits.**

---

## Output Format

For each reviewed file:

```markdown
## Code Review — <relative/path/to/file>

| Category | Result | Issues |
|----------|--------|--------|
| Architecture | ✅ | — |
| Type Safety | ⚠️ 2 issues | 1 critical, 1 minor |
| State Management | N/A | — |
| Test Quality | ⚠️ 1 issue | 1 important |
| Performance | ✅ | — |
| Security | ✅ | — |

### Issues

1. 🔴 **[Type Safety · Critical] L42** — `data as any` bypasses type checking
   on a public API boundary
   > **Fix**: Add a type guard `isValidData(data)` or use a specific type
   > like `ParsedResponse`

2. 🟡 **[Test Quality · Important] L1** — No test file found for module with
   3 exported functions
   > **Fix**: Create `TargetFile.test.ts` covering the two branching paths
   > in `processOrder()`

3. 🔵 **[Type Safety · Minor] L78** — Return type of `getConfig()` is inferred
   as `any` due to dynamic import
   > **Fix**: Add explicit return type `: AppConfig`

### Strengths

- {Genuine positive observation — not filler praise}
```

### Multiple Files

When reviewing multiple files, produce one report per file, then a summary:

```markdown
## Summary — X files reviewed

| File | 🔴 | 🟡 | 🔵 | Verdict |
|------|-----|-----|-----|---------|
| UserService.ts | 0 | 1 | 0 | Clean |
| UserController.ts | 1 | 2 | 1 | Needs Work |

**Overall**: 1 critical, 3 important, 1 minor across 2 files
```

### Verdict per File

| Verdict | Meaning |
|---------|---------|
| **Clean** | No critical or important issues. Ship it. |
| **Needs Work** | Has critical or 3+ important issues. Fix before merging. |
| **Solid** | 1-2 important issues, no critical. Merge-worthy with minor fixes. |

---

## Quality Gate (Self-Check Before Submitting)

Before you submit your review, ask yourself:

1. **Would I mass-reject a PR over any of these findings?** If not, it's not
   critical. Downgrade or drop it.
2. **Is each finding calibrated to THIS project's conventions?** If you're
   enforcing a rule this project doesn't follow, remove it.
3. **If the author fixes every issue I listed, will the code actually get
   better — or just different?** If "just different" → withdraw the finding.
4. **Am I reporting this because there's a real problem, or because I was asked
   to review and feel I need to say something?** If the latter → the code is
   clean. Say so. That's the most valuable review you can give.

> **Remember: "This code is clean and ready to ship" is a valid review result.
> It's infinitely more valuable than three fabricated improvement suggestions
> designed to appear thorough.**
