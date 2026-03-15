---
name: code-review
description: >-
  Deep file-level code review against the project's own architecture conventions.
  Use when the user says "review", "code review", "審查", "check quality",
  "review this file", "review my changes", or asks you to look at code for
  issues. Also trigger proactively after completing a significant feature.
  Covers 6 categories: architecture/structure, type safety, state management,
  test quality, performance, and security.
---

# Code Review — Deep File Audit

Review files against the project's established conventions. This is not a
generic style check — every finding should be calibrated to patterns actually
used in **this** codebase.

## Input Modes

| Invocation | Behavior |
|------------|----------|
| `/code-review` (no args) | Review files changed in `git diff` (staged + unstaged) |
| `/code-review <path>` | Review a specific file or all source files in a directory |

## Execution Steps

1. **Identify target files** — parse args or run `git diff --name-only`
2. **Learn the project's conventions** — before reviewing, quickly scan:
   - `CLAUDE.md` / `CONTRIBUTING.md` / `DESIGN.md` for documented conventions
   - 2-3 existing files in the same directory to see established patterns
   - `tsconfig.json` / `eslintrc` / `biome.json` for configured rules
3. **Read each target file** in full
4. **Run the checklist** below, skipping categories that don't apply
5. **Output the report** in the format specified at the bottom

---

## Checklist (6 Categories)

### 1. Architecture & Structure

Check whether the file respects the project's architectural boundaries.

- [ ] **Correct layer**: Is the file in the right directory for what it does?
- [ ] **No layer violations**: Does the file import from layers it shouldn't?
      (e.g., UI importing from data layer, logic layer importing from UI)
- [ ] **Separation of concerns**: Is the file doing one job, or mixing
      responsibilities (logic + rendering, data access + validation)?
- [ ] **Module boundaries**: Are cross-module imports going through public APIs,
      not reaching into internal files?
- [ ] **Naming consistency**: Do file/class/function names follow the project's
      naming conventions?

### 2. Type Safety

Applicable to TypeScript, Flow, or other typed languages.

- [ ] **No unsafe casts**: Are there `as any`, `@ts-ignore`, or equivalent
      suppressions without justification?
- [ ] **Proper null handling**: Are nullable values checked before use?
- [ ] **Consistent type locations**: Are types defined where the project
      convention expects them (shared types file, colocated, etc.)?
- [ ] **Generic usage**: Are generics used appropriately (not too broad, not
      too restrictive)?
- [ ] **Return types**: Are function return types explicit where the project
      convention requires them?

### 3. State Management

Applicable if the project uses any state management (Zustand, Redux, Pinia,
MobX, Context, signals, etc.).

- [ ] **Immutable updates**: Are state mutations done correctly per the
      library's conventions (new objects/arrays, not in-place mutation)?
- [ ] **Derived state**: Are computed/derived values calculated correctly
      (not stored redundantly)?
- [ ] **Cleanup**: Are subscriptions, listeners, or side effects properly
      cleaned up on unmount/dispose?
- [ ] **State shape**: Does the state follow the project's established patterns?

### 4. Test Quality

- [ ] **Test file exists**: Does the module have a corresponding test file?
- [ ] **Test isolation**: Is state freshly created in `beforeEach`, not shared
      across tests?
- [ ] **Edge cases**: Are boundary values and error paths tested?
- [ ] **Meaningful assertions**: Are tests asserting behavior, not just that
      code doesn't throw?
- [ ] **No flaky patterns**: Are tests using timers, random data, or external
      services without proper mocking?

### 5. Performance

- [ ] **Resource cleanup**: Are event listeners, timers, observers removed on
      cleanup?
- [ ] **Unnecessary re-renders**: In UI frameworks — are components
      re-rendering more than needed? (missing memo, wrong dependency arrays)
- [ ] **Efficient data structures**: Are `Map`/`Set` used where O(1) lookup
      matters, not linear scans?
- [ ] **Lazy loading**: Are heavy imports or computations deferred when
      possible?

### 6. Security

- [ ] **No hardcoded secrets**: API keys, tokens, passwords in code?
- [ ] **Input validation**: Is user input validated/sanitized before use?
- [ ] **XSS prevention**: Is user-provided content properly escaped in UI?
- [ ] **SQL injection**: Are queries parameterized (not string-concatenated)?
- [ ] **Dependency safety**: Are there known vulnerable dependencies?

---

## Output Format

For each reviewed file:

```
## Code Review — <relative/path/to/file>

| Category | Result | Issues |
|----------|--------|--------|
| Architecture | 4/4 | — |
| Type Safety | 3/5 | 2 issues |
| State Management | N/A | (no state) |
| Test Quality | 2/4 | 2 issues |
| Performance | 4/4 | — |
| Security | 5/5 | — |

**Overall**: X issues found (Y critical, Z minor)

### Issues

1. **[Type Safety] L42** `data as any` — unsafe cast without justification
   > Suggestion: Add a type guard or use a specific type

2. **[Test Quality] L1** No test file found
   > Suggestion: Create `TargetFile.test.ts` with key behavior tests

### Highlights

- Clean separation of concerns
- Good use of discriminated unions
```

### Severity Levels

- **Critical**: Architecture violations, type safety holes on boundaries,
  security issues, memory/resource leaks
- **Minor**: Missing tests, missing docs, naming inconsistencies, minor
  performance concerns

### Multiple Files

When reviewing multiple files, produce one report per file, then a summary:

```
## Summary — X files reviewed

| File | Critical | Minor | Score |
|------|----------|-------|-------|
| UserService.ts | 0 | 1 | 29/30 |
| UserController.ts | 1 | 2 | 25/30 |

Total: 1 critical, 3 minor across 2 files
```
