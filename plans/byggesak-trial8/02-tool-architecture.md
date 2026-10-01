# Step 1 – Tool architecture

_Part of [Trial 8 plan](README.md). Phase P1. Principle: parse once into an index; the agent only sees small query results._

Principle: **parse once into a normalized, queryable index; the agent only ever sees small
query results** (a cell, its neighborhood, a diff table). Raw XML/PDF is never pasted.

```
XML4DR ──┐
PDF ─────┼─► extract ─► normalized facts (JSON/SQLite) ─► align ─► audit ─► gap report
DSL json ┘                                                   ▲
                                         inspect CLI (spike/neighborhood queries)
```

**Language choice.**
- **Haskell** for everything touching the DSL and the XML (new cabal executable
  `schema-audit` in `dsl/`, sharing `SchemaDSL.Types`/`Eval` so the audit can *evaluate* DSL
  rules and compare with XML4DR rules rather than only diff strings). Needs an XML library
  (`xml-conduit` or `xml`) – check availability in the cabal store first; fallback is
  a tiny Python XML→JSON dumper (`ElementTree` is already proven on these files) with the
  rest in Haskell.
- **Python (existing)** for PDF geometry: reuse `research/pdf-audit/pdfgrid.py` /
  `pdfboxes.json` (vector boxes, shade, values). Do not port to Haskell; just emit the same
  normalized fact format.

### Normalized fact model (the shared contract)

One record per **cell**, keyed by a stable id, with provenance per source:

```
Cell { cellId        -- e.g. "C11/1.1/a"  (section/row/col from XML4DR set/tuple/data ids)
     , source        -- xml4dr | pdf | dsl
     , sectionPath, rowLabel, colLabel     -- labels resolved via TextPointer (nb, nn)
     , kind          -- input | calculated | prefilled | conditional | radio | label
     , inputControl, format (numeric/text/maxlen)
     , required      -- FieldFilled critical handlers
     , calc          -- parsed Expr (Add/Sub/Mul/Div/Field/Const + weighted-avg pattern)
     , rules         -- parsed checks: {cmp, left, right, severity critical|warning, message}
     , opensWhen     -- parsed SetState conditions (> 0, >= 1, Ja) -> Predicate
     , value         -- example value (PDF / XML Value)
     , pos           -- pdf page+bbox when available }
```

Expression handling: a small parser for the XML4DR `Eval` language
(`GetFieldValue(set,cell)`, `FieldFilled`, `+ - * /`, comparisons, `if/else if` blocks,
`obThis`) into the DSL's `Expr`/`Predicate` (+ an `Unparsed Text` fallback that is counted
and reported so unsupported idioms become a visible backlog rather than silent loss).
