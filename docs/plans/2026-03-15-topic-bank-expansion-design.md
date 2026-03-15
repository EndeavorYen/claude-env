# Topic Bank Expansion Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Expand the Topic Bank from 12 one-line categories to 12 categories with ~80 sub-topics, giving JUDGE concrete guidance while preserving RED team creative freedom.

**Architecture:** Single file edit — replace the Topic Bank section in `docs/against_rule.md` (lines 383-402) with expanded version including introduction, summary table, and sub-topic lists.

**Tech Stack:** Markdown only.

---

# Topic Bank Expansion Design

## Summary

Expand the adversarial protocol's Topic Bank from 12 one-line categories to 12 categories with 5-8 sub-topics each (~80 sub-topics total), giving the JUDGE concrete topic selection guidance while preserving flexibility for creative attacks.

## Design Decisions

### Format: Table overview + sub-topic lists (Option A)
- Keep the summary table for quick scanning
- Add sub-topic bullet lists below each category
- One line per sub-topic, no attack methodology prescribed

### Flexibility principles
- Topic Bank is **inspiration, not a checklist**
- RED team attacks freely within safe boundaries — sub-topics give direction, not constraints
- Technology-stack agnostic — JUDGE adapts to project's actual language/framework
- JUDGE can create custom topics beyond the bank

### Two-layer depth framework
Every sub-topic has two layers:
- **Layer 1 (Does it exist?)** — Is the mechanism in place? → Round 1
- **Layer 2 (Is it good?)** — Is the quality sufficient? Is there a better approach? → Round 2-3

This is stated as a general principle, not repeated per sub-topic.

## Topic Bank Content

### 1. Functional Correctness (6 sub-topics)
- All entry points (CLI / API / UI action) actually executable
- Claimed features have complete implementation (vs NotImplementedError / TODO / pass)
- Input/output contracts match documentation or type signatures
- Alternative flows beyond happy path are handled (empty input, no data, first use)
- Cross-module feature chains work end-to-end (vs modules work individually but fail together)
- Backward compatibility maintained after version upgrades or migrations

### 2. Error Handling (6 sub-topics)
- Errors not silently swallowed (try-catch with only pass / log but no handling)
- Error messages meaningful to users (vs raw stack traces or generic "Something went wrong")
- Errors propagate correctly upward (vs truncated at middle layer, caller unaware of failure)
- Degradation strategy for external dependency failures (API timeout, DB disconnect, missing files)
- Partial success scenarios handled (batch operation fails midway — what about completed items?)
- Error recovery paths testable (retry logic, fallback mechanisms actually triggerable)

### 3. Architecture / Design (7 sub-topics)
- Dependency direction reasonable (no bottom-layer depending on top-layer)
- Abstraction levels consistent within same layer
- No unnecessary middle layers or over-abstraction (wrapper of wrapper)
- Duplicated logic not scattered across codebase (similar but subtly different implementations)
- Module boundaries clear (changing one feature requires touching how many unrelated files)
- Data transformation count reasonable (same data serialized/deserialized how many times)
- Number of files to modify when extending with new features is reasonable

### 4. Security (7 sub-topics)
- User input validated and sanitized at trust boundaries
- Sensitive data (passwords, tokens, API keys) not in logs, error messages, or version control
- Permission checks at every required point (vs only at entry, bypassed internally)
- Third-party dependencies checked for known vulnerabilities (supply chain security)
- Serialization/deserialization free from injection risks
- Authentication state timeliness managed (session/token expiry, revocation)
- Error messages don't leak system internals (paths, versions, stack traces)

