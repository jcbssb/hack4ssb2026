# Manual testing in skjemantikk-simulator

_Part of [Trial 8 plan](README.md). Used in every slice (P5–P8)._

All manual testing by the user happens in the **skjemantikk-simulator** (Vite + Designsystemet; reads the
DSL JSON written by `schema-dsl-cli`), not in Altinn:
- Regenerate: `cd dsl && cabal run schema-dsl-cli -- --update-all` (adds `trial8-*` schemas), then in
  the simulator `npm run sync-schemas` (or `HACK4SSB_DIR`) and `npm run dev`; open
  `?schema=trial8-<slice>`. A slice JSON can also be loaded ad hoc via *Last inn egen DSL-JSON*
  without rebuilding.
- Each slice's hand-off to the user includes: the URL/param, 3–5 concrete things to try
  (e.g. "enter C11 1a = 100, 1b = 44 → c shows 56; set mottatt = 0 → herav cells close"), and the
  PDF example numbers to compare with.
- Where the simulator lacks a DSL semantic needed by a slice (e.g. weighted average, multi-language,
  severities), add it to the simulator **and** its semantics tests (`npm test`), and keep it in step
  with `SchemaDSL.Eval` so the simulator remains a faithful reference. Track such needs as
  `fixKind = simulator` in the audit report.
- Optional later: export the audit report's per-cell expectations (example values from the PDF/XML)
  as a fixture the simulator tests can replay automatically, reducing manual checking.
