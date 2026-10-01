# schema-audit

Query tool for XML4DR form definitions (see `plans/byggesak-trial8/`). Reads from
`incoming-skjema-observations/` (read-only) and writes only to `incoming-skjema-observations/.derived/`.

```bash
cd dsl
X=../incoming-skjema-observations/byggesak-20/20Byggesak.xml
cabal run -v0 schema-audit -- outline $X                 # sections: rows, cells, kinds, gated, checks, required
cabal run -v0 schema-audit -- cell    $X Section7/V1648  # one cell: texts, calc, checks, gating, reads/read-by
cabal run -v0 schema-audit -- cell    $X "herav"         # or a text search (up to 5 hits)
cabal run -v0 schema-audit -- around  $X Section7/V2015_92   # + same row/column, reads-from, read-by
cabal run -v0 schema-audit -- trace   $X Section7/V2015_92   # upstream/downstream closure + gating
cabal run -v0 schema-audit -- grep-eval $X "i samsvar med plan"   # search rules and messages
cabal run -v0 schema-audit -- evals   $X                 # Eval parser coverage and failures
cabal run -v0 schema-audit -- extract $X ../incoming-skjema-observations/.derived/20Byggesak.facts.json
```

Cell keys are `<setId>/<dataId>` (opaque ids from the XML, e.g. `Section7/V1648`). Kinds: `label`, `input`,
`calculated` (own `calculation` handler), `prefilled` (dark grey), `radio`. A cell is *gated* when a
`guidance` handler elsewhere sets its state (`normal`/`readonly`); that is the source of the
"light grey opens when …" rules. Modules: `Audit.Xml4dr` (loader), `Audit.Index` (derived relations),
`Audit.Eval` (JavaScript-subset parser for `<Eval>`), `Audit.Export` (JSON facts).

## align (P3)

    cabal run -v0 schema-audit -- align <xml> <dsl.json> audit/alignment/byggesak.json [bolk_a ...]

Aligns DSL fields to XML4DR cells per bolk (override → matrix key → number key → label → fuzzy → singleton) and prints matched / dsl-only / xml-only / explained buckets with diffs (required, prefilled, calculated, conditional, type, checks). Config: `audit/alignment/byggesak.json`.

Diffs now also compare **calculation inputs** (cells/fields read, resolved across bolks; pure copy fields are followed to their source) and **check partners** (fields that co-occur in a constraint / XML check handler). Only fields from mapped bolks are compared; add bolks to the config to widen the comparison. Several bolks are aligned together (`alignMany`) so cross-bolk links resolve.
