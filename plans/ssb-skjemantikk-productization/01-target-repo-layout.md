# 01 Target repo layout

```
ssb-skjemantikk/
├─ README.md            # what/why, 5-minute quickstart, pipeline diagram
├─ AGENTS.md            # agent operating rules (see 03)
├─ LICENSE, CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md, CITATION.cff
├─ docs/
│  ├─ methodology/      # artifact → DSL workflow, audit method, slice-by-slice trials
│  ├─ dsl/              # language reference, examples, design rationale
│  ├─ targets/          # altinn-studio.md, simulator.md, adding-a-target.md
│  └─ case-studies/     # Byggesak (20Byggesak), Kostra 51 – anonymised, short
├─ dsl/                 # Haskell package (library + CLIs)
│  ├─ src/SchemaDSL/    # Types, Builders, Eval, JSON, MetaSchema, Altinn (target)
│  ├─ app/              # schema-dsl-cli
│  ├─ audit/            # schema-audit (loader, Eval parser, extract, align, trace)
│  └─ test/             # golden + property tests
├─ examples/            # small, public, synthetic schemas (hello, matrix, rules)
├─ schemas/             # generated JSON (checked in only for examples)
├─ apps/
│  ├─ simulator/        # Vite + Designsystemet viewer (from skjemantikk-simulator)
│  └─ xml4dr-explorer/  # canvas/web explorer (from tools/xml4dr-explorer), standalone web mode too
├─ workspace/           # gitignored: incoming/, .derived/, altinn-app/ (user data lives here)
│  └─ README.md         # how to lay out a new case; data-handling rules
└─ scripts/             # setup.sh, check.sh, new-case.sh
```

Principles
- **Code and method are public; case data is not.** Real SSB form exports stay in `workspace/` (gitignored). Only synthetic or cleared samples under `examples/`.
- **Altinn app is a build output**, never edited by hand (`workspace/altinn-app/` or a configurable path).
- **Per-case folders** `workspace/<case>/{incoming,derived,reports,dsl-notes}` so several forms can be handled in parallel.
- Case DSL modules for real forms live outside the library (`cases/` plugin dir, gitignored or in a private repo) and are loaded by the CLI.
