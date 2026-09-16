# Figma APIs and Document Standards for Schema Prototyping

**Status**: Verified  
**Updated**: 2026-09-16  
**Relevant Resources**: 
- Figma REST API: `https://developers.figma.com/docs/rest-api/`
- Figma Plugin API: `https://developers.figma.com/docs/plugins/`
- Figma REST Spec: `https://github.com/figma/rest-api-spec`
- Altinn 3 App Layout Schema: `https://altinncdn.no/schemas/json/layout/layout.schema.v1.json`

---

## TL;DR
The Figma **REST API is read-only for document canvases** (used to inspect/extract nodes to JSON), while the Figma **Plugin API provides two-way read/write capabilities** (`figma.createFrame()`, `figma.createText()`, `figma.currentPage.appendChild()`) inside the editor. For schema prototyping (e.g. Altinn), the two cleanest pathways are: (1) A lightweight Figma plugin that renders schema components onto the canvas or exports selected frames into Altinn layout JSON; or (2) Designing in Figma and using the REST API (`GET /v1/files/:key`) to traverse the document tree and compile form schemas.

---

## High-Density Specs & Findings

### 1. Architectural Distinction: REST API vs. Plugin API

| Capability | REST API (`api.figma.com/v1`) | Plugin API (`figma.*`) |
| :--- | :--- | :--- |
| **Access Model** | Remote HTTP via Personal Access Token / OAuth2 | In-app sandbox (JavaScript + HTML UI) |
| **Document Mutation** | **Read-Only** for canvas canvas nodes (supports write only for comments, dev resources, variables) | **Read & Write** (programmatically creates frames, components, text, autolayout) |
| **Best Used For** | Extracting design tokens & layout structure into schema definitions (e.g. Figma -> Altinn JSON) | Generating Figma mockups programmatically from existing schemas (e.g. Altinn/JSON Schema -> Figma canvas) |

### 2. Document Node Hierarchy & Mapping to Forms

Figma document tree structure:
`DocumentNode` -> `PageNode` -> `FrameNode` (Form / Page) -> `InstanceNode / ComponentNode` (Form Component)

**Schema Element Mapping Table:**
- `FRAME` (with Auto Layout vertical/horizontal) $\rightarrow$ `Container` or `RepeatingGroup`
- `INSTANCE` (from Design System / Felles Designsystem) $\rightarrow$ Specific Altinn component (`Input`, `Checkboxes`, `RadioButtons`, `Dropdown`, `Datepicker`)
- `TEXT` / Layer Name or Component Props $\rightarrow$ Field label, description, or binding key (`dataModelBindings.simpleBinding`)

### 3. Strategy A: Schema -> Figma Prototype (Figma Plugin)
Uses Figma Plugin API:
- Create container: `const frame = figma.createFrame(); frame.layoutMode = "VERTICAL";`
- Add field label & input box:
  ```js
  await figma.loadFontAsync({ family: "Inter", style: "Regular" });
  const text = figma.createText();
  text.characters = field.title || "Spørsmål";
  frame.appendChild(text);
  ```
- Instant preview: Designers and domain experts immediately see interactive form layouts from raw schemas.

### 4. Strategy B: Figma Prototype -> Altinn Layout Schema (REST or Plugin Export)
Traverse nodes via REST (`GET /v1/files/:file_key/nodes?ids=...`) or Plugin `selection`:
- Filter nodes by naming convention or component instance key (e.g., `Component: Input`).
- Map node properties into Altinn `layout.json` format:
  ```json
  {
    "id": "node_name_or_id",
    "type": "Input",
    "textResourceBindings": { "title": "node.characters" },
    "dataModelBindings": { "simpleBinding": "node.componentProperty.binding" }
  }
  ```

---

## Exact Source Pointers
- `https://developers.figma.com/docs/rest-api/file-endpoints/` – File & node endpoints (`GET /v1/files/:key`).
- `https://developers.figma.com/docs/plugins/api/figma/` – Document creation & node manipulation reference.
- `https://developers.figma.com/docs/plugins/api/properties/nodes-createnode/` – Node creation APIs (`createFrame`, `createText`, `createComponent`).

---

## Actionable Next Steps for Team "Foran Skjema"
1. **Define Prototype Scope**: Decide whether to generate Figma frames from Altinn schemas, or parse Figma frames into Altinn layout JSON.
2. **Setup Plugin Boilerplate**: If generating UI in Figma, initialize a minimal Figma plugin in `prototyper/` (`manifest.json` + `code.ts`).
3. **Establish Component Naming Standard**: Standardize layer/component names in Figma (e.g., `altinn:Input`, `altinn:Checkboxes`) so mapping to Altinn 3 layout components is deterministic.
