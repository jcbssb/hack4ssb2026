# Repository Rules & Constraints for Team "Foran Skjema"

## Strict Principle: Never Edit `altinn-skjema-hacking/` Manually
- The repository `/Users/jcb/src/hack4ssb2026/altinn-skjema-hacking/` must **NEVER** be modified or edited directly (no manual edits to layout JSONs, settings, text resources, or options).
- It is strictly a downstream compilation target for the Dialogue Schema DSL.
- **Rule:** Any change to the Altinn app must be produced solely by compiling Dialogue ASTs through the DSL compiler (`cabal run schema-dsl-cli -- ...` or `SchemaDSL.Altinn`).
- If an Altinn validation, structure, or uniqueness error occurs, fix the code generator in `SchemaDSL.Altinn`, recompile, and run the CLI injector to update `altinn-skjema-hacking/`.
