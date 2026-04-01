---
name: write-doc
description: >-
  Write or improve Markdown documents (including README) with clear structure,
  practical examples, and repository-consistent style.
  Trigger when the user asks to write, rewrite, polish, or professionalize any
  .md document (e.g. "write doc", "write README", "improve docs", "polish document").
  Do not trigger for pure translation, non-Markdown editing, or tiny typo-only
  fixes unless the user explicitly asks for documentation authorship.
---

# write-doc - Markdown document authorship

Write short, scannable Markdown that helps readers act quickly. Less is more — every sentence must earn its place.

## Operating principles

1. **Less is more.**
   Readers absorb less when there is more text. Cut ruthlessly. A shorter doc that gets read beats a thorough doc that gets skipped.
2. **Repository conventions override this skill.**
   If the repo already has style rules (CONTRIBUTING, docs style guide, existing docs voice, markdownlint config), follow those first.
3. **Deliver a complete first draft by default.**
   Do not force outline approval loops unless the request is ambiguous or high-risk.
4. **Treat formatting rules as heuristics, not absolute laws.**
   Optimize for clarity and consistency in the target project.
5. **Be explicit about verification.**
   If code snippets or links were not executed/checked, state that clearly.

## Trigger boundaries

### Use this skill when

- The user asks to create or improve Markdown docs.
- The task involves README quality, structure, clarity, or examples.
- The output needs a polished, publication-ready Markdown artifact.

### Do not use this skill when

- The task is pure translation only.
- The user only wants minor typo fixes without structural/doc-writing work.
- The target is not Markdown (unless the user asks to produce Markdown output).

## Anti-pattern self-check

Before writing, verify you're not falling into these traps:

| Trap | Symptom | Fix |
|------|---------|-----|
| **Verbose filler** | "In today's rapidly evolving landscape..." | Delete the sentence. If nothing is lost, it was filler. |
| **Over-structuring** | 8 headings for a 30-line doc | Flatten. If a section has < 3 lines of content, merge it up. |
| **Marketing voice** | "powerful", "seamless", "robust" | Replace with a concrete claim or delete. |
| **Burying the lead** | 3 paragraphs before the reader learns what this does | Move the action/answer to line 1. |
| **Phantom sections** | Headings filled with padding to look thorough | Delete the heading entirely. |
| **Wall of text** | Any paragraph > 3 lines with no visual break | Split, convert to list, or add a table. |
| **Equal-weight everything** | Every item bold, every section same length | Use emphasis sparingly — if everything is highlighted, nothing is. |

**If your draft smells like any of the above, cut it before delivering.**

---

## Workflow

### Phase 0 - quick context gathering

Before writing, gather only what is necessary:

1. **Document type**
   README, API reference, tutorial, architecture note, changelog, runbook, or general doc.
2. **Audience**
   End users, developers, internal operators, or mixed readers.
3. **Project context**
   Existing docs, code layout, package/tooling, and tone conventions.
4. **Constraints**
   Required sections, word limits, required commands/examples, localization needs.

If context is missing, make reasonable assumptions and continue. Ask questions only when ambiguity can cause major rework.

### Phase 1 - structure and layout

Build a clear skeleton first, then fill it quickly.

#### Default behavior

- **Default**: deliver full draft directly.
- **Outline-first mode**: use only when request is vague, high-stakes, or user explicitly asks for an outline first.

#### Skeleton template

Every document starts with a TL;DR block. No exceptions.

```markdown
# Title

> **TL;DR** — 1-3 sentences. What this is, what the reader can do with it, and the single most important thing to know. A reader who stops here should still get value.

## Quick start or key outcome
## Core details
## Advanced or reference (link out if lengthy)
```

#### Summary-first rule

Each section's first sentence must be the **conclusion or takeaway** of that section. Details follow. A reader who reads only first sentences should understand the full story.

#### Density budget

These are defaults. Adjust for document type, but always justify exceeding them.

| Scope | Budget |
|-------|--------|
| TL;DR block | ≤ 3 sentences |
| Any single section | ≤ 15 lines of content (excluding code blocks) |
| Any single paragraph | ≤ 3 lines — longer paragraphs must be split or converted to a list |
| Entire README | ≤ 300 words of prose (code blocks excluded) |
| Entire tutorial | ≤ 800 words of prose |
| Other docs | ≤ 600 words of prose unless complexity demands more |

When a section exceeds its budget: split into sub-sections, convert prose to table/list, or move details to a linked sub-document.

#### Scannable-first format defaults

Choose format by information type — prose is the last resort, not the default.

| Information type | Preferred format |
|-----------------|-----------------|
| Comparisons, options, feature lists | Table |
| Steps, procedures, ordered items | Numbered list (one line per step) |
| Requirements, properties, items | Bullet list |
| Rationale, trade-offs, narrative context | Short prose (≤ 3 lines per paragraph) |