### 5. Performance (7 sub-topics)
- No unnecessary repeated calculations (same result recomputed in multiple places vs cached)
- No N+1 query problems (per-item queries in loops vs batch fetching)
- Large data processing has streaming/pagination (vs loading everything into memory)
- Startup time reasonable (no unnecessary initialization at launch)
- Parallelizable work not executed sequentially
- Caching strategy reasonable (should-cache not cached, shouldn't-cache cached, invalidation timing)
- Resources properly released (connections, file handles, temp files)

### 6. Test Quality (7 sub-topics)
- Tests actually verify behavior (vs calling function without asserting results)
- Edge cases for critical paths covered (boundary values, null, extremely large input)
- Mock scope reasonable (over-mocking causing test/reality divergence)
- No hidden dependencies between tests (execution order affecting results, shared global state)
- Test failure messages help locate problems (vs just "AssertionError")
- Tests easy to maintain (how many tests break from one small feature change)
- No eternally-passing tests (conditions always true, silently skipped)

### 7. UI/UX (8 sub-topics)
- Visual design quality — color harmony, comfortable spacing, clear typography hierarchy
- Component design standard — buttons, forms, cards deliberately designed (vs raw framework defaults)
- Cross-page design consistency — colors, border-radius, shadows, animations unified
- Interaction design quality — smooth intuitive flows, natural transitions, meaningful immediate feedback
- Information architecture — user finds target function within 3 seconds
- Empty/error state design — no-data, error, loading screens intentionally designed
- Design detail polish — hover effects, focus states, transition animations, icon selection
- Overall design matches product positioning (professional tool looking like student project = critical)

### 8. Documentation Quality (6 sub-topics)
- README description matches actual behavior (vs outdated or initial template)
- Installation/setup steps followable end-to-end (newcomer can run project from docs alone)
- API documentation params, return values, error codes match actual behavior
- Code comments still reflect current state (vs code changed but comments unchanged)
- Architecture decisions recorded (why this approach and not that one)
- Contribution guide exists and is practical (how to run tests, submit PR, code style)

### 9. DevOps / CI (6 sub-topics)
- CI pipeline covers all critical checks (lint, type check, test, build)
- Deployment process repeatable and predictable (vs depending on manual steps or specific person's environment)
- Rollback mechanism exists and has been verified
- Environment differences (dev/staging/prod) managed and documented
- Pipeline execution time reasonable (parallelizable or cacheable steps)
- Post-deployment health checks and monitoring alerts in place

### 10. Configuration Consistency (6 sub-topics)
- Config has unified source (vs scattered across code, env vars, config files, hard-coded values)
- Defaults reasonable and documented (newcomer knows default behavior without reading source)
- Sensitive config (secrets, tokens) separated from general config
- Cross-environment config differences explicitly trackable
- Config change requirements clear (restart needed? hot reload? change logged?)
- Config item dependencies and mutual exclusions validated

### 11. Type Safety (6 sub-topics)
- No type system bypasses (any / as / type: ignore / forced casts)
- Function signatures accurately reflect actual behavior (declares string return but may return null)
- External data has runtime type validation at system entry (API responses, user input, file reads)
- Generics used appropriately (vs any or Object everywhere)
- Type definitions in sync with actual data structures (schema changed but type not updated)
- Union type / optional exhaustive handling complete (no missed cases)

### 12. State Management (6 sub-topics)
- Same state doesn't have multiple sources (which is source of truth?)
- State update timing predictable (no race conditions or update order dependencies)
- Cache-source consistency maintained (cache invalidation strategy)
- No unnecessary global state sharing (vs should be local scope)
- State lifecycle clear (when created, when updated, when cleaned up)
- Concurrent modification conflict handling mechanism

## Implementation

### Task 1: Replace Topic Bank in against_rule.md

**Files:**
- Modify: `docs/against_rule.md:383-402` (replace current Topic Bank section)

**Step 1: Replace the Topic Bank section**

Replace lines 383-402 (from `### Topic Bank（建議題庫）` to the last table row before `### Phase 1~N`) with the expanded version containing:
1. Updated introduction with flexibility principles and two-layer depth framework
2. Summary table (12 categories, one-line each — same as current but with refined descriptions)
3. Sub-topic lists below each category (content from "Topic Bank Content" section above)

All content should be in Chinese (matching the rest of the document), translated from the English design above.

**Step 2: Verify no broken references**

Check that:
- The JUDGE Phase 0 Prompt Template still references "Topic Bank" correctly
- The `### Phase 1~N：沉默觀察` section immediately follows the Topic Bank
- No markdown formatting is broken

**Step 3: Commit**

```bash
git add docs/against_rule.md
git commit -m "docs: expand Topic Bank with ~80 sub-topics across 12 categories"
```
