---
name: scope
description: Ask the user to define the scope of the current development phase before broad exploration or implementation. Use when the user invokes /scope, asks to scope work, or starts an ambiguous phase where boundaries should be clarified to avoid unnecessary token-heavy exploration.
disable-model-invocation: true
---

# Scope

## Instructions

Before exploring broadly or implementing, ask the user to define the scope of this phase of development so the agent does not waste tokens exploring unrelated parts of the repo.

Ask one concise scoping question first:

```text
What is in scope for this phase, and what should I explicitly avoid?
```

If the user's answer is still broad, ask follow-up questions one at a time until these boundaries are clear:

- Goal: the user-facing outcome or decision this phase should produce.
- Include: files, modules, workflows, platforms, or database areas to inspect or change.
- Exclude: parts of the repo, features, refactors, or investigations to avoid.
- Depth: quick answer, focused implementation, review, debugging, or full plan.
- Verification: tests, commands, migrations, screenshots, or checks expected before completion.

After the user answers, summarize the scope in 3-5 bullets and ask for confirmation before doing broad exploration or edits.
