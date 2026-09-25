# Schema DSL (Haskell)

Minimal semantic Dialogue Schema DSL for SSB Hackday 2026 (Team *Foran Skjema*).

## Purpose
Expresses pure dialogue semantics (fields, question prompts, types, required flags) completely decoupled from UI layout and platform execution.

## Project Structure
- `schema-dsl.cabal` - Cabal package definition.
- `src/SchemaDSL/Types.hs` - Semantic data types (`Dialogue`, `Question`, `QuestionType`, `Prompt`).
- `src/SchemaDSL/JSON.hs` - JSON serialization and deserialization via `aeson`.
- `src/SchemaDSL/Eval.hs` - Reference semantics for calculations and constraints (target-neutral).
- `app/Main.hs` - CLI demo printing encoded Hello World dialogue.
- `test/Spec.hs` - Round-trip tests for encoding, decoding, and failure modes.

## Calculations and Constraints

Relations between values are declared at dialogue level, separate from the questions,
using a small numeric expression language (`Expr`: `Field`, `Const`, `Add`, `Sub`, `Mul`, `Div`).

- **Calculations** derive a numeric field from others, e.g. totals and remainders.
- **Constraints** are rules that must hold (`left <comparison> right`), with a message,
  a severity (`SevError` blocks, `SevWarning` only warns), an optional guard `condition`,
  and optional `reportOn` fields for where the message appears.

```haskell
calculations =
  [ Calculation "delSum" (sumOf ["delA", "delB"])
  , Calculation "rest"   (Sub (Field "total") (Field "delSum"))   -- remainder
  ]
constraints =
  [ Constraint
      { constraintId = "deler-innenfor-total"
      , constraintLeft = Field "delSum", comparison = CmpLte, constraintRight = Field "total"
      , message = "Delene kan ikke overstige totalen.", severity = SevError
      , constraintCondition = Nothing, reportOn = []
      }
  ]
```

Semantics (defined by `SchemaDSL.Eval`, followed by every target):
- Empty or non-numeric fields count as 0; `1,5` and `1.5` are both accepted.
- Division by zero has no value, and a constraint without a value is not violated.
- Equality and comparisons tolerate rounding noise (1e-6).
- By default a constraint's message is shown on the entered fields it depends on
  (calculated fields are traced back to their inputs).
- `validateRules` reports unknown fields (also in conditions), non-numeric targets, duplicates and calculation cycles.

Conditions (`condition` on questions, bolker and constraints) can also compare numbers with
`Compare Expr Comparison Expr`, e.g. `Compare (Field "mottatt") CmpGt (Const 0)` to open cells
only when another field is above 0. Calculated fields can be used in conditions too.

Targets:
- **Altinn**: calculated fields become display-only `Number` components with a `value`
  expression. Constraints become expression validations in `App/models/<DataType>.validation.json`.
- **Simulator**: evaluates the same rules live. A constraint is checked on the last visible
  step it depends on.

## Matrices (authoring helper)

`SchemaDSL.Builders` expands tables of numeric cells into plain questions, calculations and
constraints (the JSON format is unchanged). Cells get ids `<prefix>_<row>_<col>`, formulas refer
to cells by key, and parts combine with `mconcat`:

```haskell
matrix Matrix
  { matrixPrefix = "t4_c12"
  , matrixRows   = [ matrixRow "1" "Mottatt", (matrixRow "1.1" "Herav mangelfulle") { rowCols = Just ["a"] } ]
  , matrixCols   = [ matrixCol "a" "I alt", matrixCol "b" "I samsvar med plan"
                   , (matrixCol "c" "Ikke i samsvar") { colFormula = Just (\c -> Sub (c "a") (c "b")) } ]
  , matrixRules  = [ atLeastZero "ikkeNegativ" EachRow "c" "Kan ikke være negativ"
                   , partsAtMost "mangelfulle" EachColumn ["1.1"] "1" "Herav kan ikke overstige i alt" ]
  }
```

Column formulas compute a cell from its row, row formulas from its column (skipping columns
with `colSummable = False`, e.g. averages). Rules are generated wherever all their cells exist.

## Building and Running Tests

```bash
cd dsl

# Build package
cabal build

# Run test suite
cabal test

# CLI commands for maintaining SSOT schemas
cabal run schema-dsl-cli -- --update-baseline   # Updates dsl/baseline-schema.json
cabal run schema-dsl-cli -- --emit-meta         # Updates dsl/baseline-schema-meta.json
cabal run schema-dsl-cli -- --update-all        # Updates both meta and baseline schemas
cabal run schema-dsl-cli -- --print-baseline    # Prints baseline schema to stdout
cabal run schema-dsl-cli -- --print-meta        # Prints meta schema to stdout
```
