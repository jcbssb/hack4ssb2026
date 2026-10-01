# Incoming data: sources, backup and recovery

The XML4DR data in this folder is **gitignored** (about 6 MB, SSB form definitions) and exists
only on the local machine unless backed up. Tracked here: this note and its checksum manifest.

## What is ignored
- `byggesak-20/20Byggesak.xml` – XML4DR export of form 20Byggesak (Admin/Custom `ExportedBy`: `ojj@2026-06-24`; file dated 2026-09-30)
- `xml4dr/XML4DR11.xsd` – schema for the XML4DR format
- `xml4dr/Forms/*.xml` – 46 other SSB forms in XML4DR format

## Provenance / how to reconstruct
- Origin: **some of the data came from SSB's form site, <https://skjema.ssb.no/User/Form/Form.aspx>** (single form view)
  and the form list at **<https://skjema.ssb.no/User/UserForms.aspx>**
  (the form PDFs/views). **TODO (owner: jcb): record which files came from there versus received
  otherwise (the XML4DR exports by "ojj"), and the date retrieved.**
- Re-exporting: ask the SSB form-tool owners for a fresh XML4DR export; the XSD is the contract.
- Everything derived (facts JSON, audit reports) must be reproducible from these files via the
  `schema-audit` tools (see `plans/byggesak-trial8/`), so the originals are the only irreplaceable part.

## Backup
- **TODO (owner: jcb): keep a copy of `byggesak-20/20Byggesak.xml`, `xml4dr/XML4DR11.xsd` and `Forms/` in a private
  place (SSB-internal share or private archive), not in this public-ish repo. Note the location here.**
- Verify a restored copy against `data-manifest.sha256`:
  `cd incoming-skjema-observations && shasum -a 256 -c data-manifest.sha256`

## Don'ts
- Treat everything here as **read-only** (see README); the checksum manifest detects accidental edits.
- Do not commit the XML files or derived outputs that embed their full text.
- Commit only small summaries (outline, audit reports) once reviewed.
