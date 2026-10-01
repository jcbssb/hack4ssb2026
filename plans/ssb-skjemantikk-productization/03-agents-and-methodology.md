# 03 AGENTS.md and methodology

## AGENTS.md (adapted from current rules)
- Hard rules: incoming artifacts are **read-only**; generated app output is **never hand-edited**; large data stays out of context – use tools (`schema-audit cell|around|trace|grep-eval|extract|align`).
- Plans are recorded in `plans/` (small files, one phase each).
- Commit only on request; no data commits; run `scripts/check.sh` before proposing a commit.
- Workflow checklist per case, linking to docs: intake → extract → align → slice → simulate → audit report → full compile → Altinn.
- Tool cheat-sheet and output formats; how to use the explorer to inspect a cell neighbourhood.
- Escalation: when to ask the human (ambiguous labels, rule intent, F-00x findings).

## Agent skills (portable, `.github/skills/` or `skills/`)
`intake-artifacts`, `extract-facts`, `align-dsl-pdf-xml`, `author-dsl-slice`, `audit-report`, `compile-altinn`, `simulate-and-review`.
Each skill = short SKILL.md + the exact commands.

## Methodology docs
1. **Intake**: what artifact types are accepted, naming, provenance log (DATA-SOURCES template), checksum manifest.
2. **Facts model**: the neutral JSON (cells, handlers, gating, texts nb/nn) as the contract between sources and DSL. Document the schema (JSON Schema + versioning).
3. **Alignment**: matching DSL fields to XML/PDF cells (labels, rows/cols, calc refs); gap taxonomy (missing, extra, wrong rule, wrong text, ordering, gating).
4. **Incremental slices**: simple bolks first, simulator review, then widen; deployment gated on full audit.
5. **Findings log**: F-NNN with severity, source evidence, resolution (including source defects like malformed handlers).
6. **Definition of done** per slice and for a full form.
