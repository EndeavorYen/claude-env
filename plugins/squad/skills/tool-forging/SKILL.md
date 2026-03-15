---
name: tool-forging
description: Use when the squad identifies a tool gap during execution or RETRO — a repetitive manual action that should be automated. Teaches how to create bash scripts for immediate use and formal skills for next-session use.
---

# Tool Forging

When the squad encounters a repetitive manual action — something done 3+ times, or something that could be automated for reliability — forge a tool. Start with the lightest-weight option and only escalate if reuse justifies it.

## Decision Matrix

| Type | Location | When to use | Takes effect |
|------|----------|-------------|--------------|
| **Immediate tool** | `.claude/squad/tools/{name}.sh` | Default choice. Automates a repeated action within the current mission. | Immediately |
| **Persistent skill** | `.claude/skills/{name}/SKILL.md` | Useful across 2+ missions. Teaches a reusable technique or workflow. | Next session |
| **Hook** | Entry in `hooks.json` | Needs to run automatically at a pipeline stage (e.g., post-verify). | Next session |

**Default to immediate.** Only create a persistent skill if the pattern has proven useful across at least 2 separate missions. Only create a hook if the action must run automatically without being invoked.

## Creating Immediate Tools

Write a bash script to `.claude/squad/tools/{name}.sh`:

1. **Include a usage comment** at the top of the script:
   ```bash
   #!/usr/bin/env bash
   # Usage: tools/check-exports.sh <src-dir>
   # Verifies that all public modules have an index.ts barrel export.
   ```

2. **Accept stdin or args** — prefer args for clarity, but support piped input where it makes sense.

3. **Use meaningful exit codes** — `0` for success, `1` for failure, `2` for usage error.

4. **Make it executable**:
   ```bash
   chmod +x .claude/squad/tools/{name}.sh
   ```

5. **Record in tool-patterns.md** — append an entry to `.claude/squad/knowledge/tool-patterns.md` documenting the tool name, purpose, and usage example so future sessions can discover it.

### Example

```bash
#!/usr/bin/env bash
# Usage: tools/count-todo.sh [directory]
# Counts remaining TODO/FIXME comments in the codebase.
set -euo pipefail

dir="${1:-.}"
count=$(grep -rn 'TODO\|FIXME' "$dir" --include='*.ts' --include='*.tsx' | wc -l)
echo "$count TODO/FIXME items found"
[ "$count" -eq 0 ] && exit 0 || exit 1
```

## Creating Persistent Skills

When a pattern proves reusable across missions, promote it to a persistent skill:

1. **Create the directory and SKILL.md** in the project's local skill directory:
   ```
   .claude/skills/{name}/SKILL.md
   ```
   This ensures the skill is project-specific and survives plugin updates (unlike `${CLAUDE_PLUGIN_ROOT}` which is a volatile cache directory).

2. **Write YAML frontmatter** with `name` and `description` fields. The description should state *when* to use the skill so the system can match it to situations.

3. **Teach HOW, not just WHAT** — the body should explain the reasoning, decision points, and steps in enough detail that an agent can follow the technique without prior context. Include examples and edge cases.

4. **Record in tool-patterns.md** — append an entry to `.claude/squad/knowledge/tool-patterns.md` noting the skill name, what it replaced (if it was promoted from an immediate tool), and when to invoke it.

5. **Note**: persistent skills take effect next session. They will not be available in the current session.

## Identifying Tool Gaps

During RETRO (or at any pipeline stage), watch for these signals that a tool should be forged:

- **3+ manual repetitions** — any action performed three or more times by hand is a candidate for a script.
- **Automatable verification steps** — checks that could run as part of VERIFY but are currently done manually (e.g., "make sure all new files have tests").
- **Repeatable info gathering** — queries run repeatedly to understand codebase state (e.g., listing all stores, counting test coverage per module).
- **Fixed-format reporting** — status updates, summaries, or checklists that follow the same structure every time.

When a gap is identified, the member who spots it should either forge the tool immediately (if it is an immediate tool) or flag it in RETRO notes for the lead to decide on promotion to a persistent skill.
