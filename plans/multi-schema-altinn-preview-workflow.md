# Plan: Multi-Schema Deployment and Preview Workflow on Altinn Studio

## 1. Context & Constraint
- **Altinn Studio Preview Constraint:** Altinn Studio previews and compiles applications directly from the **`master`** (or `main`) branch of the app repository. It does not automatically provision ephemeral preview environments for feature branches.
- **Goal:** Enable rapid iteration, comparison, and switching between multiple schema definitions (e.g. `hack4ssb-hello`, `hack4ssb-comprehensive`, or reverse-engineered schemas from OCR) on the live Altinn Studio preview platform without manual merge churn or breaking the baseline survey flow.

---

## 2. Recommended Workflow Strategies

We recommend a **Dual Strategy**:

### Strategy A: Multi-Page Side-by-Side Coexistence (Default / Recommended for Hackday)
In Altinn 3 apps, layout sets (`mainlayout`) support multiple independent pages in the sequence (`Settings.json`).
Instead of replacing page files, each compiled Dialogue DSL schema manifests as its own dedicated page:
- `S05_hack4ssb_hello` (Baseline Hello World)
- `S06_hack4ssb_comprehensive` (Extended synthetic schema)
- `S07_<schemaId>` (Schemas reverse-engineered from screenshots)

**How it works:**
1. The compiler injector names pages uniquely (`S05_<id>`, `S06_<id>`, etc.) and inserts them into `Settings.json` `pages.groups[0].order`.
2. All generated schemas are visible in the same preview session on Altinn Studio. Reviewers can click "Next" or navigate via the page tabs directly in Altinn Studio's preview toolbar.
3. Common text resources and options coexist cleanly without collision because keys and option filenames are prefixed by field ID or schema ID (`lang.hack4ssb.<fieldId>.*`, `<FieldId>Valg.json`).

### Strategy B: Active Schema Switcher via CLI (`--activate-schema`)
When you want Altinn Studio to test a specific schema in isolation (or make it the primary form page right after `S01_Forside` without other test pages):
1. **Clean Baseline Tracking:** Keep a clean git tag or baseline commit `altinn-baseline` (the pristine survey before injected test pages).
2. **One-Command Switcher:**
   ```bash
   cabal run schema-dsl-cli -- --activate-schema synthetic ../altinn-skjema-hacking
   # or
   cabal run schema-dsl-cli -- --activate-schema hello ../altinn-skjema-hacking
   # or
   cabal run schema-dsl-cli -- --activate-schema dsl/schemas/my-ocr-schema.json ../altinn-skjema-hacking
   ```
3. What `--activate-schema` does:
   - Resets working tree changes in `altinn-skjema-hacking` to clean baseline (`git checkout -- .` and clean old generated files).
   - Injects the selected schema into `layouts/`, `options/`, `Settings.json`, and `texts/`.
   - Creates a tidy commit on `master` with description: `test(schema): activate <schemaId> for Altinn Studio preview`.
   - Prompts user to push: `git push origin master`.

---

## 3. Concrete Implementation Steps

### Phase 1: Clean Up & Isolate Current Working Tree
1. Commit the currently injected synthetic comprehensive schema changes to `master` (or a dedicated commit):
   - Files: `S05_hack4ssb_comprehensive.json`, `PrimarTeknologiValg.json`, `OnskerVeiledningValg.json`, `StotteTemaerValg.json`, `Settings.json`, and text resources.
2. Verify page order in `Settings.json` so both `S05_hack4ssb_hello` and `S05_hack4ssb_comprehensive` can either coexist or be cleanly toggled.

### Phase 2: Implement CLI Schema Switcher & Selector
Extend `schema-dsl-cli`:
1. `cabal run schema-dsl-cli -- --list-schemas`: Shows available schemas (`hello`, `synthetic`, and any JSON files in `dsl/schemas/`).
2. `cabal run schema-dsl-cli -- --activate-schema <NAME|FILE> <ALTINN_DIR>`:
   - Resets old test artifacts.
   - Injects only the requested schema as the active test step.
   - Updates `Settings.json` and text resources cleanly.

### Phase 3: Push to Master for Live Altinn Studio Preview
Whenever you switch or update the active schema:
```bash
cd altinn-skjema-hacking
git push origin master
```
Altinn Studio will immediately reload the layout and preview the active schema.
