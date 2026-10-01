# Incoming SSB form observations

Raw artifacts about legacy SSB forms that we audit our Dialogue DSL against. Formerly `screenshots/`.

**Read-only input.** Never edit, reformat, rename or delete files here (agents and tools included).
Tools read from this folder and write only to `.derived/` or to `research/`/`dsl/`. If a source
file seems wrong, record it in an audit report; do not fix it in place. New material is added as new
files. `chmod -R a-w` on the data is a cheap safeguard.

```
byggesak-20/   20Byggesak.xml (XML4DR, ignored), 20Byggesak (utfylt).pdf
xml4dr/        XML4DR11.xsd and Forms/*.xml – other SSB forms (ignored)
misc/          screenshots and clippings (bilde.png, Skjema 51 clipping)
.derived/      tool output (ignored)
```

- The XML4DR data is **not committed**; see [DATA-SOURCES.md](DATA-SOURCES.md) for provenance,
  backup and `data-manifest.sha256` verification.
- Audit plan and tooling: `plans/byggesak-trial8/`.

## Ingesting screenshots / PDFs
Supported: `.pdf`, `.png`, `.jpg`, `.jpeg`, `.webp`. Put them in a folder per form (e.g. `byggesak-20/`) or `misc/`.
The **Schema OCR & Reverse Engineering Agent** (`.github/copilot-instructions/schema-ocr-agent.md`)
turns them into `dsl/schemas/<dialogueId>.json` plus a `-report.md` of legibility and DSL limitations.
For PDFs it uses macOS PDFKit (Swift); vector PDFs can also be read with `research/pdf-audit/pdfgrid.py`.
Where XML4DR exists for a form, prefer it as the source of rules and use the PDF as a visual cross-check.
