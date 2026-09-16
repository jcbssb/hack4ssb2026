# Plan: Altinn 3 Compiler & Fragment Injektor fra Schema DSL

**Mål**: Implementere en kompilator/tolk for vår generiske semantiske skjemarepresentasjon (`SchemaDSL` / `baseline-schema.json`) som programmatisk genererer de nødvendige Altinn 3 deklarative fragmentene og injiserer dem direkte inn i filene i `altinn-skjema-hacking/App/` via en CLI-kommando.

---

## 1. Målarkitektur: Fra DSL til Altinn App Injeksjon

```
  [SchemaDSL (Haskell) / baseline-schema.json]
                       │
                       ▼
       ┌───────────────────────────────┐
       │     Altinn 3 Interpreter      │
       │   (Kompilator / Transpiler)   │
       └───────────────┬───────────────┘
                       │ Genererer deklarative fragmenter:
       ┌───────────────┼──────────────────────────────┐
       ▼               ▼                              ▼
 [Layout Page]    [Options Lists]              [Text Resources]
  S05_*.json      Hack4ssbSporValg.json        resource.nb/nn/en.json
       │               │                              │
       └───────────────┼──────────────────────────────┘
                       ▼
           ┌───────────────────────┐
           │   App File Injector   │
           └───────────┬───────────┘
                       │ Oppdaterer automatisk:
                       ├──► App/ui/mainlayout/Settings.json (pages order)
                       ├──► App/ui/mainlayout/layouts/S05_*.json (ny side)
                       ├──► App/options/*.json (nye alternativlister)
                       └──► App/config/texts/resource.*.json (nye tekster)
```

---

## 2. Fragmentene som Mappes og Genereres

For hvert semantisk element i `Dialogue`:

### 2.1 Sidenavigasjon (`App/ui/mainlayout/Settings.json`)
- **Fragment**: `"S05_" ++ dialogueId`
- **Regel**: Injiseres inn i `pages.groups[0].order` etter `S01_Forside` hvis den ikke allerede finnes.

### 2.2 Side-layout (`App/ui/mainlayout/layouts/S05_<DialogueId>.json`)
Kompilerer `steps :: [Question]` til Altinn-komponenter:
- **`Header`**: Dialogens tittel (`size: "h2"`).
- **`Panel`**: SurveyContext (organisasjon og formål).
- **`QText` ➔ `Input`**:
  - `dataModelBindings.simpleBinding`: Modellfelt (f.eks. `Hjelpefelter.hjelpefelt1`).
  - `textResourceBindings`: `{ "title": "<fieldId>.label", "help": "<fieldId>.help" }`.
- **`QChoice` ➔ `RadioButtons` / `Dropdown`**:
  - `optionsId`: Generert liste-id.
  - Genererer tilhørende `App/options/<OptionsId>.json`.
- **`QInteger` ➔ `Input` (format: number)**:
  - `type: "Input"`, `formatting: { "number": ... }`.

### 2.3 Tekstressurser (`App/config/texts/resource.<lang>.json`)
For hvert steg og felt:
- `<fieldId>.label` ➔ Prompts label.
- `<fieldId>.help` ➔ Prompts helpText.
- Injiseres inn i eksisterende ressurs-array uten å overskrive eksisterende app-tekster.

### 2.4 Datamodell-allokerer (Model Binding Strategy)
For en eksisterende app med `A3_RA-1000_M`:
- Tolken holder en tabell/strategi over ledige modelltilordninger (f.eks. `Hjelpefelter.hjelpefeltN`), eller genererer en ny C#/XSD modell dersom appen støtter dynamiske modeller.

---

## 3. CLI Kommando Grensesnitt

Vi tilbyr en ren, énlinjes CLI-kommando:
```bash
# Fra dsl/ mappen:
cabal run schema-dsl-cli -- --inject-altinn ../altinn-skjema-hacking

# Eller via npm/python runner dersom Haskell-kompilatoren kalles som bibliotek:
python3 scripts/inject_altinn.py --schema dsl/baseline-schema.json --target altinn-skjema-hacking
```

### Funksjoner i CLI-kommandoen:
1. `--dry-run`: Viser alle JSON-diffs og nye filer som vil lages, uten å skrive til disk.
2. `--target <dir>`: Sti til mål-repoet (`altinn-skjema-hacking`).
3. Idempotens: Kan kjøres flere ganger; oppdaterer eller oppretter uten duplisering.

---

## 4. Implementasjonssteg

1. **Fase 1: Altinn Fragment Generator Module (`SchemaDSL.Altinn`)**:
   - Haskell-modul (eller komplementært transpiler-skript) som tar `Dialogue` og produserer:
     - `LayoutJSON`
     - `OptionsJSON`
     - `TextResourcesMap`
2. **Fase 2: File Merger / Injector Engine**:
   - Leser eksisterende `Settings.json` og merger inn ny side i riktig posisjon.
   - Leser `resource.*.json` og merger inn nye ressursnøkler (beholder eksisterende).
   - Skriver ut nye layout- og options-filer.
3. **Fase 3: CLI Integrasjon i `schema-dsl-cli`**:
   - Legge til `--inject-altinn <path>` i `app/Main.hs`.
4. **Fase 4: Verifikasjon på `clean-baseline` branch**:
   - Kjøre kommandoen mot `clean-baseline` branchen.
   - Inspisere `git diff` og verifisere at appen er i valid Altinn-tilstand.
