# Trial 8: remaining work (handover plan, 2026-10-01)

Goal: a full **Trial 8** DSL that addresses all accepted findings except F-006 (deferred to Trial 9), then audit, simulator acceptance and (gated) Altinn injection. Read `HANDOVER.md` and `README.md` first.

## Decisions (user, 2026-10-01)
| Finding | Decision |
|---|---|
| F-002 soft-required | Accepted: DSL gets a required level none/warn/error (dsl-feature) |
| F-003 DSL stricter on required | Relax to source; use soft-required once F-002 exists |
| F-004 conditional on calculated cells | Drop condition on calculated cells; gate only input cells |
| F-005 missing gating | Add the gating |
| F-006 DSL-only constraints (297) | **Deferred to Trial 9**; split into per-family findings first |
| F-007 source-only checks (179) | Add as DSL features (format + plausibility) |
| F-008 calc inputs differ | Follow the source (e.g. C14 reads C10/C11 directly) |
| F-009 Strandsone flag | Add municipality context flag; gate D1 q3 |

## Rules for how Trial 8 is built
- `ByggesakTrial8.hs` **patches the frozen Trial 7 dialogue slice by slice** (`onBolk`, `onQuestions`, whole-dialogue transforms); keep `t7_` field ids. Do **not** regenerate the DSL from sources; each Trial N is relative to the earlier trial.
- Trial 7 (`trial7-byggesak.json`, `ByggesakTrial7.hs`) stays frozen as baseline.
- Never hand-edit `altinn-skjema-hacking/`; Altinn only through the compiler/injector, and not before the whole DSL is audited.
- Every slice: unit test in `dsl/test/Spec.hs` (Trial 7 unchanged + Trial 8 changed), `cabal test`, `cabal run schema-dsl-cli -- --update-all` (writes `schemas/trial8-byggesak.json` and `simulator/schemas.js`), `tools/skjemakart/refresh.sh trial8`, check finding counts in Skjemakart (`?audit=trial8`; the sidebar diffs against trial7), simulator walkthrough by the user.
- Commit/push only when asked; trailer `Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>`.

## Status (finding items, trial7 -> trial8, 0 untriaged)
| Finding | Trial 7 | Trial 8 now | Target |
|---|---|---|---|
| F-002 | 106 | 106 | 0 |
| F-003 | 28 | 24 | 0 |
| F-004 | 49 | 10 | 0 |
| F-005 | 10 | 10 | 0 |
| F-006 | 297 | 297 | Trial 9 |
| F-007 | 179 | 179 | 0 |
| F-008 | 41 | 41 | 0 |
| F-009 | 0 (flag cells explained) | 0 | flag + gating exist |

Done: T8a (bolk A: kommunenummer, navn, skjemaansvarlig, e-post no longer required; F-003 -4). T8b (calculated cells unconditional, except `t7_c3_2_1_c` which the source gates; F-004 49 -> 10).

## Next slices (suggested order)
1. **T8c, F-005 + rest of F-004.** The 10 remaining F-004 items are G1/G2/G3 cells (`Seksjon_H1/V2012_50,51, VB2021_54,55, VB2022_2,3`, `Seksjon_H2/V1730,1731,1733`, `Section_H3/V2012_18`) that the DSL gates but the source treats as calculated/always visible; check their calc inputs (F-008). F-005: list with `grep` on `findings.trial8.json` (`findings[id=F-005].items`), add the gating where the source's `guidance` handlers open cells (`schema-audit trace`/`around` shows "gated by").
2. **T8d, F-008 calculation inputs.** C14 columns d/b2 should read C10/C11 directly; copy chains per the audit items. Riskiest slice: verify totals in the simulator (`testTrialAgainstPdf` style tests exist).
3. **T8e, F-002 feature.** Replace/extend `required :: Bool` with a level (none|warn|error) in `SchemaDSL.Types`, JSON (keep old JSON readable), `MetaSchema`, simulator (non-blocking warning), `SchemaDSL.Altinn` (non-blocking validation), `validateRules`. Then apply: 106 soft-required items (derive from `findings.trial8.json`, rule `required: dsl=no xml=warning`) and the 24 F-003 leftovers (B1 `VB2021_*`, C10, I.20-24, radios) as soft/none per source.
4. **T8f, F-009 feature.** Prefilled context flag (coastal municipality, from `Section13/VB2019_2` Strandsone; `VB2019_1` Kommune_nr2) usable in predicates; gate D1 row 3 (`Section_E1/V2012_7` and its row: readonly when 0, soft warning when 1). Resolves one of the 2 skipped XML checks.
5. **T8g, F-007 checks.** Source-only checks: email format (`EPOSTADR`), phone range (`TELEFONNR > 20999999`), `VB2021_*` > 50000 warning, plausibility and herav <= total checks (179 items; group by family with `schema-audit grep-eval`). Existing `Constraint` covers comparisons; formats need a new check type (types, JSON, simulator, Altinn).
6. **Whole-form re-audit (P8).** Target: only F-001 (source defect `handler445`, raise with SSB) and F-006 remain; untriaged 0; the 2 skipped checks resolved or documented.
7. **User acceptance in the simulator**, then **gated Altinn injection (P9)** via `cabal run schema-dsl-cli -- ...` (add `--inject-trial8`, see `pagedInjectCommands` in `dsl/app/Main.hs`); fix generator issues in `SchemaDSL.Altinn`.

## Trial 9 (not now)
Split F-006 (297 DSL-only constraints) into per-family findings by `kind` + `prefix` + `contains`/`bolks` in `dsl/audit/findings/byggesak.json`; decide per family keep/drop/promote. Then Trial 9 patches Trial 8 the same way; Skjemakart already supports `?audit=trial9` once `schemas/trial9-byggesak.json` exists (`refresh.sh trial9`).

## Other open items
- Section13/Section10/setSID are mapped as explained cells (see README progress). The audit report generator (`research/byggesak-trial8-audit.md`), PDF extraction/alignment (`extract pdf`) and corpus stats (`Forms/`) are still undone (steps 4, 5, 7 in `HANDOVER.md`).
- User TODOs: provenance and private backup in `DATA-SOURCES.md`, raise F-001 with SSB, productization decisions (`plans/ssb-skjemantikk-productization/`).
- Tools: standalone Skjemakart `node tools/skjemakart/serve.mjs 8765` (use 127.0.0.1); `tools/skjemakart/README.md` and `dsl/audit/README.md`.
