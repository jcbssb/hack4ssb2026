# Risks / open questions

_Part of [Trial 8 plan](README.md). _

- **Eval parsing coverage**: nested `if/else if` and cross-set references may need iteration;
  mitigated by the `Unparsed` bucket.
- **Alignment ambiguity** for rows without clear ids; mitigated by layered matching + overrides.
- **XML library availability** in the offline cabal store (fallback Python dumper).
- XML4DR may include rules for **prior-year/SSB-side** logic (`PrimaryKey`, prefilled data) that
  Altinn cannot replicate – classify as `source-ambiguity`/out-of-scope rather than gaps.
- Is XML4DR (exported 2026-06-24) the same revision as the PDF (2026 form)? First check:
  compare `GYLDIGFOM`/title text and run the example values from the PDF through the parsed calcs.
- Licensing/sensitivity of the `Forms/` corpus: keep derived files gitignored; commit only
  summaries and the small Byggesak facts if acceptable.
