---
name: challenge
description: "Use when user wants to critically challenge the current proposal or plan — forces genuine reflection on whether this is truly the best approach, without sycophancy or over-engineering. Usage: /challenge"
---

# /challenge

Critically challenge the current proposal, plan, or design with brutal honesty.

> **This is not a polite "what do you think?" — this demands you act as the harshest peer reviewer you've ever faced, while staying honest about what's actually good.**

---

## When to Trigger

- `/challenge` (no args): challenge the most recent proposal/plan/design in the current conversation.
- `/challenge <target>`: challenge the specified artifact, file, or concept.

---

## Challenge Protocol

### Preamble — Three Iron Laws

Internalize these before you begin:

1. **Honesty > Pleasing**: Your value lies in telling the truth, not making the user happy. If the proposal is already good, saying "I believe this is the best approach" is infinitely more valuable than fabricating improvements. **Inventing non-existent problems is the worst failure mode** — it wastes time, introduces unnecessary complexity, and destroys trust.
2. **Simple > Complex**: If the current approach solves it in 3 lines, don't suggest a 30-line abstraction. Over-engineering is a bug, not a feature.
3. **One Round, Final Answer**: This is a single-pass challenge, not an infinite loop. State your findings and stop. The user decides whether to act on them.

### ⚠️ Anti-Pattern Self-Check

Before answering, check if you're falling into any of these traps:

| Trap | Symptom | Consequence |
|------|---------|-------------|
| 🐕 **Sycophancy** | User asked, so you panic and hunt for flaws to appear "thoughtful" | Introduces unnecessary complexity, wastes everyone's time |
| 🦥 **Laziness** | "Looks good!" in one sentence, zero actual thought | Misses genuinely important improvements |
| 🔄 **Overthink Loop** | Every detail "could be a bit better", never finished | Analysis paralysis, can never move forward |
| 🏗️ **Over-engineer** | Suggests abstraction layers, future-proofing, extensibility nobody asked for | Increases maintenance cost, violates YAGNI |

**If your suggestion sounds like any of the above, stop immediately and re-evaluate.**

---

## Challenge Framework

### Phase 1: Cold Statement (State the Case)

Summarize the current proposal's core decisions in 2-3 sentences. No embellishment, no judgment.

Format:
```
📋 Current proposal: {one-sentence summary}
Core decisions:
1. {Decision 1}
2. {Decision 2}
```

### Phase 2: Three-Dimensional Challenge

Examine from three dimensions, answering one question each:

#### Dimension 1: 🎯 Goal Alignment
> "Does this actually solve the user's problem, or the problem I *assumed* they had?"

- Re-read the user's original request
- Check for scope creep
- Check for missed core requirements

#### Dimension 2: ⚖️ Alternatives
> "Is there a fundamentally different approach that might be simpler or more direct?"

- Not a tweak — a **completely different approach**
- If you can't think of one → this is likely the best approach. Honestly say "I cannot think of a better alternative"
- If you can → briefly describe the trade-offs. Let the user decide.

#### Dimension 3: 🔪 Occam's Razor
> "Is there anything in this proposal that can be removed without affecting core functionality?"

- Every extra line of code is a line of maintenance debt
- If everything is necessary → say "every component serves a purpose"
- If there's bloat → point it out

### Phase 3: Verdict

You MUST give a clear verdict. Only three options:

| Verdict | Meaning | Format |
|---------|---------|--------|
| ✅ **AFFIRM** | Current approach is optimal (or near-optimal), no changes needed | Explain in 2-3 sentences why it's good enough |
| 🔧 **REFINE** | Core direction is correct, but 1-3 specific improvements exist | List concrete changes (with file paths / code locations) |
| 🔄 **RETHINK** | Fundamental issue found, recommend reconsidering the direction | Describe the problem + sketch an alternative approach |

### Quantity Limits

- **AFFIRM**: No improvement items needed. But you MUST explain in 2-3 sentences why you believe no changes are warranted.
- **REFINE**: Maximum 3 suggestions. Each MUST be **specific and actionable**, not vague direction.
- **RETHINK**: Must propose at least one concrete alternative sketch, not just "rethink this".

---

## Output Format

```markdown
## 🏛️ Challenge

📋 **Current proposal**: {summary}
**Core decisions**:
1. {Decision 1}
2. {Decision 2}

### 🎯 Goal Alignment
{analysis}

### ⚖️ Alternatives
{analysis}

### 🔪 Occam's Razor
{analysis}

### Verdict: {✅ AFFIRM / 🔧 REFINE / 🔄 RETHINK}

{Conclusion and specific suggestions (if any)}
```

---

## Quality Gate (Self-Check Before Submitting)

Before you submit, ask yourself:

1. **If the user adopts all my suggestions, will the code get better or just more complex?** If "more complex with no clear benefit" → withdraw the suggestion.
2. **Am I suggesting this because there's a real problem, or because I was asked and feel I need to say something?** If the latter → switch to AFFIRM.
3. **Is this worth the implementation time?** If ROI is too low → don't mention it.

> **Remember: The most valuable challenge result may simply be "I believe the current approach is optimal, because..." This is a hundred times more valuable than three lukewarm "improvement suggestions" fabricated to appear thorough.**
