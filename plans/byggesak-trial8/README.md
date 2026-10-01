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

## DSL freeze policy

1. `dsl/schemas/trial7-byggesak.json` and `Examples/ByggesakTrial7.hs` are **frozen** as the audit baseline; all audit tools run against them and never modify them.
2. Findings are recorded as F-NNN (class + proposed fix) without applying fixes during triage.
3. Fixes go into a new `Examples/ByggesakTrial8.hs` compiling to `trial8-byggesak.json`, built slice by slice (T8a–T8g) and tested in the simulator.
4. Re-run the audit on Trial 8 and diff against the Trial 7 baseline (regression baseline, see `05-audit-checks.md`).
5. No Altinn deployment until the full DSL is audited (P9, via the compiler/injector only).

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
| [11-skjemakart-improvements.md](11-skjemakart-improvements.md) | Skjemakart (explorer) v1 done; next improvements | 03, 04 |

Hard rule (repo instruction): `altinn-skjema-hacking/` is never edited by hand. Altinn is reached
only through the compiler/injector (`schema-dsl-cli`), and not until the full DSL is audited
([08](08-deployment-gate.md)).

## Phases & acceptance

| Phase | Deliverable | Done when |
|---|---|---|
| P0 ✅ | Folder renamed, references updated (done) | `grep -r "screenshots/"` clean; build/tests still pass |
| P1 ✅ | `extract xml4dr` + `outline` | 20Byggesak: all 1204 cells in facts; unparsed Evals counted (target < 5 %); slice order confirmed |
| P2 ✅ | `cell` / `around` / `trace` / `grep-eval` | Can answer "what opens C12 1.1 b1 and what does it feed" in one call, < 40 lines |
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
- **P2 done:** `trace` (transitive up/downstream + gating) and `grep-eval` (rules and messages) added.
- **Finding F-001 (source defect):** `handler445` (Section_H3 / Cell585) is malformed in the source:
  `FieldFilled(obThis)GetFieldValue(...)` has no operator between the calls. Classify as source-ambiguity; ask SSB.
- Cell ids are opaque (`Cell117`), so alignment (P3) must rely on row/column labels and position. Row labels
  sit in label cells of the same row, column headers in earlier rows of the same column (both implemented).

- **P3 / T8a (started):** `align` command + `audit/alignment/byggesak.json` for bolk A, B, H, I. All 15 DSL fields matched 1:1, 0 dsl-only / xml-only (2 explained demo cells). Candidate findings to triage: DSL marks A fields (4 of 5) and I.20–24 required where XML has no FieldFilled check; B1 `VB2021_*` required only as soft warning in XML plus >50000 warning missing in DSL; EPOSTADR isEmail and TELEFONNR >20999999 checks missing in DSL. Next: confirm in simulator, record as F-NNN, extend to T8b.

- **T8b (done, alignment):** added bolk C10 (Section12), C11 (Section7), C14 (Section23); 25+13+12 fields matched 1:1 (fixed column keys like `b.1` ↔ `b1`). New diff classes: calc inputs, check partners (cross-bolk). Candidate findings: C10 DSL adds `behandlet ≤ mottatt` checks absent in XML and marks all fields required; C11 conditional (2.1/2.2) opens not found in XML; C14 col d/b2 calc inputs differ (XML references C10/C11 directly, DSL sums C14 columns). To triage in simulator.
- **T8b+ (all C bolks mapped):** added C12 (Section4), C13 (Section6), C15 (Section9), C16 (Section26), C2 (Section29), C3 (Section31), C4 (Section18), C11–C2 eKOSTRA (Section14), D1–D2 eKOSTRA (Section15). All 16 mapped bolks align 1:1 (0 dsl-only / 0 xml-only). Diff totals: required 70, check partners 93, conditional 43, calc inputs 31. Next: group into F-NNN findings (`audit` command + `dsl/audit/findings/byggesak.json`), then map D/E/F/G bolks.

### Progress: findings grouping and E bolks
- Added `schema-audit audit <xml> <dsl> <cfg> <findings> <out.json> [bolk…]` (modules `Audit.Findings`, `Audit.Audit`). It collects cell diffs, DSL-only constraints and XML-only checks (set-compared), tags each with a finding via the rules in `dsl/audit/findings/byggesak.json`, and lists untriaged items as NEW.
- Findings F-002…F-008 (soft-required, DSL stricter required, conditional on calculated cells, missing gating, DSL-only constraints, source-only checks, calc-input differences). All status `proposed`; 432 items, 0 untriaged.
- Mapped E0 (Section1), E1 (Seksjon_F1), E2 (Seksjon_F2): 2/40/40 fields matched 1:1 (colKey now accepts `e2a`-style headers). 19 of 19 mapped bolks align fully.
- Output `.derived/20Byggesak.findings.json` is ready for the Skjemakart findings layer (not yet wired).

### Progress: Skjemakart findings layer, D bolks
- Skjemakart: `/api/findings`, "F" cell badge, "has finding" filter, Findings block in the detail pane. Tip: use `http://127.0.0.1:8765/` (a Python server shadows `localhost` on IPv6).
- Mapped D1 (Section_E1, 51 fields) and D2 (Section11, 11) 1:1; `numKey` now splits `4.Antall` glued row labels. Section13 (2 radios) has no DSL bolk. 563 audit items, 0 untriaged.

### Progress: F bolks
- Mapped F0 (Section2), F1 (Section_G3), F2 (Seksjon_G1), F3 (Seksjon_G2), F4 (Section16). Letter-led matrix rows (`a.`, `a2b.`) now key rows; F3 `a12`/`a21` single-cell rows are overrides. 617 audit items, 0 untriaged.

### Progress: G bolks — all DSL bolks mapped
- Mapped G0 (Section5), G1 (Seksjon_H1), G2 (Seksjon_H2), G3 (Section_H3), G4 (Section_H4) 1:1. All 31 mapped bolks align fully (no DSL-only/XML-only); 710 audit items, 0 untriaged. Remaining unmapped XML: Section13 (2 radios), a few cross-bolk checks (2 skipped).
- Next: review/confirm findings F-002…F-008 with the user, then PDF extraction and simulator verification.

### Progress: remaining sections
- 34 of 44 sections now carry audit data; the other 10 are cell-less containers (`Section8`, `Section3`, `Seksjon_B/_E/_F/_G/_H/_M/_N`, `Section_D1`). Mapped the last three cell-bearing sections as explained XML-only cells: `setSID` (platform metadata, 7 cells) and `Section13` (platform prefill: `Kommune_nr2`, `Strandsone`) under bolk_a, `Section10` (6 dark-grey helper totals of C10) under bolk_c10.
- Candidate finding: `Section13/VB2019_2` (Strandsone) gates D1 row 3 (`Section_E1/V2012_7`: readonly when 0, "fill in" warning when 1); the DSL has no such flag.
- The 2 skipped XML checks are `Section_E1/V2012_7` -> Strandsone (explained cell) and `Seksjon_G1/V2014_1` -> `Section_H3/Cell585` (F-001 malformed handler).
