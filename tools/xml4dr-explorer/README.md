# xml4dr-explorer

Copilot canvas to navigate the XML4DR analysis (sections, cells) and highlight
structure, constraints, gating and calculation chains.

- Reads only the derived facts JSON (`incoming-skjema-observations/.derived/20Byggesak.facts.json`, produced by `schema-audit extract`); never the XML.
- Source lives here; `.github/extensions/xml4dr-explorer/extension.mjs` is a thin loader (extensions are only discovered under `.github/extensions/`).
- Files: `extension.mjs` (server + actions), `relations.mjs` (relation logic), `ui.html` (UI).
