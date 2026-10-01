# Skjemakart

Copilot canvas to navigate the XML4DR analysis (sections, cells) and highlight
structure, constraints, gating and calculation chains.

- Reads only the derived facts JSON (`incoming-skjema-observations/.derived/20Byggesak.facts.json`, produced by `schema-audit extract`); never the XML.
- Source lives here; `.github/extensions/skjemakart/extension.mjs` is a thin loader (extensions are only discovered under `.github/extensions/`).
- Files: `extension.mjs` (server + actions), `relations.mjs` (relation logic), `ui.html` (UI).

Audit overlay: `cd dsl && cabal run -v0 schema-audit -- align-json <xml> schemas/trial7-byggesak.json audit/alignment/byggesak.json ../incoming-skjema-observations/.derived/20Byggesak.align.json` – the canvas serves it at `/api/align` (derived facts only) and shows ✔/⚠/✖/ⓘ badges, "Audit vs DSL" filters and an Audit block in the detail pane.

Standalone (no canvas, survives closing it): `node tools/skjemakart/serve.mjs [port=8765] [facts.json]` → http://127.0.0.1:8765/. Serves ui.html from disk, so UI edits show on page reload; restart only to pick up server changes.

## Refreshing audit data
`tools/skjemakart/refresh.sh` regenerates `.align.json` and `.findings.json` from the DSL, alignment config and findings file (`facts.json` only changes with `schema-audit extract`). The server reads files on every request and exposes `/api/rev` (file mtimes); open pages poll it every 5 s and show a "New audit data available — click to reload" banner.

## Audits per DSL trial
Derived audit files are per trial: `.derived/20Byggesak.{align,findings}.<tag>.json` (tag = `trial7`, `trial8`, ... from `dsl/schemas/<tag>-byggesak.json`). `refresh.sh [tag...]` builds them (default: all trials >= 7). The viewer has an "Audit of DSL" selector (`?audit=<tag>`, default latest) and shows the change in finding items vs the previous trial. `/api/audits` lists available audits; `/api/align|findings|rev` take `?audit=<tag>`. Shared logic: `audits.mjs`.
