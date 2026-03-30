---
name: write-doc
description: >-
  Write or improve Markdown documents (including README) with clear structure,
  practical examples, and repository-consistent style.
  Trigger when the user asks to write, rewrite, polish, or professionalize any
  .md document (e.g. "write doc", "write README", "改善文件", "文件撰寫").
  Do not trigger for pure translation, non-Markdown editing, or tiny typo-only
  fixes unless the user explicitly asks for documentation authorship.
---

# write-doc - Markdown document authorship

Write professional, scannable Markdown that helps readers take action quickly.

## Operating principles

1. **Repository conventions override this skill.**
   If the repo already has style rules (CONTRIBUTING, docs style guide, existing docs voice, markdownlint config), follow those first.
2. **Deliver a complete first draft by default.**
   Do not force outline approval loops unless the request is ambiguous or high-risk.
3. **Treat formatting rules as heuristics, not absolute laws.**
   Optimize for clarity and consistency in the target project.
4. **Be explicit about verification.**
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

### Phase 1 - structure design

Build a clear skeleton first, then fill it quickly.

#### Default behavior

- **Default**: deliver full draft directly.
- **Outline-first mode**: use only when request is vague, high-stakes, or user explicitly asks for an outline first.

#### Skeleton template

```markdown
# Title

One- to two-sentence summary of what this is and why it matters.

## Quick start or key outcome
## Core details
## Advanced or reference
## Troubleshooting / FAQ (if needed)
```

### Phase 1.5 - layout and readability heuristics

Use these as defaults, then adapt to repo style.

#### Spacing heuristics

- Leave one blank line after headings, paragraphs, lists, tables, and code blocks.
- Use section dividers (`---`) only at major topic shifts.
- Avoid visually dense sections with no breaks.

#### Density heuristics

- One idea per paragraph when possible.
- Prefer splitting very long lists with subheadings.
- Use tables for comparisons and option matrices.
- Use prose for narrative flow; use lists for scan targets.

#### Emphasis heuristics

- Use `code` for commands, paths, identifiers, and config keys.
- Use **bold** for truly important terms, not every line.
- Avoid decorative formatting that does not improve scanning.

#### Heading heuristics

- Keep headings short and descriptive.
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

### Phase 3 - validation and polish

Before final delivery, run applicable checks when tools are available.

#### Optional verification commands

```bash
# style/lint (example)
npx markdownlint-cli2 "**/*.md"

# link check (example)
lychee README.md
```

If these tools are unavailable, perform manual checks and explicitly label items as "not tool-verified".

#### Final quality gate

- [ ] First paragraph explains what this is and why it matters.
- [ ] Headings alone communicate the document storyline.
- [ ] Commands/snippets are syntactically plausible and copy-paste friendly.
- [ ] Internal links and anchors are valid (or flagged if unverified).
- [ ] Formatting is consistent with repository conventions.
- [ ] Assumptions are explicit where context was missing.

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

One-line value statement.

## What this does
## Quick start
## Prerequisites and installation
## Usage
## Configuration
## Troubleshooting
## Contributing / Ownership
## License (if applicable)
```

Not every section is required. Keep only sections that create reader value.

### README anti-patterns

- Long generic intro before any actionable example.
- Table of contents in the first screen for short READMEs.
- Feature lists with no user benefit language.
- Outdated badges/screenshots that reduce trust.
- Placeholder sections (`TODO`, empty headings) left in final output.

## Output contract

When producing or editing docs:

1. Deliver a complete Markdown draft unless user asks for outline-only.
2. Preserve repo voice and terminology.
3. Prefer actionable examples over abstract prose.
4. Call out unverified commands/links explicitly.
5. Recommend follow-up checks only when they add clear value.
