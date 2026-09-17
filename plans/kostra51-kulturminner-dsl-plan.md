# Plan: Reversering av SSB KOSTRA 51Plan (Kulturminneforvaltning 2026) til Dialogue DSL og Altinn

## 1. Skjermbildeanalyse (`screenshots/bilde.png`)

- **Skjematittel:** `51. Planbehandling, miljø- og kulturminneforvaltning 2026`
- **Kontekst/Enhet:** Fylkeskommune / KOSTRA
- **Obligatorisk-merke:** `* Obligatorisk felt`
- **Bolk B1:** `B1. Tid brukt til arbeid med kulturminner i fylkeskommunen.`
- **Underseksjon 1:** `1. Hvor mange årsverk brukte fylkeskommunen til kulturminnearbeid i alt?`
  - Felt 1: Grå bakgrunn (Beregnet sum eller forhåndsutfylt/sum-felt).
  - Felt 1a: `... 1a. Herav til arkeologi?` (hvit bakgrunn, numerisk/desimal årsverk).
  - Felt 1b: `... 1b. Herav til saksbehandling ift. nyere tids kulturminner?` (hvit bakgrunn, numerisk/desimal årsverk).
  - Felt 1c: `... 1c. Herav til saksbehandling ift. landskap/by/arealplan?` (hvit bakgrunn, numerisk/desimal årsverk).
  - Felt 1d: `... 1d. Herav til annet?` (hvit bakgrunn, numerisk/desimal årsverk).
- **Underseksjon 2:** `2. Midlertidige årsverk`
  - Felt 2a: `2a. Hvor mange årsverk til kulturminneforvaltning var midlertidige?` (hvit bakgrunn, numerisk/desimal årsverk).
- **Enhet for alle felter:** `Antall årsverk` (desimaltall, typisk 1 eller 2 desimaler, f.eks. 1.5 årsverk).

---

## 2. Gaps og begrensninger i gjeldende DSL

1. **Beregnet sum / readOnly / locked felt:**
   - I gjeldende DSL (`Question`) har vi `required` og `condition`, men ikke eksplisitt `readOnly :: Bool` eller `calculation :: Maybe String` / `calculated :: Bool`.
   - I Altinn tilsvarer dette `readOnly: true` (eller en beregningsfunksjon / expression sum `["sum", ["dataModel", ...]]`).
2. **Numerisk enhet / post-fix label:**
   - Spørsmålene deler kolonneoverskriften `Antall årsverk`. I DSL har vi `Prompt` med `label` og `helpText`. Vi kan inkludere `(antall årsverk)` i ledeteksten eller bruke `annotations` / `unit: "årsverk"`.
3. **Betingelse (Condition):**
   - Skal midlertidige årsverk (2a) eller underpostene (1a-1d) være betinget av at totalen > 0? I skjermbildet er alle 1a-1d hvite (åpne).
4. **Desimal vs heltall:**
   - Årsverk i KOSTRA rapporteres oftest med desimaler (f.eks. `QDecimal` med 1-2 desimaler).

---

## 3. Gjennomføringssteg

- [ ] **Steg 1 (Avklaringer & DSL-utvidelse):**
  - Avklar om `readOnly` bør legges til i `Question` i DSL-et, eller om vi representerer 1 som sum/beregnet via `annotations` inntil videre.
  - Avklar om årsverk skal være `QDecimal` (f.eks. 1 eller 2 desimaler) eller `QInteger`.
- [ ] **Steg 2 (Definisjon i Haskell & JSON):**
  - Legg til `kostra51KulturminneDialogue` i `dsl/src/SchemaDSL/Examples.hs`.
  - Generer `dsl/schemas/kostra51-kulturminner.json`.
  - Opprett deficit-rapport `dsl/schemas/kostra51-kulturminner-report.md`.
- [ ] **Steg 3 (Kompilator & Altinn-injeksjon):**
  - Oppdater `SchemaDSL.Altinn.Compile` til å respektere ev. `readOnly` på komponenter hvis feltet er beregnet.
  - Utvid CLI `--inject-kostra51` for injeksjon inn i `altinn-skjema-hacking`.
  - Injiser og verifiser data model (`SkjemaData.kostra51_kulturminner.*`), layout og tekster.
- [ ] **Steg 4 (Verifisering i simulator & Altinn):**
  - Oppdater `simulator/schemas.js` og test i visningscanvas.
  - Commit til `altinn-skjema-hacking`.
