# SSB og Altinn Skjemastandarder: Retningslinjer for Datamodeller og Design

**Status**: Verified  
**Oppdatert**: 2026-09-16  
**Relevante kilder**:
- Altinn Designsystem / Felles Designsystem (Digdir): `https://designsystemet.no/`
- Altinn 3 App Layout Schema: `https://altinncdn.no/schemas/json/layout/layout.schema.v1.json`
- SSB Datafangst / SUV (SpørreUndersøkelser Virksomhet): RA-skjemaer (f.eks. RA-0666, RA-0782)

---

## TL;DR
SSB-skjemaer i Altinn 3 bygger på Digdirs **Felles Designsystem** (tidligere Altinn designsystem), standardiserte komponenttyper (`Input`, `Checkboxes`, `RadioButtons`, `Dropdown`, `RepeatingGroup`) og strenge krav til universell utforming (UU), klarspråk og sporbarhet (RA-koder, dataModelBindings, org/enhet metadata). En ren JSON-schema definisjon alene mangler visuelle/tekstlige instruksjoner (UU-hjelpetekster, feilmeldinger, feltrekkefølge, kolonneinndeling), og må derfor berikes med metadata for å tilfredsstille SSB- og Altinn-standardene.

---

## High-Density Specs & Retningslinjer

### 1. SSB Skjemastruktur og Konvensjoner (SUV / Datafangst)
- **Skjemaidentifikatorer**: Bruker standard RA-kodifisering (f.eks. `RA-0666`, `RA-0782`).
- **Standard Header & Kontekst**:
  - Hvert skjema skal tydelig angi oppgavegiver/enhet (Org.nr, navn på bedrift/virksomhet, kontaktperson).
  - Tittel og formål: Kortfattet forklaring på hvorfor dataene samles inn og hjemmel (f.eks. Statistikkloven).
- **Språk og Nynorsk/Bokmål/Engelsk**:
  - Tekster skilles ut i ressursfiler (`resource.nb.json`, `resource.nn.json`, `resource.en.json`).
  - Ledetekster skal følge statens prinsipper for klarspråk (direkte spørsmål fremfor byråkratiske termer).

### 2. Altinn 3 & Felles Designsystem (Digdir) Standarder
- **Typografi & Visuelt hierarki**:
  - Tittel (Header L/H1), Seksjonstitler (Header M/H2), Feltgrupper (Header S/H3).
  - Skjemaflater skal ha konsistent spacing (4px/8px basert grid).
- **Komponentregler for skjemafelter**:
  - **Korte tekst/tallsvar**: `Input` (spesifiser format/type: `text`, `number`, med prefiks/suffiks som "kr", "%" eller "stk").
  - **Få valg (2-4)**: `RadioButtons` (enkeltvalg) eller `Checkboxes` (flervalg) – ikke dropdown.
  - **Mange valg (>5)**: `Dropdown` eller søkbar `Combobox`.
  - **Datoer**: `Datepicker` med format `DD.MM.YYYY`.
  - **Dynamiske lister / Tabeller**: `RepeatingGroup`.
- **Universell Utforming (WCAG 2.1 / UU-krav)**:
  - Alle felter *må* ha en unik `title` (ledetekst).
  - Hjelpetekst skal struktureres i `help` eller `description` (tooltip eller synlig tekst under feltet).
  - Validering og feilmeldinger skal være informative og peke direkte på hvordan feilen rettes.

### 3. Gap-analyse: Ren JSON Schema vs. Altinn/SSB Skjemastandard

| Informasjonsbehov | Finnes i ren JSON Schema? | Tilleggsmetadata / Konfigurasjon som kreves |
| :--- | :--- | :--- |
| **Felttype / Datatype** | Ja (`string`, `number`, `boolean`, `enum`) | Mappes direkte til komponenttype (`Input`, `Radio`, etc.) |
| **Obligatorisk / Påkrevd** | Ja (`required: ["teamName"]`) | Settes til `"required": true` i layout |
| **Ledetekst (Title)** | Delvis (`title` eller nøkkelnavn) | Trenger klarspråklig formulering på bokmål/nynorsk |
| **Visuell Layout & Rekkefølge** | Nei (objektnøkler er uordnede) | Sidesortering, grid/kolonne-bredde (`grid: { xs: 12, sm: 6 }`) |
| **Hjelpetekst / Rettledning** | Nei (ev. `description`) | Veiledningstekst for oppgavegiver (f.eks. "Hva regnes med?") |
| **Prefiks/Suffiks (valuta, enhet)**| Nei | Angivelse av måleenhet (kr, timer, ansatte) |
| **Datamodell-binding** | Implisitt (feltsti) | Eksplisitt `dataModelBindings.simpleBinding` |

---

## Actionable Next Steps
1. Ved automatisk generering fra JSON Schema må det støttes enten en **skjema-dekorator / form metadata** (annotasjoner i schema eller en separat `ui-schema.json`), eller en **AI-drevet berikelse** som tilfører klarspråk, SSB-kontekst og UU-felter.
2. Etablere et lite komponentbibliotek eller faste Figma-stiler som matcher Felles Designsystem for Altinn 3.
