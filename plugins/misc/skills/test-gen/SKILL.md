---
name: test-gen
description: >-
  Generate test scaffolding for source files by analyzing their public API. Use
  when the user says "generate tests", "write tests", "寫測試", "test this",
  "add tests for", "test coverage", "產生測試", or when you notice a module
  lacks a corresponding test file. Analyzes public methods, interfaces, state
  transitions, and boundary constants to produce a structured test skeleton with
  describe/it blocks, setup hooks, spies, and TODO markers for assertions.
---

# Test Gen — Test Skeleton Generator

Analyze a source file and produce a comprehensive test skeleton. The skeleton
captures the structure (what to test); the user fills in the assertions (how
to verify).

## Why Skeletons, Not Complete Tests

Auto-generated "complete" tests tend to test the obvious and miss the subtle.
A test like `expect(result).toBeDefined()` gives false confidence. By generating
the structure with TODO markers, each test forces the developer to think about
what the correct assertion actually is.

## Input

```
/test-gen <path-to-source-file>
```

If no argument: ask the user which file to generate tests for.

## Step 0 — Detect Test Framework

Before generating, detect the project's test setup:

1. Check `package.json` devDependencies:
   - `vitest` → Vitest (import from `vitest`)
   - `jest` → Jest (import from `@jest/globals` or global)
   - `mocha` + `chai` → Mocha/Chai
2. Check for config files: `vitest.config.*`, `jest.config.*`, `.mocharc.*`
3. For non-JS projects:
   - `Cargo.toml` → Rust `#[cfg(test)]` module
   - `pyproject.toml` / `pytest` → Python pytest
   - `go.mod` → Go `_test.go` files
4. Default: Vitest (most common in modern TS projects)

Also detect:
- **Test file location**: Check if project uses colocated tests (`*.test.ts`
  alongside source) or a separate `__tests__/` directory. Match the convention.
- **Mock utilities**: Check for `vi.fn()` (Vitest), `jest.fn()` (Jest), or
  custom mock helpers.

## Step 1 — Analyze the Source File

Read the target file and extract:

| What | How to Find It |
|------|----------------|
| **Public methods** | Exported functions, public class methods (no `private`/`_` prefix) |
| **Interfaces/types** | Exported interfaces — each property can become a contract test |
| **Constructor params** | Required setup for `beforeEach` |
| **Getters/setters** | Paired getter → setter tests (set value, read it back) |
| **Constants** | `static MIN`, `static MAX`, enums → boundary tests |
| **State transitions** | Methods that change internal state → sequence tests |
| **Return types** | `boolean` returns → true/false paths; `void` → side-effect tests |
| **Guard clauses** | Early returns, `if (x < 0) return false` → negative tests |
| **Dependencies** | Imports that may need mocking (external services, DB, etc.) |

## Step 2 — Determine Test Categories

For each public method, generate tests in these categories:

1. **Happy path** — Normal expected usage with valid inputs
2. **Edge cases** — Boundary values (0, MIN, MAX, empty array, null-ish states)
3. **Error/guard paths** — What happens with invalid inputs (return false, throw, no-op)
4. **Side-effect verification** — If the method triggers callbacks or events, verify with spies
5. **State transitions** — If the method changes state, verify before/after

## Step 3 — Generate the Test File

Write the test file following the detected framework conventions. Example for Vitest:

```typescript
import { describe, it, expect, beforeEach, vi } from "vitest";
import { TargetClass } from "./TargetClass";

describe("TargetClass", () => {
  let instance: TargetClass;

  beforeEach(() => {
    instance = new TargetClass(/* default constructor args */);
  });

  // ─── Construction ──────────────────────────────────────────

  describe("constructor", () => {
    it("should initialize with default values", () => {
      // TODO: Assert initial state via getters
    });

    it("should accept custom parameters", () => {
      // TODO: Pass non-default args, verify state
    });
  });

  // ─── Public Method: methodName ─────────────────────────────

  describe("methodName", () => {
    it("should [expected behavior] when [valid input]", () => {
      // TODO: implement — happy path
    });

    it("should return false when [invalid input]", () => {
      // TODO: implement — guard clause
    });

    it("should handle boundary value MIN", () => {
      // TODO: implement — boundary
    });

    it("should handle boundary value MAX", () => {
      // TODO: implement — boundary
    });
  });

  // ─── Side Effects ─────────────────────────────────────────

  describe("event/callback behavior", () => {
    it("should trigger [event] when [condition]", () => {
      const handler = vi.fn();
      // TODO: register handler, trigger condition
      // expect(handler).toHaveBeenCalledWith(/* expected args */);
    });
  });

  // ─── State Transitions ────────────────────────────────────

  describe("state transitions", () => {
    it("should transition from [state A] to [state B]", () => {
      // TODO: implement — verify getter before and after
    });
  });

  // ─── Cleanup ──────────────────────────────────────────────

  describe("dispose/cleanup", () => {
    it("should clean up resources", () => {
      // TODO: dispose and verify cleanup
    });
  });
});
```

### Adaptation for Other Frameworks

**For state management stores** (Zustand, Pinia, Redux, etc.):

```typescript
describe("useMyStore", () => {
  beforeEach(() => {
    // TODO: Reset store to initial state
  });

  it("should update state immutably", () => {
    // TODO: Capture state before, perform action, compare references
  });
});
```

**For React/Vue components**: Use the project's testing library (`@testing-library/react`, `@vue/test-utils`, etc.).

**For API/service modules**: Mock external dependencies (fetch, DB clients).

## Step 4 — Report

After generating the test file, output:

```
Generated: path/to/TargetClass.test.ts

| Category | Tests | TODO Count |
|----------|-------|------------|
| Construction | 2 | 2 |
| methodName | 4 | 4 |
| Side effects | 1 | 1 |
| State transitions | 1 | 1 |
| Cleanup | 1 | 1 |
| **Total** | **9** | **9** |

Fill in the TODO assertions, then run your test command.
```

## Conventions

- Match the project's existing test file location (colocated vs `__tests__/`)
- Use the project's test framework import style
- Use `beforeEach` to create fresh instances — never share mutable state between tests
- Name test cases as `"should [behavior] when [condition]"`
- Use section divider comments for readability
- **Never generate complete assertions** — use TODO markers for the user to fill in
