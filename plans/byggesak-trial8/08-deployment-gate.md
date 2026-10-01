# Deployment gate: no Altinn Studio testing yet

_Part of [Trial 8 plan](README.md). Phase P9._

**No injection into the Altinn app and no Altinn Studio/tt02 deployment testing during the
slices.** Altinn work starts only when there is a *potentially complete* DSL (all sections
composed in `ByggesakTrial8`) that has been *fully audited* against XML4DR + PDF, i.e. the audit shows
no open findings other than documented source ambiguities, and the user has accepted it in the
simulator. Only then: inject via the CLI (`--inject-trial8`; never hand-edit
`altinn-skjema-hacking/`), fix Altinn-generator issues in `SchemaDSL.Altinn`, recompile, re-inject.
Altinn-specific findings found at that stage are recorded as a separate `fixKind = altinn-generator` list.
Altinn compile checks that are pure (the compiler emitting layout/expressions, `cabal test`) may still run in
slices, since they need no deployment.
