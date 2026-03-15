---
name: design-check
description: >-
  Verify that implementation matches a design document (DESIGN.md, ADR, RFC,
  architecture spec, or any reference doc). Use when the user says "design
  check", "check against design", "對照設計", "architecture compliance", "does
  this match the design", "drift check", "verify design", "符不符合設計",
  or when completing a major milestone. Compares expected files, names, public
  APIs, data models, and dependency directions against the reference document.
---

# Design Check — Design Document Compliance Verifier

Design documents drift from implementation over time — methods get renamed,
files get moved, interfaces evolve. This skill catches that drift early,
before it compounds into architectural debt.

## Input

```
/design-check                              → Auto-detect design doc, check full scope
/design-check <path-to-design-doc>         → Check against a specific document
/design-check <path> --scope <directory>   → Check a specific directory against the doc
```

## Step 1 — Find the Design Document

If no document is specified, look for (in order):

1. `docs/DESIGN.md` or `DESIGN.md`
2. `docs/ARCHITECTURE.md` or `ARCHITECTURE.md`
3. `docs/adr/` (Architecture Decision Records)
4. `docs/rfc/` (Request for Comments)
5. Any `.md` file in `docs/` with "design", "architecture", or "spec" in the name
6. Relevant sections in `README.md`

If multiple are found, ask the user which one to use.
If none found, inform the user and ask them to specify a path.

## Step 2 — Extract the Design Specification

Read the design document and extract:

1. **Expected files** — Every file path or module mentioned
2. **Class/interface/type names** — Every exported identifier mentioned
3. **Public API methods** — Method names, parameters, return types described
4. **Data model types** — Interfaces, schemas, or types defined in the design
5. **Integration points** — Which existing files the design says to modify
6. **Dependency rules** — Allowed import/dependency directions between layers

## Step 3 — Scan the Codebase

For each item from Step 2, check the actual codebase:

### 3a. File Existence

Use Glob to check if every expected file exists:

```
Expected: services/AuthService.ts → ✅ exists
Expected: services/PaymentService.ts → ❌ missing
```

Also check for **unexpected files** in the directory that aren't in the design
(may indicate undocumented features or refactoring that wasn't reflected).

### 3b. Name Consistency

For each class/interface mentioned in the design, verify the actual export name
matches:

```
Design says: class AuthService → Actual: class AuthService ✅
Design says: validateToken() → Actual: verifyToken() ⚠️ renamed
```

### 3c. Public API Comparison

For methods described in the design, check:
- Does the method exist?
- Do parameter names roughly match?
- Does the return type match?

Minor parameter name differences are warnings, not errors. Missing methods or
completely different signatures are errors.

### 3d. Data Model Check

Compare type definitions in the design against actual code:
- Are all expected fields present?
- Are field types compatible?
- Are there extra fields not in the design? (warning, not error)

### 3e. Dependency Direction

For each file, check imports:
- Do imports follow the layer rules specified in the design?
- Are there unexpected cross-layer dependencies?

## Step 4 — Output the Report

```
## Design Compliance Report — <Document Name>

### File Coverage

| Expected (Design Doc) | Actual | Status |
|-----------------------|--------|--------|
| services/AuthService.ts | exists | ✅ |
| services/PaymentService.ts | — | ❌ missing |
| models/User.ts | exists | ✅ |

Unexpected files (not in design doc):
- services/CacheService.ts (not documented — add to design?)

### API Drift

| Design Specification | Actual Implementation | Status |
|---------------------|----------------------|--------|
| AuthService.validateToken() | AuthService.verifyToken() | ⚠️ renamed |
| PaymentService.charge() | — | ❌ missing |

### Data Model Drift

| Type | Field | Design | Actual | Status |
|------|-------|--------|--------|--------|
| User | email | string | string | ✅ |
| User | role | string | — | ❌ missing |
| User | avatar | — | string | ⚠️ undocumented |

### Dependency Violations

None found. ✅
(or list specific violations)

### Summary

- Files: X/Y exist (Z missing)
- API: N renames detected
- Data model: A missing fields, B undocumented fields
- Dependencies: Clean ✅ / M violations

### Recommendations

1. **Missing file**: `PaymentService.ts` — not yet implemented or design outdated?
2. **API rename**: `validateToken` → `verifyToken` — update design or rename method.
3. **Undocumented field**: `avatar` in User — add to design document.
```

## Severity Levels

| Level | Meaning | Action |
|-------|---------|--------|
| ✅ Match | Design and implementation agree | None |
| ⚠️ Drift | Difference exists but code works | Update design doc or rename |
| ❌ Missing | Designed but not implemented | Implement or remove from design |
| ❓ Extra | Implemented but not designed | Document in design doc |

## Bidirectional Sync

Design drift goes both ways:

- **Implementation behind design** — The designed feature hasn't been built yet.
  If there's a roadmap or task tracker, check if it's planned.
- **Implementation ahead of design** — The code has evolved beyond what was
  designed. This is normal, but the design doc should be updated.

Always recommend which direction to sync (update code vs. update design) based
on which version appears more intentional.
