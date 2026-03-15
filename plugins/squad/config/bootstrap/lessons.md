# Squad Lessons Learned

Accumulated insights from past missions. Read during RECON to avoid repeating mistakes.

<!-- Entries are appended by the RETRO stage after each mission -->

## Bootstrap Lessons (from plugin development)

### Agent Stale After Deployment
- **Context:** Multiple missions observed agents registering in team config (`backendType: "in-process"`) but never executing.
- **Root cause:** `Task` tool can silently fail — agent is registered but process never starts.
- **Lesson:** Always run startup health check within 3 minutes. Check for `contract-ack.md`. If missing, respawn once then fall back to direct execution.
- **Severity:** Critical — wastes entire session if undetected.

### contract-ack.md Must Be Absolute First Action
- **Context:** Original role-forging had "read CLAUDE.md" as step 1 and "write contract-ack.md" as step 2. Some agents spent time reading files before writing their liveness signal.
- **Lesson:** contract-ack.md is the agent's heartbeat. It must be written BEFORE anything else. The lead uses it to detect stale agents within the startup timeout window.
