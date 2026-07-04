---
name: scope
description: Ask the user to define the scope of the current development phase before broad exploration or implementation, including whether to use git history or current repo state. Use when the user invokes /scope, asks to scope work, or starts an ambiguous phase where boundaries should be clarified to avoid unnecessary token-heavy exploration.
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

Ask how the agent should use git history when making decisions:

```text
Should I refer to old git commits for context, or work from the current repo state only?
```

Use AskQuestion when available:

- **Current state only** — read files, diffs, and status as they are now; do not dig through commit history unless the user later asks.
- **Git history** — inspect specific commits, branches, or `git log`/`git show` for prior decisions, reverts, or abandoned approaches.
- **Both** — start from current state, but check named commits or a time range when context is missing.

If the user picks git history, ask one follow-up: which commits, branch, tag, or time window to use. If they pick current state only, do not run broad history searches.

After the user answers, summarize the scope in 3-6 bullets (include the git-history choice) and ask for confirmation before doing broad exploration or edits.
