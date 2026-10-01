# 02 Keep / move / remove

## Keep (core product)
| Current | Target | Notes |
|---|---|---|
| `dsl/src/SchemaDSL/{Types,Builders,Eval,JSON,MetaSchema}.hs` | `dsl/src/…` | Core language |
| `dsl/src/SchemaDSL/Altinn*` | `dsl/src/…/Altinn` | Primary compile target; keep the "never hand-edit output" rule |
| `dsl/app`, `dsl/test`, `schema-dsl.cabal` | same | Rename package `ssb-skjemantikk` |
| `dsl/audit/**` | same | Audit CLI = key differentiator |
| `tools/xml4dr-explorer` | `apps/xml4dr-explorer` | Add standalone (non-Copilot) web mode |
| sibling `skjemantikk-simulator` | `apps/simulator` | Merge in, keep sync script |
| `research/pdf-audit/pdfgrid.py` | `dsl/audit/pdf/` | Part of PDF→facts step; pin deps in `requirements.txt` |
| `plans/byggesak-trial8/*` method parts | `docs/methodology/` | Rewrite as generic method; keep Byggesak as case study |
| `incoming-skjema-observations/README`, `DATA-SOURCES.md` pattern | `workspace/README.md` | Generalise to a data-handling policy; keep manifest/backup idea |
| `dsl/src/.../Examples/{Hackday(hello),MatrixDemo}` | `examples/` | Small synthetic demos |
| Kostra51 / Byggesak examples | case studies | Only if content is cleared for public release (check with SSB) |

## Remove or archive (hack-story / dead ends)
| Item | Reason | Action |
|---|---|---|
| Root README "Team Foran Skjema", hackday framing | Hack story | Rewrite |
| `plans/rapport-foran-skjema-hack4ssb2026.md` | Hackday report | Archive in old repo |
| `plans/figma-schema-prototype.md`, `research/figma-schema-prototyping.md`, `docs/jon-workflow-figma-mcp-altinn.md`, `docs/altinn-figma-to-app-joakim/`, `docs/*arbeidsflyt*`, `docs/*arbeidsflyter-oppsummering.md` | Figma/alternative avenues, not in final DSL workflow | Archive; at most one "related approaches" doc |
| `simulator/*.html` (workflow visualizers, dsl-visualizer) | Hack-era demos of the 4 flows | Drop (superseded by apps/simulator) |
| `ai/`, `altinn/`, `prototyper/` (empty dirs) | Empty | Drop |
| `Skjema 51.pdf` at root | Case data, loose | Move to case workspace / drop |
| `plans/{multi-schema-altinn-preview…,minimal-altinn-tt02-hello-world,manifest-baseline…,ssot-schema-workflow}` | Merge useful parts into targets/altinn docs | Condense, then drop |
| `plans/{byggesak-trial5-plan,bolk-grouping-plan,kostra51-*}` | Trial history | Keep as short case-study "lessons learned" only |
| `dsl/schemas/trial1..7*.json`, `kostra51-*.json`, `hack4ssb-*.json` | Generated, case-specific | Regenerate on demand; keep only example outputs |
| `Examples/ByggesakTrial5..7.hs` | Iteration history | Keep only the final audited Byggesak module (post Trial 8) in private/case repo |
| `dsl/dist-newstyle` (201 MB), `altinn-skjema-hacking/` submodule reference | Build artefacts / separate repo | Ignore; app output path configurable |
| Hardcoded paths (`/Users/jcb/...`, `../skjemantikk-simulator`) | Machine-specific | Parametrise |

## Sensitive-content check before publishing
- Grep for names, internal URLs (`skjema.ssb.no` login details, "Intern SSB-test"), test-user ids, org numbers, tokens.
- Confirm no XML4DR/PDF exports or OCR text of internal forms in history (use fresh history).
- Clear Byggesak/Kostra51 text with SSB before including even as case studies.
