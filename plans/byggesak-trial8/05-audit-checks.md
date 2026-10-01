# Step 4 – Audit checks

_Part of [Trial 8 plan](README.md). Phase P4._

Each check yields findings `{id, severity, section, cell, finding, evidence, fixKind}` where
`fixKind ∈ {dsl-content, dsl-feature, builder, altinn-generator, source-ambiguity}`.

1. **Presence** – cells/rows/sections in XML4DR but not DSL (and vice versa); Trial 6 listed
   21 missing (row 2.2) and 8 extras – confirm Trial 7 state.
2. **Kind** – input vs calculated vs prefilled vs conditional (dark/light grey ↔ `SetState`).
3. **Calculations** – parsed XML `Eval` calc vs DSL `Calculation`; compare symbolically
   *and* numerically using PDF example values via `SchemaDSL.Eval`. Detect the weighted-average
   (row 2.2) and `if FieldFilled … else if` patterns explicitly.
4. **Constraints** – XML4DR checks vs DSL `Constraint`s: comparison, operands, **severity
   (critical=error vs warning)**, message text; flag unmatched in both directions.
5. **Conditions (opens-when)** – the 172-cell backlog from the Trial 6 audit; fill from `SetState`.
6. **Required** – `FieldFilled(obThis)` critical handlers vs DSL `required` (the Trial 6 audit
   couldn't read this from the PDF).
7. **Texts** – nb/nn labels, units, help texts, `maxlen`; flag DSL labels differing from source
   and missing nn translations (decide whether DSL needs multi-language).
8. **Types/formats** – XML `Format` (numeric widths, decimals, text length) vs DSL
   `QuestionType`.
9. **Structure/ordering** – section order, numbering (`numberingRef`), radio groups.
10. **Unmodelled features** – list every XML4DR idiom the DSL cannot express yet
    (`MsgBox`, prefilled values like `SKJEMA_NR`/`GYLDIGFOM`, domains, `Admin/Custom`,
    style groups), grouped with counts → this is the DSL feature backlog.

Report: `research/byggesak-trial8-audit.md` (generated summary + hand commentary), plus
machine-readable `.derived/byggesak-trial7.audit.json`. Include a **regression baseline**:
re-running `audit` after each fix must show the finding count dropping, and previously
verified-correct cells (61 calculated cells from Trial 6) must stay green.
