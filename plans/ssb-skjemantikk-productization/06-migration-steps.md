# 06 Migration steps (gated)

| # | Step | Gate |
|---|---|---|
| M0 | Decide the open questions in README (licence, owner, history, simulator placement) | Owner sign-off |
| M1 | Finish Trial 8 audit in this repo (P3–P8) so the method is proven before extraction | Audited Byggesak DSL |
| M2 | Sensitive-content review; confirm what SSB allows public (case studies, text) | Written clearance |
| M3 | Create `ssb-skjemantikk` (private first); import via copy, **fresh history** | Repo exists |
| M4 | Apply 02 triage; restructure to 01 layout; rename package; remove hardcoded paths | `cabal build`, simulator build pass |
| M5 | Write AGENTS.md, skills, methodology docs (03) from existing plans/READMEs | Dry-run: a fresh agent completes a synthetic case end-to-end |
| M6 | Synthetic fixtures + golden tests + CI (04) | CI green |
| M7 | Merge simulator as `apps/simulator`; standalone explorer web mode | Both run from `make` |
| M8 | Cold-start test: someone not on the team clones, follows README, produces simulator output from a sample PDF+XML | Success w/o help |
| M9 | Public release: licence, docs site, demo, announce (05) | Owner approval |
| M10 | Archive `hack4ssb2026` with a pointer README | Done |

Risks: internal data in history/docs (mitigated by fresh history + review), Altinn API drift, SSB policy on publishing form definitions, maintaining two languages of docs.
