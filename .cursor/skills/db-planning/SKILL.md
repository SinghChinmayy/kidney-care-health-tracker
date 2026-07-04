---
name: db-planning
description: >-
  DB design planning workflow: interview requirements, then produce versioned
  artifacts (DBML + markdown + migration SQL) under planning/db/ using
  v{N}/s{M}/s{M}.{m} folder nesting. Use when the user invokes /db-planning,
  says "plan db", "design database", "db planning", or starts schema design work.
disable-model-invocation: true
---

# DB Planning

Two-phase workflow: **interview** until requirements are clear, then **versioned artifacts** for review and implementation.

Read the Supabase skill when writing or applying migrations.

## Versioning Scheme

Three levels, nested as folders:

| Level | Label | Meaning | Example path |
|---|---|---|---|
| Major | `v{N}` | Planning epoch — breaking redesign or new domain | `planning/db/v0/` |
| Stage | `s{M}` | Logical implementation phase within a major version | `planning/db/v0/s1/` |
| Minor | `s{M}.{m}` | Implementable slice within a stage | `planning/db/v0/s1/s1.1/` |

### Folder layout

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

- **v{N} → v{N+1}**: user explicitly starts a new major planning epoch (full redesign, unrelated domain, or fresh planning session that supersedes prior major version).
- **s{M} → s{M+1}**: new logical phase within the same major version (e.g. s1 = core patient data, s2 = care team + labs).
- **s{M}.{m} → s{M}.{m+1}**: next implementable delta within the same stage (e.g. s1.1 ships patients + vitals; s1.2 relaxes one constraint).

Before creating files, confirm the target path with the user if ambiguous. When continuing existing work, read the latest minor slice under the stage (highest `s{M}.{m}`) and its `migration.sql` status.

### Legacy layout

Flat `stage-*` files under `planning/db/v0/` were migrated to `v0/s1/s1.*`. Use the nested layout for all new work.

---

## Phase 1 — Interview

Goal: shared understanding before any schema is written.

Rules:

- Ask **one question at a time**. Wait for an answer before the next.
- Walk the design tree depth-first; resolve dependencies before sibling questions.
- Provide a **recommended default** for each question (user can accept or modify).
- If the answer is discoverable in the codebase, explore first — do not ask.
- Cover: purpose → entities → relationships → access patterns → scale → constraints → integrations → ops.

End the interview when all branches are resolved or the user says "done" / "enough" / "move on".

### Question tree (depth-first)

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

---

## Phase 2 — Stage Artifacts

After the interview (or when scoping a new stage), create **stage-level** files at `planning/db/v{N}/s{M}/`:

### `s{M}.dbml`

DBML spec: https://dbml.dbdiagram.io/docs

Include:

- Full stage schema — all entities planned for this phase (including deferred slices if useful for context)
- Column types, pk, indexes, notes
- `Ref` lines for all relationships
- Header comment: project name, version path (`v0/s1`), date

### `s{M}.md`

Sections:

1. **Summary** — one paragraph purpose
2. **Entities** — name, description, est rows (launch / 1yr / 5yr)
3. **Key Relationships** — M:N join tables, notable constraints
4. **Access Patterns** — pattern, frequency, index strategy
5. **Design Decisions** — decision, choice, reason
6. **Implementation Slices** — planned minor slices (`s1.1`, `s1.2`, …) and what each will ship
7. **Open Questions** — unresolved items
8. **Change Log** — what changed from the previous stage or major version

Pause for user review of DBML before breaking into minor slices or writing SQL.

---

## Phase 3 — Minor Slice Artifacts

Each implementable slice gets its own folder: `planning/db/v{N}/s{M}/s{M}.{m}/`

### `s{M}.{m}.dbml`

- Schema for **this slice only** (tables/columns/indexes being added or changed)
- Must be consistent with the stage DBML; call out intentional deltas in notes
- Header comment: version path, parent stage, date

### `s{M}.{m}.md`

Same section structure as stage MD, scoped to the slice:

1. Summary — what this slice ships and why now
2. Entities — only entities touched in this slice
3. Key Relationships
4. Access Patterns
5. Design Decisions — especially deltas from prior minor slice
6. Open Questions
7. Change Log — what changed from `s{M}.{m-1}` or from stage baseline

### `migration.sql`

- Postgres SQL implementing the slice DBML
- First lines: comment with source path, e.g. `-- Source: planning/db/v0/s1/s1.1/s1.1.dbml`
- Idempotent where practical (`if not exists`, guarded alters)
- Include RLS, triggers, grants only when in scope for this slice

**Order of operations per slice:** DBML → user review → MD → `migration.sql` → user review → apply.

---

## Applying Migrations

Planning `migration.sql` is the draft source of truth. To apply:

1. Copy or adapt into `supabase/migrations/{timestamp}_v{N}_s{M}_s{M}_{m}_{slug}.sql`
   - Example: `20260703212925_v0_s1_s1_1_patient_vitals.sql`
2. Keep the `-- Source:` comment pointing at the planning path
3. Run locally with Supabase CLI before remote apply

Do not apply SQL before the slice DBML is reviewed.

---

## Workflow Summary

```
interview → shared understanding
  → planning/db/v{N}/s{M}/s{M}.dbml + s{M}.md  (stage design, review)
  → planning/db/v{N}/s{M}/s{M}.1/              (first implementable slice)
       s{M}.1.dbml → review → s{M}.1.md → migration.sql → review → supabase/migrations/
  → s{M}.2/, s{M}.3/, …                          (subsequent slices in same stage)
  → s{M+1}/                                       (next stage within same v{N})
  → v{N+1}/s1/                                    (new major version)
```

Ask the first interview question when the user says "start" or invokes this skill.
