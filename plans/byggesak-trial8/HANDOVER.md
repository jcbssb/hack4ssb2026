# Trial 8 handover (as of 2026-10-01)

> Update: findings are decided and Trial 8 has started (T8a, T8b). Resume with `12-trial8-remaining-work.md`; the "Next steps" below are partly superseded.

Resume point for a fresh session. Read this, then `README.md` (plan, freeze policy, progress log).

## Goal
Audit the Byggesak (20Byggesak) Dialogue DSL against incoming SSB artifacts (XML4DR form, corpus, filled PDF) with tools that keep big data out of agent context, so the workflow can modernize old schemas. No Altinn deployment until the DSL is fully audited.

## Rules
- Never hand-edit `altinn-skjema-hacking/`; Altinn changes only via the DSL compiler/injector.
- `incoming-skjema-observations/` is read-only; derived data goes in `incoming-skjema-observations/.derived/` (gitignored). Never commit XML or derived data.
- DSL freeze: `dsl/schemas/trial7-byggesak.json` / `ByggesakTrial7.hs` are the audit baseline. Fixes go in a new `ByggesakTrial8.hs`, slice by slice, simulator-tested (`../skjemantikk-simulator`).
- Commit/push only when asked; trailer `Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>`. Plans live in `plans/`.

## State (all committed and pushed; last commit a30ab7a)
- `schema-audit` (Haskell, `dsl/audit/`): `outline cell around trace grep-eval extract dsl align align-json audit`. Modules `Audit.{Xml4dr,Eval,Index,Export,Dsl,Align,Findings,Audit}`. See `dsl/audit/README.md`.
- Alignment config `dsl/audit/alignment/byggesak.json` maps all 31 DSL bolks (A,B,C2-C4,C10-C16,C/D eKOSTRA,D1,D2,E0-E2,F0-F4,G0-G4,H,I) to XML sections. All align 1:1, no DSL-only or XML-only cells (except 2 explained in A; two F3 overrides).
- Findings `dsl/audit/findings/byggesak.json`: F-002..F-008, all status `proposed` (F-001 = malformed `handler445` in Section_H3, source defect, to raise with SSB).
  - F-002 soft-required not expressible (dsl-feature); F-003 DSL stricter on required; F-004 conditional on always-visible calculated cells; F-005 missing gating; F-006 DSL-only constraints (171+); F-007 source-only checks (email/phone/plausibility/herav<=total, dsl-feature); F-008 calc inputs differ (C14 etc.).
  - `schema-audit audit` result: 710 items, 0 untriaged; new unmatched items show as NEW.
- Skjemakart (`tools/skjemakart/`): audit badges, "Audit vs DSL" and "has finding" filters, Findings block, reset button, URL-hash back/forward, new-data banner via `/api/rev`.

## Commands (from repo root)
- Refresh derived data: `tools/skjemakart/refresh.sh` (align + findings JSON).
- Viewer: `node tools/skjemakart/serve.mjs 8765` then open `http://127.0.0.1:8765/` (use 127.0.0.1; a Python server shadows `localhost` on IPv6). Currently running as PID 89778; restart if the server code changes.
- Single slice: from `dsl/`: `cabal run -v0 schema-audit -- align ../incoming-skjema-observations/byggesak-20/20Byggesak.xml schemas/trial7-byggesak.json audit/alignment/byggesak.json bolk_x`
- Canvas extension in `.github/extensions/skjemakart`: each `extensions_reload` gives a new port; prefer the standalone server.

## Next steps
1. User review/confirmation of findings F-002..F-008 (decide per family: dsl-content / dsl-feature / keep as deliberate; F-006 especially). Update statuses.
2. Triage finer: split F-006/F-007 into per-family findings if wanted (rules are `kind` + `prefix` + `contains`/`bolks`/`xmlKind`).
3. Map the leftovers: `Section13` (2 radios, no DSL bolk), 2 cross-bolk XML checks skipped.
4. `extract pdf` (pymupdf, `research/pdf-audit/pdfgrid.py`) and align the filled PDF against DSL/XML.
5. Write `research/byggesak-trial8-audit.md` report generation from `audit`.
6. Trial 8 DSL fixes in `ByggesakTrial8.hs` per slice; verify in the simulator; re-audit and diff vs Trial 7.
7. Corpus stats across other XML4DR forms; gated Altinn injection via compiler CLI only.

## Open user TODOs
- Provenance details and private backup location in `DATA-SOURCES.md`.
- Raise F-001 with SSB.
- Productization decisions (licence, owner, fresh history, simulator placement, name casing); see `plans/ssb-skjemantikk-productization/`.

## Gotchas
- macOS `sed -i` needs `''`; use python/edit for multi-line edits.
- Environment: GHC 9.10.3, cabal 3.16, Node 26, Python 3.14.
- Headless UI test with jsdom: `/tmp/jd/` (ephemeral; recreate if needed, end script with `process.exit(0)`).
