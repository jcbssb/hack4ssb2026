# Keeping the three datamodel files in sync

Every Altinn Studio datamodel lives as **three** files under `App/models/` that must always
describe the same shape - `<ModelName>.cs`, `<ModelName>.schema.json`,
`<ModelName>.xsd` (plus a `.validation.json` some repos also have; only touch it if you're
told to add validation rules). Never edit just one of the three.

`<ModelName>` and the model's `dataType` id (used in `dataModelBindings.field.dataType`) come
from `App/config/applicationmetadata.json` -> `dataTypes[].appLogic.classRef` /
`dataTypes[].id`.

## Adding a new simple field to an existing object

Given a target complex type (e.g. the root type or a nested one like `InternInfo`), adding a
field named `myNewField` (string) requires all three:

**`.cs`** - add a property with matching attributes, appended after the type's existing
properties with the next sequential `Order`:

```csharp
[XmlElement("myNewField", Order = 42)]
[JsonProperty("myNewField")]
[JsonPropertyName("myNewField")]
public string? myNewField { get; set; }
```

For numeric types use `decimal?`/`long?`/`int?` and add a `[Range(Double.MinValue,
Double.MaxValue)]` attribute plus a `ShouldSerializeMyNewField()` method returning
`myNewField.HasValue` (matches the pattern used throughout these models for optional
numerics, so they're omitted from XML when empty rather than serialized as 0).

**`.schema.json`** - add the property to the corresponding `$defs.<TypeName>.properties`:

```jsonc
"myNewField": { "type": "string", "maxLength": 1000 }
// numeric: { "type": "number" }
```

**`.xsd`** - add the element to the corresponding `xs:complexType` sequence, in the same
order as the `.cs`/`.schema.json`:

```xml
<xs:element minOccurs="0" name="myNewField" type="xs:string" />
<!-- numeric: type="xs:decimal" (or xs:long/xs:int) -->
```

## Adding a repeating group (list) field

A `RepeatingGroup`'s `dataModelBindings.group.field` must point at a `List<T>` property:

- `.cs`: a new class `MyListItem` with its own fields (same three-attribute pattern per
  property), plus `public List<MyListItem>? MyList { get; set; }` on the parent type.
- `.schema.json`: a new `$defs.MyListItem` object, and a `"MyList": { "type": "array",
  "items": { "$ref": "#/$defs/MyListItem" } }` property on the parent def.
- `.xsd`: a new `xs:complexType name="MyListItem"`, and on the parent's sequence:
  `<xs:element minOccurs="0" maxOccurs="unbounded" name="MyList" type="MyListItem" />`.

## Checklist before moving on

- [ ] Field/type added to `.cs`, `.schema.json`, and `.xsd` with the same name and
      compatible type in all three.
- [ ] New `Order` values in `.cs` are unique within their containing type and appended
      after existing ones (don't renumber existing fields).
- [ ] The `dataType` used in the layout's `dataModelBindings` matches
      `applicationmetadata.json`'s `dataTypes[].id` for this model.
- [ ] Optional numeric properties get a `ShouldSerializeX()` guard.
