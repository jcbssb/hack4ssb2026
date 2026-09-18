---
name: altinn-figma-to-app
description: >
  Turn an Altinn Studio app design in Figma into real app files: layout pages, UI
  components, option lists, language/text resources, and datamodel bindings. Use this
  whenever the user gives a Figma file/frame (link, file key, or node id) for an Altinn
  Studio app and asks to implement, generate, sync, or update pages/components/forms
  from it, or asks how Figma designs map to Altinn Studio layouts.
---

# Altinn Studio: Figma design -> app implementation

This skill turns a Figma design (built with the shared Altinn Studio component library -
Input, Button, RadioButtons, etc.) into the actual files an Altinn Studio app repo expects:
`App/ui/<layoutSet>/layouts/*.json` pages, `App/options/*.json` option lists,
`App/config/texts/resource.*.json` language resources, and the three datamodel files under
`App/models/`.

Read this file fully before starting. It links out to `reference/*` files with more detail -
open those when you need the specifics they cover instead of guessing.

## 0. Access to the Figma file

The `figma-altinn` Copilot CLI extension provides `figma_login`, `figma_whoami`,
`figma_get_file`, `figma_get_images`. The user authenticates with their own Figma account
(OAuth, no API key to paste). If a `figma_*` tool call fails with "Not logged in", call
`figma_login` once and ask the user to complete the browser sign-in, then retry.

- Extract the file key from whatever the user gives you: a Figma URL looks like
  `https://www.figma.com/design/<fileKey>/<name>?node-id=<nodeId>`.
- Always call `figma_get_file` with `simplified: true`. It strips styling/geometry and
  resolves Figma component instances to their library component name (e.g. `componentName:
  "Input"`), which is exactly what you need to identify Altinn components.
