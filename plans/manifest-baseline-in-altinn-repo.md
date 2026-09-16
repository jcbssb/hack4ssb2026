# Plan: Manifestere Baseline Skjema i Altinn Skjema Repoet (`altinn-skjema-hacking`)

**Mål**: Injisere en ny side i det klonede Altinn-skjemaet (`altinn-skjema-hacking`) som manifesterer vårt "Hello World" baseline-skjema (`hack4ssb-hello` med `teamName` og `trackChoice`) og gjøre den testbar i Altinn Studio-portalen / TT02.

---

## 1. Undersøkelse av Eksisterende Altinn-arkitektur

Det klonede repoet (`altinn-skjema-hacking`) er en standard Altinn 3 app med frontend v4:
- **Layout-sett**: `App/ui/layout-sets.json` definerer layout-settet `mainlayout`.
- **Sidenavigasjon**: `App/ui/mainlayout/Settings.json` styrer sidenes rekkefølge under `pages.groups[0].order`.
  - Nåværende sider: `["S01_Forside", "S20_Summary", "S70_Tidsbruk", "S80_Brukeropplevelse", "S90_Kommentarogkontakt"]`.
- **Layout-filer**: Ligger i `App/ui/mainlayout/layouts/*.json`.
- **Tekstressurser**: `App/config/texts/resource.nb.json` (og `.nn.json`, `.en.json`).
- **Datamodell**: `A3_RA-1000_M` (C# klasse `App/models/A3_RA-1000_M.cs` og schema `App/models/A3_RA-1000_M.schema.json`).
  - Modell inneholder generiske hjelpefelter: `Hjelpefelter.hjelpefelt1`, `Hjelpefelter.hjelpefelt2`, etc., eller felter under `Kontakt`.

---

## 2. Manifestasjonsstrategi: Ny Side `S05_Hack4SSB.json`

For å beholde eksisterende flyt intakt samtidig som vi tester baseline-dialogen, legger vi til siden `S05_Hack4SSB` rett etter forsiden:

```
[S01_Forside] ──► [S05_Hack4SSB (Vår Baseline!)] ──► [S20_Summary] ──► ...
```

### 2.1 Steg 1: Opprette Layout-filen `S05_Hack4SSB.json`
Opprettes i `App/ui/mainlayout/layouts/S05_Hack4SSB.json` basert på vår SSOT `baseline-schema.json`:
- **Header L**: "SSB Hackday 2026 - Registrering" (`lang.hack4ssb.tittel`).
- **Panel / Ingress**: Info om teamregistrering og oppgavegiver.
- **Input-komponent (`teamName`)**:
  - `id`: `hack4ssb-teamName-input`
  - `type`: `Input`
  - `required`: `true`
  - `dataModelBindings`: `{ "simpleBinding": "Hjelpefelter.hjelpefelt1" }` (sikrer at svaret lagres i datamodellen uten å måtte kompilere om C#-modellen på nytt!).
  - `textResourceBindings`: `{ "title": "lang.hack4ssb.teamName.label", "help": "lang.hack4ssb.teamName.help" }`
- **RadioButtons-komponent (`trackChoice`)**:
  - `id`: `hack4ssb-trackChoice-radio`
  - `type`: `RadioButtons`
  - `dataModelBindings`: `{ "simpleBinding": "Hjelpefelter.hjelpefelt2" }`
  - `textResourceBindings`: `{ "title": "lang.hack4ssb.trackChoice.label", "help": "lang.hack4ssb.trackChoice.help" }`
  - `options`: 4 svaralternativer definert inline eller via options-id.

### 2.2 Steg 2: Oppdatere `Settings.json`
I `App/ui/mainlayout/Settings.json`:
- Legge til `"S05_Hack4SSB"` i `pages.groups[0].order`:
  ```json
  "order": [
    "S01_Forside",
    "S05_Hack4SSB",
    "S20_Summary",
    "S70_Tidsbruk",
    "S80_Brukeropplevelse",
    "S90_Kommentarogkontakt"
  ]
  ```

### 2.3 Steg 3: Injiser Tekstressurser
I `App/config/texts/resource.nb.json`:
- `S05_Hack4SSB`: "Hackday Team"
- `lang.hack4ssb.tittel`: "SSB Hackday 2026 - Registrering"
- `lang.hack4ssb.teamName.label`: "Hva er navnet på ditt Hackday Team?"
- `lang.hack4ssb.teamName.help`: "Oppgi et unikt lagnavn, f.eks. 'Foran Skjema'."
- `lang.hack4ssb.trackChoice.label`: "Hvilket hovedspor jobber teamet med?"
- `lang.hack4ssb.trackChoice.help`: "Velg det primære fokusområdet for hack-prosjektet."

Tilsvarende nynorsk og engelsk defaults i `.nn.json` og `.en.json`.

---

## 3. Verifikasjon i Altinn Studio Portal

1. **Lokal syntakssjekk**:
   - Validere at `S05_Hack4SSB.json` og `Settings.json` er gyldig JSON og samsvarer med Altinn frontend v4 layout schema.
2. **Git Commit & Push til Altinn Studio**:
   - Committe endringene i `altinn-skjema-hacking`.
   - Pushe til `https://altinn.studio/repos/ssb/hack4ssb-foran-skjema`.
3. **Visning og Test i Altinn Studio Designer / TT02**:
   - Åpne appen i Altinn Studio UI.
   - Verifisere at den nye siden "S05_Hack4SSB" vises i sidestolpen og i skjemabyggeren.
   - Forhåndsvise skjemaet i Altinn Studio Preview eller deploye til TT02.
