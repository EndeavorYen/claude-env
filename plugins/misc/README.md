# claude-misc

Personal collection of miscellaneous Claude Code skills and commands.

Installed via [claude-env](https://github.com/EndeavorYen/claude-env) marketplace.

## Structure

```
claude-misc/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── skill-a/
│   │   └── SKILL.md
│   └── skill-b/
│   │   └── SKILL.md
│   └── ...
└── commands/
    ├── command-a.md
    └── ...
```

## How to Add a New Skill

### 1. Create the skill directory and file

```bash
cd ~/claude-misc
mkdir skills/my-new-skill
```

Create `skills/my-new-skill/SKILL.md`:

```markdown
---
name: my-new-skill
description: >
  Brief description of what this skill does and WHEN to trigger it.
  Include trigger phrases like "do X", "run Y", "幫我Z".
---

## Instructions

What Claude should do when this skill is invoked.

## Steps

1. First step
2. Second step
3. ...
```

### 2. Push

```bash
git add -A
git commit -m "add: my-new-skill"
git push
```

### 3. Update on all machines

```bash
claude plugin marketplace update my-env
```

New Claude Code sessions will pick up the skill automatically.

## How to Add a New Command

### 1. Create the command file

Create `commands/my-command.md`:

```markdown
---
name: my-command
description: What /my-command does
arguments:
  - name: target
    description: The target to operate on
    required: true
---

## Instructions

What Claude should do when the user runs `/my-command <target>`.
```

### 2. Push and update (same as skills)

```bash
git add -A && git commit -m "add: /my-command" && git push
claude plugin marketplace update my-env
```

## Skill Writing Tips

- **description** is critical — it determines when Claude auto-triggers the skill
- Include trigger phrases in both English and Chinese if you use both
- Keep skills focused: one skill = one job
- Reference files by relative path if the skill includes helper scripts

## Installation

This plugin is installed via the [claude-env](https://github.com/EndeavorYen/claude-env) umbrella marketplace:

```bash
claude plugin install misc@my-env --scope user
```
