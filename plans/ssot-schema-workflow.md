# Plan: Single Source of Truth (SSOT) Arbeidsflyt for Skjemautvikling

**Mål**: Etablere og formalisere en robust **Single Source of Truth (SSOT)** arkitektur og arbeidsflyt for team *Foran Skjema* (SSB Hackday 2026).  
**Kjerneidé**: Én autoritativ, semantisk skjemadefinisjon som driver alle eksterne representasjoner (Figma-prototyper, Altinn 3 layouts, datamodeller og simulatorer) uten redundans eller desynkronisering.

---

## 1. Hvorfor en Semantisk SSOT?

I tradisjonell skjemabygging oppstår lett desynkronisering:
- **Datamodellører** jobber i XSD eller JSON Schema (kun datatyper og valideringsregler).
- **Designere** tegner skjermbilder i Figma (kun visuelle lag, ustrukturerte tekster).
- **Utviklere** skriver Altinn 3 `layout.json` og `resource.nb.json` for hånd.

### Løsning: Den semantiske dialogspesifikasjonen som SSOT
Vi definerer én maskinlesbar og versjonskontrollert fil (`baseline-schema.json`, validert mot `baseline-schema-meta.json`) som inneholder:
1. **Identitet & Kontekst**: Undersøkelseskode (f.eks. `RA-0666`), oppgavegiver-opplysninger, formål og hjemmel.
2. **Semantisk Dialogrekkefølge**: Rekkefølge av spørsmål og steg.
3. **Spørsmål og Hjelpetekster**: Klarspråklige ledetekster, veiledning og forklaringer.
4. **Datatyper og Bindinger**: Hvilket datamodellfelt (`fieldId` / `simpleBinding`) hvert svar tilhører.
5. **UI & Designsystem Hints**: Valgfritt metanivå for komponentpreferanser (`Input`, `RadioButtons`, `Dropdown`).

---

## 2. SSOT Kompilator- og Generator-arkitektur

```
                 ┌──────────────────────────────────────────────┐
                 │          Single Source of Truth (SSOT)       │
                 │      dsl/baseline-schema.json (eller DSL)    │
                 └──────────────────────┬───────────────────────┘
                                        │
             ┌──────────────────────────┼──────────────────────────┐
             ▼                          ▼                          ▼
   ┌───────────────────┐      ┌───────────────────┐      ┌───────────────────┐
   │   Figma Tolker    │      │ Altinn 3 Tolker   │      │  Simulator Tolker │
   │  (Plugin Script)  │      │  (CLI / Node/Py)  │      │   (Web Canvas)    │
   └─────────┬─────────┘      └─────────┬─────────┘      └─────────┬─────────┘
             ▼                          ▼                          ▼
   Figma AutoLayout Canvas    - App/ui/layouts/*.json    Sanntids testbar
   (Felles Designsystem)      - App/models/schema.json   interaktiv prototype
                              - resource.nb.json
```

---

## 3. Livssyklus og Arbeidsflyt (Steg-for-steg)

### Steg 1: Definisjon og Validering av SSOT
- Skjemaet defineres eller oppdateres i `baseline-schema.json` (eller genereres fra Haskell Dialogue DSL).
- Valideres mot `dsl/baseline-schema-meta.json` for å garantere at påkrevde felt og typer er korrekte.

### Steg 2: Automatisk Generering av Målformater
- **Figma Prototype Generator**:
  - Leser SSOT og oppretter frames i Figma med ferdige Felles Designsystem-komponenter.
  - Hver node tagges med `fieldId` i `pluginData`.
- **Altinn 3 Artifact Generator**:
  - Genererer `layout.json` (med `Header`, `Input`, `RadioButtons`, koblet mot `dataModelBindings`).
  - Genererer `resource.nb.json` for alle tekster.
  - Genererer `schema.json` (ren datamodell).
- **Simulator**:
  - Laster SSOT inn i simulatoren (`simulator/index.html`) for umiddelbar testing av dialogflyten.

### Steg 3: Håndtering av Design-iterasjoner (Toveis synkronisering / Round-trip)
Når fageksperter eller designere endrer tekster eller rekkefølge i Figma:
1. Endringene skal **ikke** overskrive Altinn-filer direkte.
2. Figma-eksportøren dytter oppdaterte tekster/rekkefølge tilbake til **SSOT (`baseline-schema.json`)**.
3. SSOT regenererer deretter de tekniske Altinn 3-filene. Dette sikrer at SSOT alltid forblir den autoritative kilden.

---

## 4. Konkrete Implementasjonsfaser

- [x] **Fase 1: Etablere Metaschema & Baseline Sample**
  - Opprettet `dsl/baseline-schema-meta.json` og `dsl/baseline-schema.json`.
  - Bygget og testet Haskell DSL-støtte for semantisk serialisering.
- [x] **Fase 2: Simulator som verifikasjonsarena**
  - Implementert og åpnet side-panel canvas for sanntidssimulering av dialog og payload.
- [ ] **Fase 3: Altinn 3 Eksportør (`ssot-to-altinn`)**
  - Lage et script/CLI som transformerer `baseline-schema.json` til en komplett Altinn 3-mappestruktur (`App/ui/layouts/Form.json`, `resource.nb.json`, `applicationmetadata.json`).
- [ ] **Fase 4: Figma Plugin Kobling (`ssot-to-figma`)**
  - Knytte Figma Plugin API til å parse `baseline-schema.json` og instansiere designelementer.
