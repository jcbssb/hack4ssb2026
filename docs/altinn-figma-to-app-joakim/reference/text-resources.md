# Text / language resources

Location: `App/config/texts/resource.<lang>.json`, one file per language present in that
folder (`nb` = bokmål, `nn` = nynorsk, `en` = English - a repo may have more or fewer; only
touch the files that actually exist).

Each file has the same shape:

```json
{
  "language": "nb",
  "resources": [
    { "id": "S04_NydyrkingSoknader.RadioButtons-EhhlTL.title.EbtI", "value": "..." },
    {
      "id": "S04_NydyrkingSoknader.RepeatingGroup-l8FtOW.title.ppS6",
      "value": "Du har oppgitt {0}, av dette vennligst fordel arealet ...",
      "variables": [
        { "key": "SkjemaData.OmsoktNydyrkaAreal[0].antDekarOmsoktNydyrkaAr", "dataSource": "dataModel.<DataTypeId>", "defaultValue": "0" }
      ]
    }
  ]
}
```

- `id` naming convention seen throughout real apps: `<PageId>.<ComponentId>.<bindingKey>.<shortHash>`
  (the hash suffix is just a short random disambiguator - generate a new random 4-char
  base62-ish string per id, it has no semantic meaning). Shared ids like `lang.option.ja` or
  `lang.tittel.navigation.neste` are reused across many pages/components instead of being
  page-scoped - reuse an existing shared id where one already fits, rather than creating a
  near-duplicate.
- `variables` lets a text interpolate a datamodel value via `{0}`, `{1}`, ... placeholders in
  `value`; `dataSource` is `dataModel.<dataTypeId>` where `<dataTypeId>` matches a
  `dataTypes[].id` in `App/config/applicationmetadata.json`.

## Rule: every new textResourceBindings id must exist in every language file

When a layout page references a new resource id:

1. Check whether that id already exists in `resource.nb.json` (or whichever is the repo's
   primary language) - if yes, reuse it exactly; don't add a duplicate with different
   casing/wording.
2. If it doesn't exist, add an entry with a real, correctly translated value to **every**
   `resource.<lang>.json` file present in `App/config/texts/` - never add it to only one
   language file. If you don't have a translation for a language, ask the user for the
   wording rather than guessing or leaving it out.
3. Keep the same `id` and `variables` (if any) across all language files; only `value`
   differs per language.
