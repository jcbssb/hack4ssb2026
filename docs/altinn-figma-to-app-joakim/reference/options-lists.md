# Option lists

Location: `App/options/<optionsId>.json`. Filename (without `.json`) is the `optionsId`
referenced by `RadioButtons`/`Checkboxes`/`Dropdown`/`Option` components.

Format: a JSON array of objects with `value` and `label`. `label` is almost always a text
resource id (standard practice), not literal text:

```json
[
  { "label": "lang.option.ja", "value": "1" },
  { "label": "lang.option.nei", "value": "0" }
]
```

`value` is always a string, even for numeric-looking codes. Some option lists have more
metadata per entry (check existing files in the target repo for local conventions before
inventing new fields).

## Before creating a new options list

1. Check `App/options/` for an existing list that already fits (a generic yes/no list like
   `JaNeiOptionlist` is commonly reused across many components/pages - don't duplicate it).
2. If the Figma design shows specific option text, create the list with a descriptive
   `optionsId` (PascalCase, matching the naming style already used in that repo), and make
   sure every `label` resolves to a text resource id you also add in
   `App/config/texts/resource.*.json` (see `text-resources.md`).
3. Wire the new/-existing `optionsId` into the component's `optionsId` property.