- For a large file, first fetch with a shallow request (or a specific frame's `nodeIds` from
  the URL's `node-id` param) rather than the whole document, to avoid huge payloads.
- Each Figma frame/page in the design generally corresponds to one Altinn layout page. Each
  top-level Altinn-library component instance inside a frame corresponds to one layout
  component, in visual top-to-bottom order.
- Some Figma responses omit the component metadata dictionaries. In that case the tool
  preserves the `INSTANCE` node's `name` as `componentName`; use that together with
  `componentProperties` and the surrounding frame context. Names such as `Input`, `Button`,
  `Header`, `RadioButtons`, `Dropdown`, and `Input tekst` are useful library clues, but
  decorative instances such as icons, logos, spacers, and navigation chrome are not form
  components and should not become layout entries.

## 1. Figure out which pages are new/real content vs. boilerplate

Before creating pages, read `reference/page-identification.md`. SSB Altinn apps share a standard set of boilerplate pages. In this project, the exact
boilerplate page ids are:

- `S01_Forside`
- `S20_Summary`
- `S70_Tidsbruk`
- `S80_Brukeropplevelse`
- `S90_Kommentarogkontakt`

These pages already exist in the target repo and must **not** be recreated - only real,
form-specific content pages from the Figma file should become new layout pages. That file
also explains how the summary page and page-order settings must be updated when you add a
new content page.

## 2. Map Figma components to Altinn layout components

Read `reference/component-catalog.md` for the most common components (Input, RadioButtons,
Checkboxes, Dropdown, TextArea, Datepicker, Header, Paragraph, Panel/Alert, Group,
RepeatingGroup, NavigationButtons, Option) with their key properties and real examples. The
full authoritative schema is `reference/layout.schema.v1.json`
(`https://altinncdn.no/toolkits/altinn-app-frontend/4/schemas/json/layout/layout.schema.v1.json`)
- grep it for `CompXExternal` when you need a component type not covered in the catalog, or
  to double check an exact property name/enum value.

General page shape:

```json
{
  "$schema": "https://altinncdn.no/toolkits/altinn-app-frontend/4/schemas/json/layout/layout.schema.v1.json",
  "data": { "layout": [ /* array of components, in order */ ] }
}
```

Every component in a page needs a unique `id` within that layout set. Use the convention
seen in real apps: `<ComponentType>-<6 random base62 chars>`, e.g. `Input-UtEgVq`.
Before saving, compare every generated component id with all existing component ids in the
target layout file and regenerate any collision. Keep the ids stable on later edits so
existing expressions, group children, table columns, overrides, and summaries continue to
refer to the same component. Where relevant, also add `dataModelBindings` and
`textResourceBindings`. `Group`/`RepeatingGroup` reference their children by id in a
`children` array.

For components whose Altinn schema supports the `required` property, set `"required": true`
by default when generating an editable, user-entered component. This is the normal form
convention: users should not be able to continue without completing the designed field. A
read-only field must never be required by default; read-only, calculated, informational, and
otherwise non-user-entered components should omit `required` or use `"required": false`.
Set `"required": false` for editable fields when the Figma design or surrounding wording
clearly indicates that the field is optional. Do not add `required` to component types whose
schema does not support it; verify the property in `reference/layout.schema.v1.json` when
uncertain.

## 3. Decide if you need options lists and datamodel bindings

- If a component needs a fixed set of choices (RadioButtons, Checkboxes, Dropdown, or the
  `Option` component inside a repeating group row), it needs an `optionsId` pointing at a
  file in `App/options/<optionsId>.json`. See `reference/options-lists.md` for the exact
  format, and check whether a suitable list (e.g. a shared yes/no list) already exists
  before creating a new one.
- Any component with a `dataModelBindings` entry needs a matching field in the datamodel.
  See `reference/datamodel-sync.md` - **every** datamodel field change must be applied to
  all three files (`.cs`, `.schema.json`, `.xsd`) together, never just one.

## 4. Text resources

Every `textResourceBindings` value is a resource id, not literal text. Resource ids must be
unique across the entire application, not merely unique within one page. Use the convention
seen in real apps (`<PageId>.<ComponentId>.<bindingKey>.<shortHash>`) or reuse an existing
shared id such as `lang.tittel.navigation.neste` when the text is intentionally shared.
Before adding a resource, search every `resource.<lang>.json` file for the id and do not
overwrite an existing resource with different text. Read
`reference/text-resources.md`: check `App/config/texts/resource.<lang>.json` for each
language present in that folder (`nb` = bokmål, `nn` = nynorsk, `en` = English, etc.), and if
an id doesn't already exist in a file, add it there with real translated text - never leave
a language file missing a key that exists in the others.

## 5. Page registration is mandatory

Creating a layout file is not enough to make a page appear in the application. Whenever a
new page is created or an existing page is renamed/reordered, update the matching layout
set's `App/ui/<layoutSet>/Settings.json` in the same change:

1. Add the page id exactly once to the appropriate `pages.groups[].order` array.
2. Preserve the existing order and keep shared boilerplate pages in their established
   positions; form-specific pages normally go between the front page and the trailing
   summary/feedback pages.
3. If the layout set has multiple page groups, put the page in the group that controls the
   relevant task.
4. Check for duplicate page ids and confirm that the filename, page id in `Settings.json`,
   summary target, and any process/task references agree.
5. If `S20_Summary.json` uses `Summary2`, add one unique summary component targeting the new
   page as described in `reference/page-identification.md`.

Do not report a page as implemented until both its layout JSON and `Settings.json` are
updated and validated.

## 6. Worked example

`reference/examples/` has a small, self-contained worked example: a content page
(`content-page-example.json`) using Header/RadioButtons/Group/Input/RepeatingGroup/Option/
NavigationButtons, its matching `options-list-example.json`, its `nb`/`nn` text resource
entries, the `Settings.json` page-order change, and the `Summary2` block to add to the
boilerplate summary page. Use it as a template for shape/naming conventions, not as literal
content to copy.

The supplied design files were also inspected:

- `RA-0583 KOSTRA Forvaltning av landbruksarealer` contains real form pages named `Side 1`,
  `Side 4`, `Side 5`, `Side 6`, `Side 7`, `Side 8`, `Side 9`, and `Side 10`; it also contains
  shared Altinn header/login/modal chrome. Ignore that chrome and map the actual form content
  frames/components.
- `RA-0182 Egenmeldt sykefravær` contains a clearly instructional `1. Introduksjon` canvas
  with text explaining how to use the design kit. This is not an app page to generate; it is
  boilerplate/documentation and should be skipped when implementing a schema.
- `#hack4ssb - 4an skjema` is a component-library playground: its canvas/section names include
  `❖ Input`, `Button`, `Button Group`, and repeated component examples. It is useful for
  learning the design-kit component names/properties, but it is not a real schema page and
  must not be converted wholesale into application layouts.

## 7. Workflow checklist

1. Get the Figma file/frame with `figma_get_file` (`simplified: true`).
2. Classify each Figma page/frame as a boilerplate page (skip) or new content page.
3. For each new content page: create `App/ui/<layoutSet>/layouts/<PageId>.json`, mapping
   each component instance in order; assign collision-free component ids; set supported
   input components to `required: true` by default; and update
   `App/ui/<layoutSet>/Settings.json` page order in the same change (plus the boilerplate
   `S20_Summary` page as a new `Summary2` block targeting it, if that repo uses that pattern).
4. Create/extend option lists under `App/options/` for any fixed-choice component.
5. Add any new datamodel fields to all three files under `App/models/`.
6. Add every new globally unique text resource id, with real text, to every
   `resource.<lang>.json` under `App/config/texts/`; reuse shared ids only when the wording
   is exactly the same.
7. Sanity check: every page id appears exactly once in `Settings.json`, every component id is
   unique within its layout set, every `dataModelBindings.field`/`simpleBinding` resolves to
   a real datamodel property, every `optionsId` matches a file in `App/options/`, and every
   `textResourceBindings` value exists in all language files without duplicate/conflicting
   resource definitions.
