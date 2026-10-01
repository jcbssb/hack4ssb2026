# Step 6 – Generalize beyond Byggesak

_Part of [Trial 8 plan](README.md). Phase P7; can run in parallel from P1._

- Run `corpus` on `Forms/*.xml` (46 forms): histogram of Eval idioms, control types, set/tuple
  shapes, which are matrix-like → prioritized list of DSL/Builders features worth adding
  (weighted average, cross-section copy `= C10 a`, conditional opens, severities).
- Prototype **XML4DR → draft DSL** generator for the idioms that parse cleanly (inverse of
  the audit: emit `Builders` matrix skeleton + calculations + constraints), so Byggesak Trial 8
  is mostly *generated and then audited*, and other forms start from a draft. Scope this as an
  experiment after the audit works; do not block Trial 8 on it.
- Document the resulting pipeline in `docs/` and `plans/ssot-schema-workflow.md`
  (XML4DR = source of rules, PDF = visual cross-check, DSL = SSOT going forward).
