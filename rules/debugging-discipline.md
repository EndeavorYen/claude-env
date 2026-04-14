# Debugging discipline

Use this rule when investigating bugs, regressions, flaky behavior, or surprising outputs.

- Trace root cause before patching symptoms.
- When something is broken, collect evidence before explaining it.
- For unfamiliar libraries, CLIs, frameworks, or APIs, check the real docs or local source first.
- If the task is broad or multi-step, make a short plan, then execute it.
- Push back on overcomplicated approaches when a simpler one would solve the problem.
- When results contradict your hypothesis, update the hypothesis.
- Do not rationalize surprising output. Investigate it.
- If a fix feels like a workaround, say so and keep digging unless the user explicitly asked for a temporary patch.
- If you are not sure, say what you know, what you do not know, and what would verify it.
