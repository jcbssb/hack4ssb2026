# Step 0 – Housekeeping: rename the folder (DONE)

_Part of [Trial 8 plan](README.md). Phase P0._

`screenshots/` → `incoming-skjema-observations/` (`git mv`; the untracked XML files just move).
Update references: `screenshots/README.md` (also rewrite: it describes only screenshot/PDF
OCR ingestion), root `README.md`, `.github/copilot-instructions/schema-ocr-agent.md`,
`plans/*.md`, `research/byggesak-trial6-audit.md`, `docs/jon-workflow-figma-mcp-altinn.md`,
`dsl/schemas/kostra51-*-report.md`. Rename `bilde.png`/`Skjema 51.textClipping` only if
confirmed unused. Add `.DS_Store` to `.gitignore`. Proposed layout:

```
incoming-skjema-observations/
  README.md
  byggesak-20/   20Byggesak.xml, 20Byggesak (utfylt).pdf
  xml4dr/        XML4DR11.xsd, Forms/*.xml
  misc/          bilde.png, ...
  .derived/      (gitignored) normalized JSON/SQLite produced by the tools
```

Open decision (cheap, ask before Step 0): keep the old path as a symlink for a transition
period or do a clean break. Recommendation: clean break.

## Gitignore and data recovery (done before the rename)
- `.gitignore` already excludes the XML4DR data (old and new folder names, plus `.derived/`).
- `incoming-skjema-observations/DATA-SOURCES.md` + `data-manifest.sha256` (tracked) record contents, provenance, backup
  and checksum verification. Open TODOs for the user: record the original source and a backup location.
- At rename time, `git mv` the tracked files, move the ignored data by plain `mv`, and carry
  `DATA-SOURCES.md`/manifest along (update the paths in the manifest or regenerate it).
