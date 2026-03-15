---
name: verify
description: >-
  Run the full verification pipeline for any project: lint, typecheck, tests,
  security audit, and build. Use when the user says "verify", "check",
  "validate", "run checks", "CI checks", "pre-commit", "驗證", "檢查",
  "make sure everything passes", or before committing / creating a PR. Also
  trigger proactively after any non-trivial code change.
---

# Verify — Pre-flight Quality Gate

Run all project quality checks in the correct order. Fail fast: cheaper checks
run first so you don't wait for a build only to discover a lint error.

## Step 0 — Detect Project Setup

Before running anything, detect the project's tooling:

1. **Package manager** — Check which lock file exists:
   - `bun.lockb` → `bun`
   - `pnpm-lock.yaml` → `pnpm`
   - `yarn.lock` → `yarn`
   - `package-lock.json` → `npm`
   - If none found, default to `npm`

2. **Available scripts** — Read `package.json` `scripts` field. Map to steps:
   - `lint` or `eslint` → Step 1
   - `typecheck` or `tsc` → Step 2
   - `test` → Step 3
   - `build` → Step 5

3. **Non-JS projects** — If no `package.json`, look for:
   - `Makefile` → use `make lint`, `make test`, etc.
   - `Cargo.toml` → `cargo clippy`, `cargo test`, `cargo build`
   - `pyproject.toml` / `setup.py` → `ruff check .`, `pytest`, `python -m build`
   - `go.mod` → `go vet ./...`, `go test ./...`, `go build ./...`

## Execution Order

Run each step **sequentially**. Stop and report on the first failure — do not
skip ahead. The order is deliberate (fastest → slowest):

### Step 1 — Lint

```bash
<pm> lint
```

Catches syntax issues, unused variables, hook violations, and style problems.
If there are auto-fixable errors, offer to run with `--fix` and re-check.

### Step 2 — Typecheck

```bash
<pm> typecheck
```

Only applicable for TypeScript projects. Skip if no `tsconfig.json` exists.
If `typecheck` script isn't defined, try `tsc --noEmit` directly.

### Step 3 — Tests

```bash
<pm> test
```

Runs the project's test suite (Vitest, Jest, pytest, cargo test, etc.).

### Step 4 — Security Audit

```bash
<pm> audit --audit-level=high
```

Checks dependencies for known vulnerabilities. Only flag **high** and
**critical** severity. Skip for non-JS projects that lack `audit` support.

If vulnerabilities are found, list them and suggest fixes. Don't block the
pipeline for moderate-or-below issues.

### Step 5 — Build (optional, on request)

```bash
<pm> build
```

Full production build. Only run if the user explicitly requests it or says
"full verify" / "verify build" / "pre-release check". It's slow and step 2
already covers type errors.

## Reporting

After all steps pass (or on first failure), output a summary table:

```
| Step           | Result | Time   |
|----------------|--------|--------|
| Lint           |   pass |  2.1s  |
| Typecheck      |   pass |  8.3s  |
| Tests          |   pass | 12.7s  |
| Security Audit |   pass |  1.4s  |
| Build          | skip   |   —    |
```

- For failures: show the actual error output, then diagnose and suggest a fix.
- For passes: keep it brief, just the table.

## Fail-fast Behavior

If any step fails:

1. Show the error output clearly
2. Diagnose the root cause
3. Offer to fix it (if it's something you can fix — like a lint error or type mismatch)
4. After fixing, re-run **from the failed step onward** (no need to re-run earlier passing steps)
