# Step 7 – Incremental trials (pilot slices first)

_Part of [Trial 8 plan](README.md). Phases P5–P6, P8._

Do not audit all 1204 cells in one go. Run a series of **small trials, each a slice of the form**
(a page or bolk), and use each one to prove/fix the extract → align → audit loop and to find
DSL gaps cheaply. Findings from earlier slices are fixed in tools/DSL *before* the next slice,
so later slices should show fewer new gap classes (that decline is the progress metric).

Each slice is a self-contained DSL dialogue (`ByggesakTrial8<Slice>.hs` →
`schemas/trial8-<slice>.json`) built with the existing matrix `Builders`, so it can be loaded
alone in the simulator and audited with `schema-audit audit --section <S>`.

| Slice | Content | Why this order / what it tests |
|---|---|---|
| T8a | Bolk A (contact fields), B (fees, prefilled dark-grey col b), H (comment), I (2 = 2a + 2b) | Trivial. Proves id mapping, labels nb/nn, required (`FieldFilled`), prefilled cells, simple calc. Mostly tool shakedown. |
| T8b | C10 + C11 (+ C14 summing check) | First matrix: `a = b + c + d` entered-and-checked (not calculated), cross-section copies, `c = a − b`, row 2.2 weighted average. Exercises opens-when conditions (`SetState`) on a small cell set. |
| T8c | C12, C13, C2 | Larger 6-column matrix (b1/b2 herav, `d = c + b2`); validates the generic alignment at scale. |
| T8d | C15, C16, C3, C4, eKOSTRA yes/no | Mixed types, Ja/Nei gating, tail of C. |
| T8e | D1, D2 | Cross-section references (D1 1a ← C10 2a; D2 ← C10/C4), `b2 = b`, row removals/additions from the Trial 6 audit. |
| T8f | E0/E1/E2 | Nested row sums, weighted averages with weights in another row, `e2 = e2a + e2b`. |
| T8g | F0–F4, G0–G4 | Largest conditional structure: yes/no-gated matrices, many herav chains, many light-grey cells. |
| T8 (full) | Everything composed into `ByggesakTrial8.hs` | Whole-form audit; remaining gaps ≈ only documented source ambiguities. |

Per-slice loop (repeat until the slice's audit is clean or findings are classified):
1. `outline` + `spike <section>` to see XML4DR vs PDF vs current Trial 7 for the slice.
2. Write/adjust the slice dialogue (and fix tools/Builders/DSL if the gap is `dsl-feature`/`builder`).
3. `audit --section` → findings; regression-check earlier slices (all previously clean slices stay clean).
4. Simulator check (below), then record learnings in `research/byggesak-trial8-audit.md`
   (one short section per slice: gap classes found, what was fixed, what stays open).

Slice order is a proposal; reorder if the XML4DR outline shows a better pilot (e.g. a section
that already has many parsed handlers). Ask the user to confirm the order after P1 (`outline`).
