# 11 Skjemakart – further improvements (proposed)

Status: Skjemakart v1 done (`tools/skjemakart/`, canvas + browser; dark theme, relation / fill / has-relation filters, deselect).
It reads only the derived facts JSON, never the XML. Items below are ordered by value for the audit (P3+).

## Audit value (do first)
1. **DSL / PDF overlay**: once `extract dsl` + `align` (P3) exist, colour cells by alignment status (aligned, missing in DSL, extra in DSL, rule mismatch, text mismatch) and add them as filters. Shows gaps directly in the map.
2. **Findings layer**: show F-NNN findings (e.g. F-001 malformed handler445) as badges on cells; click → finding text and evidence. Filter "only cells with findings".
3. **Slice view**: pick a slice (T8a–T8g / bolk) and show only its sections plus the cross-slice edges leaving it (inputs the slice depends on).
4. **Export selection**: copy cell key, "cell + neighbourhood" as the same text `schema-audit cell/around` prints, so it can be pasted to the agent.

## Navigation and relations
5. **Graph view** (calculation/gating DAG) alongside the grid; highlight the same chains; collapse by section.
6. **Path between two cells** (shortest calc/gating path) and **cycle / unreachable-input detection**.
7. **Direction-aware depth** (separate upstream/downstream depth) and an "include gating in chains" switch.
8. **Cross-section edges list** with counts per section pair (matrix view) to find tightly coupled bolks.
9. Show **tuple / repeating groups** and nb/nn language toggle; show cell **kind × severity** (warning vs critical) for constraints.
10. **Rule semantics in detail pane**: render parsed `Eval` as a readable expression tree, with operand cells linked and labelled.

## Usability and robustness
11. URL state (selection, filters, section) in the hash so views can be shared/bookmarked; keyboard navigation (arrows, `/` search, Esc).
12. Search across texts/rules (`grep-eval`-like) with result list; filter-chip counts ("calculated: 312").
13. Large-section performance (virtualised grid); print/export view as PNG/SVG for reports.
14. **Multi-form support**: load any facts JSON (corpus under `xml4dr/Forms/`) via a picker; compare two forms' structure.
15. Standalone mode: `node tools/skjemakart/serve.mjs <facts.json>` (no Copilot needed) for the new `ssb-skjemantikk` repo; unit tests for `relations.mjs` with a tiny synthetic facts fixture; jsdom smoke test in CI.
16. Facts schema: add `schemaVersion` to the `extract` output and validate on load; show the facts file hash/time in the header (provenance).

## Productisation link
Becomes `apps/skjemakart` in `ssb-skjemantikk` (see `plans/ssb-skjemantikk-productization/01-target-repo-layout.md`); items 14–16 are prerequisites for publishing.
