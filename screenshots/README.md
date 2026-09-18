# Ingesting Legacy SSB Schema Screenshots

Place old SSB schema screenshots or PDF files in this folder (`hack4ssb2026/screenshots/`).

Supported formats: `.pdf`, `.png`, `.jpg`, `.jpeg`, `.webp`.

## Workflow
1. Save your screenshot or PDF here (e.g. `screenshots/20Byggesak (utfylt).pdf` or `screenshots/ra-0100-page1.png`).
2. The **Schema OCR & Reverse Engineering Agent** (`.github/copilot-instructions/schema-ocr-agent.md`) will inspect the document.
   - For PDFs, it uses macOS native Swift PDFKit to extract text and structure across pages without external dependencies.
3. The agent will:
   - Extract semantic fields, prompts, bolker, options, and types into `dsl/schemas/<dialogueId>.json`.
   - Ask clarifying questions if conditional logic is observed.
   - Generate `dsl/schemas/<dialogueId>-report.md` documenting text legibility confidence and DSL limitations (e.g. if the form uses checkboxes, matrix tables, or skip logic not yet supported in the minimal DSL).
4. Run the visualizer or Altinn injector to compile and test the new schema!
