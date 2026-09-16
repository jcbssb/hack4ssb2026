# Plan: Generere Figma Skjemaprototype (Fra JSON Schema + Supplerende Informasjon)

**Mål**: Utvikle en løsning for å generere en visuell Figma-skjemaprototype som representerer et enkelt skjema (f.eks. registrering av Hackday Team Name), og vurdere om dette kan gjøres helautomatisk fra JSON Schema eller krever supplerende metadata for å tilfredsstille SSB- og Altinn-standarder.

---

## 1. Konklusjon: Kan det lages automatisk fra JSON Schema, eller trengs tilleggsinformasjon?

### Svar: En hybrid-tilnærming (JSON Schema + Tilleggsmetadata / UI-hints)
- **Hva en ren JSON Schema gir automatisk**:
  - Felttype (`string` ➔ Input, `boolean` ➔ Checkbox, `enum` ➔ RadioButtons/Dropdown).
  - Feltnavn og tekniske restriksjoner (`maxLength`, `minimum`, `required`).
  - Grunnleggende ledetekst (dersom `title` og `description` er utfylt).
- **Hvorfor ren JSON Schema alene IKKE er tilstrekkelig for SSB- og Altinn-standard**:
  1. **SSB Skjemakontekst**: Mangler header, oppgavegiverinformasjon (org.nr/virksomhetsnavn), veiledningstekst og formål/lovhjemmel.
  2. **Altinn UI-layout**: JSON Schema har ingen definisjon av rekkefølge, kolonnebredder (`grid`), sideskift eller komponentstørrelser.
  3. **Designsystem-binding**: Mangler kobling mot Felles Designsystem (Digdir) stiler (fonter, spacing, farger, varianter).
- **Løsning**: Bruke **JSON Schema + Form Metadata (UI Schema / Dekorator)** eller la AI berike den enkle modellen til en fullverdig skjemaspesifikasjon før den tegnes i Figma.

---

## 2. Arkitektur for Figma-prototyping

```
[JSON Schema (f.eks. teamName)]
              +
[Supplerende UI & SSB Metadata]  ──(AI Berikelse / Mapping)──► [Standardisert Form Spec]
                                                                        │
                                                                        ▼
                                                             [Figma Plugin / Generator]
                                                                        │
                                                                        ▼
                                                             [Visuell Figma Prototype]
                                                             (Felles Designsystem stiler)
```

### 2.1 Skjemamodell med supplerende metadata
For å produsere et "Hello World"-skjema som oppfyller standardene, kombineres datamodellen med supplerende konfigurasjon:

```json
{
  "schema": {
    "type": "object",
    "properties": {
      "teamName": { "type": "string", "title": "Teamnavn" }
    },
    "required": ["teamName"]
  },
  "uiMetadata": {
    "header": {
      "title": "SSB Hackday 2026",
      "subtitle": "Registrering av prosjekt og deltakere",
      "context": "Oppgavegiver: Statistisk sentralbyrå (Org.nr: 971 526 920)"
    },
    "fields": {
      "teamName": {
        "component": "Input",
        "label": "Hva er navnet på ditt Hackday Team?",
        "helpText": "Oppgi et unikt navn på laget, f.eks. 'Foran Skjema'.",
        "placeholder": "F.eks. Foran Skjema",
        "required": true
      }
    },
    "submitButton": {
      "text": "Send inn registrering"
    }
  }
}
```

---

## 3. Implementasjonsfaser for Figma Prototype-generatoren

### Fase 1: Enkel Figma Plugin Boilerplate i `prototyper/`
1. Etablere en minimal Figma-plugin (`manifest.json` og `code.ts` / `code.js`).
2. Pluginen har en enkel UI (dialog) med:
   - Tekstboks for å lime inn JSON Schema / Form Spec.
   - Knapp: "Generer Altinn Skjema".

### Fase 2: Rendering til Figma Canvas (Node Tree Generation)
1. **Side og Hoved-ramme (Frame)**:
   - Oppretter en vertikal Auto Layout-ramme med standard bredde (f.eks. 680px for desktop skjema).
   - Setter bakgrunnsfarge (#FFFFFF) og padding (32px/24px iht. designsystemet).
2. **SSB & Altinn Header-komponenter**:
   - Tittel (`Header L`, Bold, 28px).
   - Ingress/hjelpetekst (16px Regular, sekundærfarge).
3. **Form-komponenter**:
   - For hvert felt:
     - Spørsmålstekst / Label (`Header S`, SemiBold, 16px) med ev. rød stjerne for påkrevd felt (`*`).
     - Hjelpetekst / tooltip (14px).
     - Rektangel/ramme som simulerer Input-felt (høyde 44px, 1px ramme `#0062BA` eller nøytral grå, border radius 4px).
     - Placeholder-tekst.
4. **Handlingsknapper**:
   - Primærknapp (Send inn) i standard Altinn/Digdir-blå (#0062BA) med hvit tekst.

### Fase 3: Toveis samspill (Figma ➔ Altinn Schema)
1. Pluginen annoterer hver genererte node med Figma `setPluginData('altinnBinding', 'teamName')` eller tilsvarende metadata.
2. Når teamet har redigert tekster eller flyttet felter i Figma, kan en "Eksportér til Altinn"-funksjon lese tilbake nodene og spytte ut en valid `App/ui/layouts/Form.json`.

---

## 4. Verifikasjonskriterier for Prototypen
- [ ] Figma-framen bruker Auto Layout så tekster og felter flyter naturlig ved redigering.
- [ ] Inneholder alle obligatoriske SSB-elementer: Tittel, kontekst/hjemmel, entydig ledetekst og hjelpetekst.
- [ ] Noder er navngitt eller tagget slik at videre konvertering til Altinn 3 layout er deterministisk.
