---
name: scaffold-feature
description: >-
  Auto-generate file scaffolding for new features by learning the project's
  conventions. Use when the user says "scaffold", "建骨架", "create new feature",
  "new module", "set up files for", "start implementing", "產生檔案結構",
  or is about to begin work on a new feature that needs multiple files.
  Discovers the project's architecture patterns from existing code and generates
  matching file skeletons with TODO markers.
---

# Scaffold Feature — Convention-Aware Module Generator

Generate the complete file structure for a new feature by learning from the
project's existing conventions. Every generated file matches established
patterns so you start writing business logic immediately, not boilerplate.

## When to Use

- Starting work on a new feature that needs multiple files
- Adding a new module/service/component to an existing project
- The user says "scaffold", "骨架", or "create files for X"

## Step 1 — Learn Project Conventions

Before generating anything, analyze the existing codebase:

### 1a. Detect Architecture Pattern

Scan the project structure to identify the architecture:

| Pattern | Indicators |
|---------|-----------|
| **Layered** (controller/service/repo) | `controllers/`, `services/`, `repositories/` dirs |
| **Feature-based** | `features/`, `modules/` with self-contained dirs |
| **MVC** | `models/`, `views/`, `controllers/` dirs |
| **Clean Architecture** | `domain/`, `application/`, `infrastructure/` dirs |
| **Engine/Store/UI** | `engines/`, `stores/`, `features/` or `components/` |
| **Flat** | All files in `src/` with no clear pattern |

### 1b. Discover File Conventions

From 2-3 existing feature modules, extract:

- **Directory naming**: kebab-case, camelCase, PascalCase?
- **File naming**: `UserService.ts`, `user-service.ts`, `user.service.ts`?
- **File header style**: Block comments, JSDoc, no headers?
- **Export style**: Named exports, default exports, barrel files (`index.ts`)?
- **Test location**: Colocated (`*.test.ts`) or separate (`__tests__/`)?
- **Type location**: Colocated, shared `types/` dir, or inline?

### 1c. Check Design Documents

Look for `DESIGN.md`, `ARCHITECTURE.md`, or `README.md` that describes the
expected structure for new features. If found, follow those specifications.

## Step 2 — Gather Requirements

Ask the user (or infer from context):

1. **Feature name** — e.g., "Authentication", "NotificationService", "DarkTheme"
2. **Which layers?** — Based on the detected architecture, present relevant
   options. Default: all layers.
3. **Brief description** — One line about what this feature does (for file
   headers and TODO guidance)

If the user already specified details, skip asking.

## Step 3 — Derive Names

From the feature name, derive all identifiers following the project's
conventions:

Example (project uses PascalCase files, kebab-case dirs):

| Concept | Generated |
|---------|-----------|
| Class/component | `Authentication` |
| Directory | `authentication/` |
| Service file | `AuthenticationService.ts` |
| Test file | `AuthenticationService.test.ts` |
| Types file | `authentication.types.ts` |

## Step 4 — Generate Files

Create each file using templates derived from existing code in the project.
Mark business logic locations with `// TODO:` comments.

### Key Principles

- **Mirror existing patterns exactly** — copy the import style, export style,
  class structure, and documentation style from existing modules
- **TODO markers for decisions** — Never generate business logic. Mark every
  decision point the user needs to make:
  ```typescript
  // TODO: Define validation rules for user input
  // TODO: Choose error handling strategy (throw vs. return Result)
  ```
- **Always include test files** — Even if the user didn't ask. Generate test
  skeletons with `beforeEach` setup and TODO assertions.
- **Include types** — Generate interface/type definitions in the project's
  preferred location

### Template Structure

For each layer, generate a file that includes:

1. **File header** matching the project's style
2. **Imports** from appropriate layers
3. **Type definitions** or interface stubs
4. **Class/function skeleton** with method signatures
5. **Cleanup/dispose** method if the project uses that pattern
6. **TODO markers** at every decision point

## Step 5 — Post-Scaffold Report

After generating files, tell the user:

```
Created N files for <FeatureName>:

<Layer 1>:
  - path/to/File1.ts (X TODOs)
  - path/to/File1.test.ts (Y TODOs)

<Layer 2>:
  - path/to/File2.ts (X TODOs)

Integration needed:
  - List existing files that need changes to wire in the new feature
  - e.g., "App.tsx — add route for new page"
  - e.g., "index.ts — add barrel export"

Next steps:
  1. Fill in the TODO markers with your business logic
  2. Wire the feature into existing integration points
  3. Run tests to verify the skeleton compiles
```

## Important Conventions

- **Never generate business logic** — only scaffolding with TODO markers. The
  user's domain decisions are more valuable than auto-generated guesses.
- **Always include test files** — Testing is part of scaffolding, not an
  afterthought.
- **Follow existing naming exactly** — check existing files for how directories
  and files are named. Don't impose a different convention.
- **Check before creating** — Use Glob to verify files don't already exist
  before writing. Warn if overwriting.
