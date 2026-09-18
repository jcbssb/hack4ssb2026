# Identifying real content pages vs. boilerplate

Confirmed by comparing three separate SSB Altinn app repos (`ra0583-01`, `ra0182-02`,
`ra0255-02`) and the felleskode test repo: the standard boilerplate pages are identified
by these exact file/page names, regardless of what the form is actually about:

| Page id | Purpose | Boilerplate? |
|---|---|---|
| `S01_Forside` | Front page / intro text, often with conditional info panels | Boilerplate |
| `S20_Summary` | Auto-generated summary of all other pages via `Summary2` components | Boilerplate structure, but **must be updated** when you add a page (see below) |
| `S70_Tidsbruk` | "Time spent on this form" feedback questions | Boilerplate |
| `S80_Brukeropplevelse` | "User experience" feedback questions | Boilerplate |
| `S90_Kommentarogkontakt` | Free-text comment + contact info | Boilerplate |

These also show up in `App/ui/<layoutSet>/Settings.json` under `excludeFromPdf`, and are
always last in the page `order` array (S20/S70/S80/S90), with `S01_Forside` always first.
Treat the ids as reserved: do not generate a new page with any of these names, and do not
replace their existing layouts from Figma unless the user explicitly asks to modify
boilerplate.

Everything in between - named per form, e.g. `S02_omdispJordPB`, `Om_egenmeldinger`,
`Rapportering_1`, `S05_IKT_Investeringer` - is real, form-specific content. **These are the
pages you generate from the Figma file.** Don't recreate or rename the boilerplate pages;
don't assume the Figma file even contains them (it usually only contains the real content
pages, since the boilerplate is added once from the org's app template).

## How to tell which Figma frames are "real"

- If a Figma frame's content matches one of the five boilerplate purposes above (intro
  panel with next/back buttons only, a page that's just a list of accordions summarizing
  other pages, or the three feedback/comment page types), treat it as already covered by
  the repo's existing boilerplate - don't generate a new page for it, and don't touch the
  existing boilerplate page unless the user explicitly asks you to change it.
- Otherwise, the frame is real content: give it a new page id following the repo's existing
  naming convention (check existing page ids in `App/ui/<layoutSet>/layouts/` first - most
  SSB apps use `S<NN>_<ShortDescriptiveName>`, some use plain descriptive names without a
  number). Ask the user for the desired id/order if it's not obvious from the Figma frame
  name or its position in the file.

## Updating page order and the summary page

When you add a new content page id `<PageId>`:

1. Add `<PageId>` to the `order` array in `App/ui/<layoutSet>/Settings.json`, in the correct
   position (after the last existing content page, before `S20_Summary`/etc. if those
   trailing pages exist).
2. If `App/ui/<layoutSet>/layouts/S20_Summary.json` exists and uses the `Summary2` pattern
   (one `Summary2` component per page, `target: { "type": "page", "id": "<OtherPageId>" }`),
   add a new `Summary2` block targeting `<PageId>`, following the existing blocks' `id`
   naming style (e.g. `Summary2-<6 random chars>`) and `hideEmptyFields: true`.
3. If the repo instead has a hand-written summary/review section, ask the user how they
   want the new page represented there rather than guessing.
