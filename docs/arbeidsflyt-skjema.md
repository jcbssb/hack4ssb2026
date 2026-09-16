# Arbeidsflyt for Skjemautvikling: Fra Datamodell til Altinn via Figma

**Team**: Foran Skjema (SSB Hackday 2026)  
**Status**: Konsept & Retningslinjer  

---

## 1. Mål og Konsept
Målet er å forkorte veien fra tidlige idéer, datamodeller eller kravspesifikasjoner til ferdige, testbare Altinn 3-skjemaer.

Arbeidsflyten baserer seg på å bruke **Figma** som den visuelle og brukersentrerte iterasjonsarenaen:
1. **Rask prototyping**: Slippe å bygge Altinn-JSON for hånd i tidlig fase.
2. **Samhandling**: Fageksperter, statistikere og designere kan iterere direkte i Figma.
3. **Automatisert oversettelse**: Gjøre Figma-designet om til kjørbare Altinn 3-skjemadefinisjoner.

---

## 2. Steg i Arbeidsflyten

### Steg 1: Enkel beskrivelse / Datamodell ➔ Figma-prototype
- **Input**:
  - Enkle tekstbeskrivelser / skjemakrav (f.eks. prompter eller punktlister).
  - Datamodeller (JSON Schema, XSD, C# klasser eller OpenAPI specs).
- **Prosess**:
  - AI eller scripts mapper datatyper (f.eks. `string`, `enum`, `boolean`, `array`) til standard form-komponenter.
  - En Figma Plugin oppretter frames med Auto Layout, spørsmålstekster, hjelpetekster og skjemakomponenter (Input, Radio, Checkbox, Dropdown).
- **Output**:
  - En redigerbar, visuell skjemaprototype i Figma.

### Steg 2: Iterasjon og Forenkling i Figma
- **Aktører**: Statistikere, fageksperter, UX-designere.
- **Aktiviteter**:
  - Justere ledetekster, rekkefølge og grupperinger.
  - Teste flyt og brukervennlighet.
  - Merke elementer med kobling mot datamodell (props/navneregler).

### Steg 3: Figma-prototype ➔ Altinn 3 Skjema
- **Input**:
  - Det godkjente Figma-designet.
- **Prosess**:
  - Figma REST API eller en eksport-plugin leser komponenttreet.
  - Noder parses og mappes til Altinn 3 layout-komponenter:
    - `Frame (vertical)` ➔ Form page / Container / Panel
    - `Input component` ➔ `Input` med `textResourceBindings`
    - `Select/Radio component` ➔ `RadioButtons` / `Dropdown` med options
  - Genererer Altinn 3 app-strukturer: `App/ui/layouts/*.json` og tilhørende ressursfiler.
- **Output**:
  - Kjørbart Altinn 3 skjema klart for testkjøring eller videre tilpasning i Altinn Studio.