#### Whitespace as design

Whitespace is not wasted space — it directs the reader's eye.

- One blank line after every heading, paragraph, list, table, and code block.
- `---` only at major topic shifts (≤ 2 per document).
- If a screen of text has no visual break, it needs one.

#### Emphasis heuristics

- Use `code` for commands, paths, identifiers, and config keys.
- Use **bold** sparingly — if more than ~2 items per section are bold, nothing stands out.
- Do not use emojis. They add visual noise without information value. Follow existing repo conventions if they already use emojis.
- Avoid decorative formatting that does not improve scanning.

#### Heading heuristics

- Keep headings short and descriptive.
- If a section has < 3 lines of content, it probably doesn't need its own heading — merge it.
- Keep heading style consistent within the same document.
- Avoid skipping levels unless repo conventions explicitly allow it.

### Phase 2 - drafting

#### Tone by document type

| Type | Tone | Primary goal |
|---|---|---|
| README | Clear, confident, action-oriented | Activation |
| API docs | Precise, neutral | Correctness |
| Tutorial | Supportive, step-by-step | Learnability |
| Architecture | Analytical, tradeoff-aware | Shared understanding |
| Changelog | Concise, factual | Fast scanning |

#### Code examples

- Always fence code blocks with language labels (`bash`, `ts`, `json`, etc.).
- Use realistic examples and expected outputs.
- Keep examples minimal but runnable in principle.
- If behavior changed, include before/after examples.

#### Linking strategy

- Prefer relative links for in-repo docs.
- Use inline links for one-off references.
- Use reference-style links if the same URL appears repeatedly.

### Phase 2.5 - cut pass

After drafting, do a dedicated editing pass with one goal: **make it shorter.**

1. Re-read every paragraph. Delete any sentence where removing it loses nothing.
2. Check every section against the density budget. If over, cut or restructure.
3. Look for repeated ideas across sections. Say it once, in the best place.
4. Convert any remaining prose paragraph > 3 lines into a list or table.
5. Remove qualifiers and hedging ("it should be noted that", "it is important to", "basically", "essentially").

**Target: cut ≥ 20% of word count from the first draft.** If you cannot find 20% to cut, the first draft was already tight — good. But always look.

### Phase 3 - validation and polish

Before final delivery, run project-configured linters if available (`markdownlint`, `lychee`, etc.). If unavailable, perform manual checks and explicitly label items as "not tool-verified".

#### Final quality gate

- [ ] TL;DR block exists and is ≤ 3 sentences.
- [ ] First paragraph explains what this is and why it matters.
- [ ] Headings alone communicate the document storyline.
- [ ] No section exceeds 15 lines of prose content.
- [ ] No paragraph exceeds 3 lines.
- [ ] Prose word count is within budget for document type.
- [ ] Commands/snippets are syntactically plausible and copy-paste friendly.
- [ ] Internal links and anchors are valid (or flagged if unverified).
- [ ] Formatting is consistent with repository conventions.
- [ ] A cut pass was performed — no obvious filler, hedging, or repetition remains.

## README specialization

Use this mode when file target is `README.md` or user explicitly requests README work.

### README objective

A README should improve **discoverability** and **activation** quickly.

1. Readers understand what the project does.
2. Readers can run or try it fast.
3. Readers can find deeper docs if needed.

### Choose README mode by project type

| Mode | Typical project | Emphasis |
|---|---|---|
| Open-source product | public library/app | value proposition, quick start, install, usage, contribution |
| Internal service/tool | team-facing repo | context, prerequisites, operational steps, ownership |
| Infrastructure/ops | deployment/platform repo | architecture, environments, rollout/rollback, safety notes |

### README structure template

```markdown
# Project name

> **TL;DR** — What this does and why you'd use it, in 1-2 sentences.

## Quick start       ← reader should reach runnable code within 10 lines
## What this does    ← only if quick start alone isn't self-explanatory
## Configuration     ← only if there are user-facing options
## Troubleshooting   ← only if common pitfalls exist
```

**Only include sections that earn their space.** A 4-section README that gets read is better than an 8-section one that doesn't.

### README anti-patterns

- Long intro before any runnable example.
- Table of contents for a README that fits on one screen.
- Feature lists with no concrete benefit language.
- Placeholder sections (`TODO`, empty headings) in final output.

## Output contract

When producing or editing docs:

1. Deliver a complete Markdown draft unless user asks for outline-only.
2. Preserve repo voice and terminology.
3. Prefer actionable examples over abstract prose.
4. Call out unverified commands/links explicitly.
5. Recommend follow-up checks only when they add clear value.
