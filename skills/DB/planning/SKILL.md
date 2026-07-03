---
name: db-planning
description: >
  DB design planning skill. Two-stage workflow: (1) relentless one-at-a-time interview
  to reach shared understanding of requirements, (2) generate versioned plan artifacts
  (DBML + MD) under /planning/db/ with session/stage versioning (v0/stage-1, v0/stage-2…).
  Triggers on: "plan db", "design database", "db planning", "database design", "db design".
---

## Caveman Mode

Activate caveman full mode throughout. Skip filler. Stay precise. Auto-clarity on destructive or ambiguous ops.

## Stage 1 — Interview

Goal: reach shared understanding before any schema written.

Rules:
- Ask ONE question at a time. Wait for answer before next.
- Walk design tree depth-first, resolve dependencies before sibling questions.
- For each question provide YOUR recommended answer as default (user can accept/modify).
- If answer discoverable in codebase → explore first, don't ask.
- Cover every branch: purpose → entities → relationships → access patterns → scale → constraints → integrations → ops.

### Question Tree (depth-first order)

```
1. Purpose & Domain
   1.1 What problem does this DB solve? What is the core domain?
   1.2 Who are the primary users/consumers of this data?

2. Entities & Relationships
   2.1 What are the main "things" (nouns) the system tracks?
   2.2 What are the relationships between them? (1:1, 1:N, M:N)
   2.3 Any hierarchical/recursive relationships?

3. Access Patterns
   3.1 What are the most frequent read queries?
   3.2 What are the most frequent write operations?
   3.3 Any real-time / streaming requirements?

4. Scale & Volume
   4.1 Expected rows per entity at launch? 1 year? 5 years?
   4.2 Read-heavy, write-heavy, or balanced?
   4.3 Any burst patterns (time-of-day, events)?

5. Constraints & Rules
   5.1 Any hard business rules (e.g. "user cannot book same slot twice")?
   5.2 Compliance requirements (HIPAA, GDPR, PCI)?
   5.3 Data retention / deletion policies?

6. Tech & Integrations
   6.1 DB engine preference or already decided?
   6.2 Any existing systems this DB must integrate with?
   6.3 ORM / query builder in use?

7. Ops & Non-functional
   7.1 High-availability needed?
   7.2 Multi-region or single-region?
   7.3 Backup & recovery SLA?
```

Signal end of interview: when all branches resolved or user says "done" / "enough" / "move on".

---

## Stage 2 — Plan Artifacts

When interview done, generate versioned artifacts.

### Versioning Scheme

```
/planning/db/
  v{N}/
    stage-{M}.dbml   <- DBML for DB visualisation
    stage-{M}.md     <- Design plan doc
```

- N = session number (0-indexed). Increment each NEW conversation/session.
- M = stage number within session (1-indexed). Increment each plan update in same session.
- First ever output -> v0/stage-1.*
- Next edit same session -> v0/stage-2.*
- New session -> v1/stage-1.*

### DBML File (stage-M.dbml)

Use DBML spec: https://dbml.dbdiagram.io/docs

Include:
- Table definitions with column types, pk, indexes, notes
- Ref lines for all relationships (>, -, <>)
- Header comment with project name, version, date

### MD File (stage-M.md)

Sections:
1. Summary - one paragraph purpose
2. Entities table - name, description, est rows (launch/1yr/5yr)
3. Key Relationships - M:N join tables, notable constraints
4. Access Patterns table - pattern, frequency, index strategy
5. Design Decisions table - decision, choice, reason
6. Open Questions - unresolved items for next stage
7. Change Log - what changed from previous stage

---

## Workflow Summary

```
interview -> shared understanding
  -> create v{N}/stage-1.dbml + stage-1.md
  -> each update in session -> stage-2, stage-3 ...
  -> new session -> v{N+1}/stage-1.*
```

Ask first interview question now if user says "start" or invokes skill.
