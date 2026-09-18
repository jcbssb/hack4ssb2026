# Component catalog (most common Altinn Studio layout components)

This covers the components that show up in almost every SSB Altinn form. For anything not
listed here, grep `reference/layout.schema.v1.json` for `"Comp<Type>External"` (e.g.
`CompCheckboxesExternal`) to get the exact property list.

## Shared concepts

**`dataModelBindings`** shapes (from `IDataModelBindingsSimple` /
`IDataModelBindingsOptionsSimple` / `IDataModelBindingsList` in the schema):

```jsonc
// simple value component (Input, TextArea, Datepicker, ...)
"dataModelBindings": { "simpleBinding": { "field": "SkjemaData.myField", "dataType": "A3_RA-0583_M" } }
// shorthand also seen and valid: "dataModelBindings": { "simpleBinding": "SkjemaData.myField" }

// selection component with options (RadioButtons, Checkboxes, Dropdown)
"dataModelBindings": { "simpleBinding": { "field": "SkjemaData.myChoice", "dataType": "..." } }

// RepeatingGroup / Group backed by a list in the datamodel
"dataModelBindings": { "group": { "field": "SkjemaData.MyRepeatingList", "dataType": "..." } }
```

Use the object form (`{ "field", "dataType" }`) for new pages - it's the form used in newer
layouts and is unambiguous about which datamodel/data type a binding targets. `dataType`
must match a `dataTypes[].id` in `App/config/applicationmetadata.json` (usually the app's one
form datamodel, e.g. `A3_RA-0583_M`).

**`textResourceBindings`** - every value is a resource id (not literal text), typically named
`<PageId>.<ComponentId>.<bindingKey>.<shortHash>` or a shared `lang.*` id reused across
pages. Common keys: `title` (label/question text), `description`, `body` (Panel/Alert),
`help`.

**`hidden`** - a boolean expression, evaluated client-side. Common forms seen in real apps:

```jsonc
["equals", ["dataModel", "SkjemaData.someField"], "1"]
["notEquals", ["component", "RadioButtons-xyz"], "1"]
["or", [ ... ], [ ... ]]
["and", [ ... ], [ ... ]]
["not", [ ... ]]
```

## Header

```jsonc
{ "id": "Header-abc123", "type": "Header", "size": "L" | "M" | "S" | "h2" | "h3" | "h4",
  "textResourceBindings": { "title": "..." } }
```

## Paragraph / Text

Plain text block, `textResourceBindings.title` is shown as the body text (no label
semantics). Use `Paragraph` for descriptive text; `Text` is rarer, mostly used as a
read-only inline value display.

## Panel / Alert

Info/warning/danger callouts, often conditionally `hidden`.

```jsonc
{ "id": "Panel-abc123", "type": "Panel", "variant": "info" | "warning" | "success", "showIcon": true,
  "textResourceBindings": { "title": "...", "body": "..." } }

{ "id": "Alert-abc123", "type": "Alert", "severity": "danger" | "warning" | "info" | "success",
  "textResourceBindings": { "title": "...", "body": "..." } }
```

## Input

```jsonc
{
  "id": "Input-abc123", "type": "Input",
  "dataModelBindings": { "simpleBinding": { "field": "SkjemaData.myField", "dataType": "..." } },
  "textResourceBindings": { "title": "..." },
  "required": true,
  "readOnly": false,
  "formatting": { "number": { "decimalScale": 0, "allowNegative": false, "suffix": " dekar" }, "align": "right" }
}
```

Set `required: true` by default for editable, user-entered inputs. Read-only inputs must
never be required by default: omit `required` or set it to `false`, because a read-only
calculated value is not something the user can complete. Use `required: false` for editable
inputs when the design explicitly marks the field optional.

Use `formatting.number` for numeric inputs (matches how quantities/areas are formatted in
real forms). `readOnly: true` is used for computed/derived values (e.g. sums shown via
calculation rules).

## TextArea

Same as `Input` but for multi-line free text; no `formatting`.

When the text area is user-entered, set `required: true` unless the design explicitly marks
the comment or description as optional.

## RadioButtons / Checkboxes / Dropdown

All three are "selection" components sharing the same options mechanism:

```jsonc
{
  "id": "RadioButtons-abc123", "type": "RadioButtons",
  "dataModelBindings": { "simpleBinding": { "field": "SkjemaData.myChoice", "dataType": "..." } },
  "textResourceBindings": { "title": "...", "description": "..." },
  "required": true,
  "optionsId": "JaNeiOptionlist"
}
```

`optionsId` must match a file `App/options/<optionsId>.json` (see
`reference/options-lists.md`). `Checkboxes`/`MultipleSelect` bind to a list field instead of
a single value - check `IDataModelBindingsList`/relevant schema section before using them.
Set `required: true` by default when the selection is needed to proceed, and use `false`
only when the design clearly makes the selection optional.

## Datepicker

Like `Input`, binds a single date-typed field via `simpleBinding`; no `optionsId`.

## Group / RepeatingGroup

`Group` is a static visual grouping of other components (often used with a shared `hidden`
expression); `RepeatingGroup` repeats a set of child components once per row of a datamodel
list.

```jsonc
{
  "id": "RepeatingGroup-abc123", "type": "RepeatingGroup",
  "dataModelBindings": { "group": { "field": "SkjemaData.MyList", "dataType": "..." } },
  "textResourceBindings": { "title": "..." },
  "maxCount": 99999,
  "children": ["Input-child1", "Input-child2"],
  "edit": { "mode": "onlyTable", "editButton": false, "saveButton": false, "addButton": false, "deleteButton": false },
  "tableColumns": { "Input-child1": { "editInTable": false }, "Input-child2": { "editInTable": true, "width": "24%" } }
}
```

Children referenced in `children` are defined as normal top-level components elsewhere in
the same `layout` array (they are not nested objects). An `Option`-typed component (see
below) can appear as a repeating group child to render a fixed label per row instead of an
editable field.

## Option

A read-only label pulled from an options list, keyed by a value in the datamodel - used
inside repeating groups/tables to show a category name next to its data:

```jsonc
{
  "id": "Input-abc123", "type": "Option",
  "textResourceBindings": { "title": "..." },
  "value": ["dataModel", "SkjemaData.MyList.categoryField"],
  "optionsId": "MyOptionsList"
}
```

## NavigationButtons

Always the last component on a page in real apps; not bound to data.

```jsonc
{ "id": "NavigationButtons-abc123", "type": "NavigationButtons",
  "textResourceBindings": { "next": "lang.tittel.navigation.neste", "back": "lang.tittel.navigation.tilbake" },
  "showBackButton": true,
  "validateOnNext": { "page": "current", "show": ["All"] } }
```

## Summary2 (used on the boilerplate summary page only)

See `reference/page-identification.md` - one `Summary2` block per content page, not
something you add to a regular content page.
