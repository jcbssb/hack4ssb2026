# Plan: productify the hack repo as `ssb-skjemantikk`

Status: **proposed** (2026-10-01). Recorded here because this repo holds the plans.

## Goal
A new repo `ssb-skjemantikk` that anyone can clone and, with an AI agent guided by `AGENTS.md`, go from
**incoming artifacts** (screenshots, PDFs, XML4DR/legacy definitions, written descriptions)
→ **audited Skjemantikk DSL** → **compiled outputs** (Altinn Studio app, simulator schemas, reports).

## Pipeline (target)
```
incoming/ (read-only) ──► schema-audit (extract/align/audit) ──► DSL (Haskell, typed)
                                                       │
                                  ┌────────────────────┼────────────────────┐
                                  ▼                    ▼                    ▼
                           Altinn Studio app     Simulator schemas     Audit/gap reports
```

## Files
| File | Content |
|---|---|
| [01-target-repo-layout.md](01-target-repo-layout.md) | Proposed structure, what each part is |
| [02-keep-move-remove.md](02-keep-move-remove.md) | Triage of current repo content |
| [03-agents-and-methodology.md](03-agents-and-methodology.md) | AGENTS.md, skills, methodology docs |
| [04-build-and-dependencies.md](04-build-and-dependencies.md) | One-command setup, CI, sibling repos |
| [05-public-and-international.md](05-public-and-international.md) | Making it useful for other statistical organisations |
| [06-migration-steps.md](06-migration-steps.md) | Ordered steps, with gates |
| [07-multi-repo-architecture.md](07-multi-repo-architecture.md) | Decoupled multi-repo ecosystem, independent compilers, shared contracts, and consumer slices |

## Decisions needed from the owner
1. Licence (suggest EUPL-1.2 or MIT/Apache-2.0; check SSB policy).
2. Org/owner for the new repo (SSB GitHub org vs. personal).
3. Whether to keep git history (suggest **fresh history + squash import**; see 06).
4. Whether the simulator becomes a subfolder (suggest yes: `apps/simulator`) or stays a sibling.
5. Name casing: `ssb-skjemantikk` (as requested).
