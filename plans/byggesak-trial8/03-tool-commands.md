# Step 2 + 5 – Tools and investigation workflow

_Part of [Trial 8 plan](README.md). Phases P1–P2._

| Command | Purpose |
|---|---|
| `extract xml4dr <file> [-o .derived/<form>.facts.json]` | Parse XML4DR → facts; print summary only (counts per section, per kind, unparsed Evals). |
| `extract pdf <pdf>` | Wrap `pdfgrid.py` → same fact format (position, shade → kind, value). |
| `extract dsl <dialogue>` | Dialogue → facts (questions, calculations, constraints, conditions, bolker). |
| `outline <form>` | **Overview section**: section tree with cell counts and kinds; always small enough to read (the "cut-down" view of the XML). |
| `cell <form> <id\|pattern>` | One cell with its text, kind, calc, rules, opens-when, and value, from every source side by side. |
| `around <form> <id> [--radius N]` | **Neighborhood**: same row, same column, parent section, cells that reference it or that it references (data-flow in/out), e.g. C11/c with C10 sources and C14 consumers. |
| `trace <form> <id>` | Dependency closure: what feeds this cell (calc chain) and what it gates (opens/validates). |
| `grep-eval <form> <regex>` | Search rules/texts across the form with context (replacement for raw-XML greps). |
| `spike <form> <section>` | Everything for one section as a compact table: XML4DR vs PDF vs DSL columns, mismatches highlighted. |
| `align <form> --dsl <trial>` | Build the cell mapping XML4DR↔PDF↔DSL (see Step 3); emits `alignment.json` + unmatched lists. |
| `audit <form> --dsl <trial> [--section S] [--format md\|json]` | Run all checks (Step 4) → gap report with severity and a `fixKind` tag. |
| `corpus <dir>` | Run `extract` + pattern statistics over `Forms/*.xml` (Step 6). |

Evidence output rule: every report line cites `cellId`, source, and a one-line reason; no
raw XML blocks.

## Investigation workflow (how it is used)

1. `outline` → pick a section.  2. `spike <section>` → mismatches.  3. For each suspicious
cell `around`/`trace` (e.g. D1 1a ← C10 2a; E2 e2 = e2a + e2b; F2 rad a).
4. Decide fix class. Findings that need user judgement (source ambiguity) are batched into
one question list rather than interrupting.
