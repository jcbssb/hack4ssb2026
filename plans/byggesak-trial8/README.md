# Plan: Trial 8 – audit the Byggesak DSL against incoming XML4DR + PDF artifacts

Split into small files so each can be planned/executed on its own. Read this index first.

## Goal

Build a small **audit toolchain** (not a hand-edit of Trial 7) that compares the Byggesak
Dialogue DSL with the incoming artifacts and reports gaps. The gaps then drive (a) DSL /
Builders / generator improvements and (b) a Trial 8 dialogue. The real deliverable is a
**repeatable workflow for modernizing old SSB schemas**: Byggesak is the first test case.

Hard rule: `incoming-skjema-observations/` is **read-only input**; tools write only to `.derived/`, `research/` or `dsl/`.

Hard rule (repo instruction): `altinn-skjema-hacking/` is never edited by hand. Trial 8 reaches
Altinn only through the compiler/injector (`schema-dsl-cli`), and **not until the full DSL is audited**
(see Step 7: incremental slices tested in the skjemantikk-simulator first).

## What we have (measured, not read into context)

| Artifact | Size | What it is |
|---|---|---|
| `incoming-skjema-observations/byggesak-20/20Byggesak.xml` | 777 KB | **XML4DR** export of the real SSB form definition: 44 `Set`s, 219 `Tuple`s, 1204 `Data` cells, 342 `Format`/`InputControl`s, 573 `Text`s (nb + nn), **518 `Handler`s** with `Eval` expressions (`GetFieldValue("Set","Cell")`, `FieldFilled`, sums, `if/else if` calculations, `>`/`<`/`==` checks) and `Action`s (`MsgBox`, `SetError critical/warning`, `SetState`). |
| `incoming-skjema-observations/xml4dr/XML4DR11.xsd` | 34 KB | Schema for the above (small enough to read in full once). |
| `incoming-skjema-observations/xml4dr/Forms/*.xml` | 46 files, ~5 MB (largest 805 KB) | Other SSB forms in the same format – a **corpus** for generalizing the tools, not for Byggesak. |
| `incoming-skjema-observations/byggesak-20/20Byggesak (utfylt).pdf` | 128 KB | Filled-in PDF; already audited by `research/byggesak-trial6-audit.md` (cell colors, positions, example values). |
| `dsl/schemas/trial7-byggesak.json` + `Examples/ByggesakTrial7.hs` | – | Current DSL under audit. |

Key insight: XML4DR contains the **authoritative rules** the PDF only hints at (which cell
opens which, exact calculations, critical error vs warning, texts in nb/nn). The Trial 6 audit
flagged "172 light-grey cells lack a condition – what opens them is not visible in the PDF";
the `Handler`/`SetState` data should answer exactly that.

## Files

| File | Covers | Depends on |
|---|---|---|
| [01-housekeeping-rename.md](01-housekeeping-rename.md) | Rename (**done**) `screenshots/` → `incoming-skjema-observations/` | – |
| [02-tool-architecture.md](02-tool-architecture.md) | Language choice, normalized fact model, Eval parsing | 01 |
| [03-tool-commands.md](03-tool-commands.md) | `schema-audit` subcommands, investigation workflow | 02 |
| [04-alignment.md](04-alignment.md) | XML4DR ↔ PDF ↔ DSL cell alignment | 02 |
| [05-audit-checks.md](05-audit-checks.md) | What counts as a gap, finding format, report | 03, 04 |
| [06-incremental-slices.md](06-incremental-slices.md) | Pilot slices T8a–T8g, per-slice loop | 03–05 |
| [07-simulator-testing.md](07-simulator-testing.md) | Manual testing in `skjemantikk-simulator` | 06 |
| [08-deployment-gate.md](08-deployment-gate.md) | No Altinn work until full DSL audited | 06, 07 |
| [09-corpus-and-generalization.md](09-corpus-and-generalization.md) | `Forms/` corpus stats, XML4DR → draft DSL | 02 (parallel) |
| [10-risks.md](10-risks.md) | Risks and open questions | – |

Hard rule (repo instruction): `altinn-skjema-hacking/` is never edited by hand. Altinn is reached
only through the compiler/injector (`schema-dsl-cli`), and not until the full DSL is audited
([08](08-deployment-gate.md)).

## Phases & acceptance

| Phase | Deliverable | Done when |
|---|---|---|
| P0 ✅ | Folder renamed, references updated (done) | `grep -r "screenshots/"` clean; build/tests still pass |
| P1 ✅ | `extract xml4dr` + `outline` | 20Byggesak: all 1204 cells in facts; unparsed Evals counted (target < 5 %); slice order confirmed |
| P2 (partly: `cell`, `around` done; `trace`, `grep-eval` open) | `cell` / `around` / `trace` / `grep-eval` | Can answer "what opens C12 1.1 b1 and what does it feed" in one call, < 40 lines |
| P3 | `extract dsl`, `extract pdf`, `align` | ≥ 95 % cells aligned **for the T8a–T8b slices** first, then widened per slice |
| P4 | `audit` + generated report | Reproduces known Trial 6/7 findings in the pilot slices (sanity check) and adds new ones from XML4DR |
| P5 | T8a, T8b slices (pilot) | Slices audited clean/classified; simulator walkthrough accepted by user; tool/DSL fixes landed |
| P6 | T8c–T8g slices | Each slice: audit clean/classified, simulator-checked, no regressions; new-gap-class count per slice trending to zero |
| P7 | `corpus` stats on `Forms/` | Idiom histogram + feature backlog doc (can run in parallel from P1 on) |
| P8 | Full `ByggesakTrial8` composed + whole-form audit | Only documented source ambiguities remain; user acceptance in simulator |
| P9 | Altinn injection + Studio/tt02 testing (**gated, after P8**) | Injected via CLI only; generator issues fixed in `SchemaDSL.Altinn` |

## Progress log

- **P1 done** (`dsl/audit/`, usage in `dsl/audit/README.md`): `outline`, `cell`, `around`, `evals`, `extract`.
  20Byggesak: 44 sections, 1204 cells, 518 handlers; **517/518 Evals parse** (target < 5 % unparsed).
  Cell identity is `setId/dataId`; rules attach via Data → Format → InputControl → CatchEvent, in three
  handler kinds: `calculation` (own value), `guidance` (`SetState` normal/readonly on other cells = what
  opens light-grey cells), untyped checks (`SetError` warning/critical + message).
- **Finding F-001 (source defect):** `handler445` (Section_H3 / Cell585) is malformed in the source:
  `FieldFilled(obThis)GetFieldValue(...)` has no operator between the calls. Classify as source-ambiguity; ask SSB.
- Cell ids are opaque (`Cell117`), so alignment (P3) must rely on row/column labels and position. Row labels
  sit in label cells of the same row, column headers in earlier rows of the same column (both implemented).
