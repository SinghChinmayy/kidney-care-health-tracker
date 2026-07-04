---
name: db-planning
description: >
  DB design planning skill. Two-stage workflow: (1) relentless one-at-a-time interview
  to reach shared understanding of requirements, (2) generate versioned plan artifacts
  (DBML + MD + migration SQL) under planning/db/ with v{N}/s{M}/s{M}.{m} folder nesting.
  Triggers on: "plan db", "design database", "db planning", "database design", "db design".
---

## Caveman Mode

Activate caveman full mode throughout. Skip filler. Stay precise. Auto-clarity on destructive or ambiguous ops.

## Versioning Scheme

Three levels, nested as folders:

| Level | Label | Meaning | Example path |
|---|---|---|---|
| Major | `v{N}` | Planning epoch — breaking redesign or new domain | `planning/db/v0/` |
| Stage | `s{M}` | Logical implementation phase within a major version | `planning/db/v0/s1/` |
| Minor | `s{M}.{m}` | Implementable slice within a stage | `planning/db/v0/s1/s1.1/` |

```
planning/db/
  v0/
    s1/
      s1.dbml              # stage-wide schema (review)
      s1.md                # stage reference doc
      s1.1/
        s1.1.dbml          # slice schema (review before migration)
        s1.1.md            # slice reference doc
        migration.sql      # SQL to apply for this slice
      s1.2/
        s1.2.dbml
        s1.2.md
        migration.sql
    s2/
      s2.dbml
      s2.md
      s2.1/
        ...
  v1/
    s1/
      ...
```

### When to increment

- **v{N} → v{N+1}**: new major planning epoch (full redesign or user explicitly resets).
- **s{M} → s{M+1}**: new logical phase within same major version.
- **s{M}.{m} → s{M}.{m+1}**: next implementable delta within same stage.

Confirm target path with user if ambiguous. When continuing, read latest minor slice (highest `s{M}.{m}`).

### Legacy layout

Flat `stage-*` files under `planning/db/v0/` were migrated to `v0/s1/s1.*`. Use the nested layout for all new work.

---

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

## Stage 2 — Stage Artifacts

Create at `planning/db/v{N}/s{M}/`:

### s{M}.dbml

Use DBML spec: https://dbml.dbdiagram.io/docs

Include:
- Full stage schema
- Table definitions with column types, pk, indexes, notes
- Ref lines for all relationships (>, -, <>)
- Header comment with project name, version path, date

### s{M}.md

Sections:
1. Summary - one paragraph purpose
2. Entities table - name, description, est rows (launch/1yr/5yr)
3. Key Relationships - M:N join tables, notable constraints
4. Access Patterns table - pattern, frequency, index strategy
5. Design Decisions table - decision, choice, reason
6. Implementation Slices - planned s{M}.1, s{M}.2, … and what each ships
7. Open Questions - unresolved items for next stage
8. Change Log - what changed from previous stage

Pause for user DBML review before minor slices or SQL.

---

## Stage 3 — Minor Slice Artifacts

Folder: `planning/db/v{N}/s{M}/s{M}.{m}/`

### s{M}.{m}.dbml

- Slice-only schema (tables/columns/indexes in this slice)
- Consistent with stage DBML; note intentional deltas

### s{M}.{m}.md

Same sections as stage MD, scoped to slice. Change Log references prior minor slice.

### migration.sql

- Postgres SQL for slice DBML
- Header: `-- Source: planning/db/v0/s1/s1.1/s1.1.dbml`
- Idempotent where practical

**Order:** DBML → review → MD → migration.sql → review → apply.

---

## Applying Migrations

Copy/adapt planning `migration.sql` to:

`supabase/migrations/{timestamp}_v{N}_s{M}_s{M}_{m}_{slug}.sql`

Keep `-- Source:` comment. Run locally via Supabase CLI before remote.

---

## Workflow Summary

```
interview -> shared understanding
  -> v{N}/s{M}/s{M}.dbml + s{M}.md (stage, review)
  -> v{N}/s{M}/s{M}.1/ ... s{M}.n/ (slices: dbml -> md -> migration.sql -> supabase)
  -> s{M+1}/ (next stage) or v{N+1}/s1/ (new major)
```

Ask first interview question now if user says "start" or invokes skill.
