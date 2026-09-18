# hack4ssb2026 - Foran Skjema

Repository for SSB Hackday 2026.

## Team
**Foran Skjema**

## Formål / Purpose
Utforske og eksperimentere med:
- **AI** (assistert skjemabygging, validering, analyse og utfylling)
- **Figma-prototyping** av skjemaer og brukeropplevelse
- **Altinn-skjemaer** (Altinn 3 integrasjoner, modeller og dataflyt)

## Skjema-arbeidsflyt / Schema Workflow
Vi utforsker en to-stegs, iterativ arbeidsflyt for rask skjemautvikling:
```
[Enkle beskrivelser / Datamodeller]
             │
             ▼  (AI + Figma Plugin / Generator)
   [Figma Skjemaprototype]
             │  (Brukertesting, faglig iterasjon & UX-justeringer)
             ▼
   [Iterert Figma-design]
             │
             ▼  (Figma Export / REST / Parser)
  [Altinn 3 Skjemaer & Layout]
```

1. **Beskrivelse/Modell ➔ Figma-prototype**: Generere visuelle, enkle Figma-prototyper basert på datamodeller (JSON Schema / XSD) eller ustrukturerte/enkle beskrivelser.
2. **Iterasjon i Figma**: Fageksperter og designere justerer layout, ledetekster, rekkefølge og felter direkte i Figma.
3. **Figma-prototype ➔ Altinn 3**: Ekstrahere og oversette det ferdige Figma-designet til kjørbare Altinn 3-skjemadefinisjoner (`layout.json`, `layout-settings.json`, datamodell-bindinger).

Interaktiv visualisering av arbeidsflyten: Åpne `simulator/workflow-visualizer.html` i en nettleser.

## Prosjektstruktur
- `prototyper/` – Figma-eksport, wireframes og UX-notater
- `altinn/` – Altinn-relaterte skjemadefinisjoner og datamodeller
- `ai/` – Eksperimenter, prompts, scripts og verktøy
- `docs/` – Notater og presentasjonsmateriell
  - `docs/jon-workflow-figma-mcp-altinn.md` – Jon-metodikken: Fra metodikk/screenshots via AI (MCP) til Figma og videre til Altinn 3
  - `docs/arbeidsflyt-skjema.md` – Konseptuell arbeidsflyt fra modell til Altinn via Figma
  - `docs/altinn-figma-to-app-joakim/` – Detaljert referanse og veiledning for oversettelse av Figma-design til Altinn 3-applikasjoner (komponentkatalog, sidetype-identifisering, datamodellsynk, tekstressurser og options)
- `research/` – Bakgrunnsundersøkelser, designsystemstandarder og API-dokumentasjon
- `plans/` – Arkitektur- og implementasjonsplaner
