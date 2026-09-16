# Schema DSL (Haskell)

Minimal semantic Dialogue Schema DSL for SSB Hackday 2026 (Team *Foran Skjema*).

## Purpose
Expresses pure dialogue semantics (fields, question prompts, types, required flags) completely decoupled from UI layout and platform execution.

## Project Structure
- `schema-dsl.cabal` - Cabal package definition.
- `src/SchemaDSL/Types.hs` - Semantic data types (`Dialogue`, `Question`, `QuestionType`, `Prompt`).
- `src/SchemaDSL/JSON.hs` - JSON serialization and deserialization via `aeson`.
- `app/Main.hs` - CLI demo printing encoded Hello World dialogue.
- `test/Spec.hs` - Round-trip tests for encoding, decoding, and failure modes.

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
