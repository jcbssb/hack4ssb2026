# Fire Arbeidsflyter for Skjemautvikling i SSB

**Til:** Jon, Joakim og teamet  
**Fra:** Foran Skjema (SSB Hackday 2026)  
**Formål:** Oppsummering og sammenligning av fire utforskede spor for å produsere Altinn 3-skjemaer fra metodikk, prototyper og kode.

---

## Sammenligningsmatrise: De 4 Arbeidsflytene

| Egenskap | 1. Opprinnelig konsept (Figma ➔ Altinn) | 2. Jon-arbeidsflyten (Screenshots/MCP ➔ Figma ➔ Koder) | 3. Joakim-arbeidsflyten (Figma ➔ AI Copilot CLI ➔ Altinn Repo) | 4. Foran Skjema (Dialogue DSL SSOT) |
| :--- | :--- | :--- | :--- | :--- |
| **Utgangspunkt** | Datamodeller (JSON Schema / XSD) | Skjermbilder/PDF + Metodikk-krav | Ferdig designet Figma-frame/fil | Typet Haskell AST (Single Source of Truth) |
| **Arena for iterasjon** | Figma | Figma | Figma (visuelt) + Git diff / PR | Toveis: Skjemasimulator (web) + Figma |
| **Rolle AI** | Figma Plugin / script-generator | Multimodal agent via Figma MCP (`create_frame`) | AI Coding Agent (Copilot CLI + `figma-altinn` extension) | OCR/ekstraksjon til AST + syntesegenerering |
| **Veien til Altinn 3** | Figma REST API / parser genererer layout | Skjemakoder overtar og koder i repo for hånd | Figma JSON-eksport ➔ AI leser JSON og oppdaterer repo | 100% automatisk kompilering (`schema-dsl-cli`) |
| **Styrke** | Ren UI-visualisering tidlig | Naturlig for metodologer og fageksperter | Fjerner manuell koding via Figma JSON ➔ AI ➔ Repo | Full type-sikkerhet, validering og umiddelbar testbarhet |

---

## 1. Opprinnelig Konseptuell Flyt (Figma ➔ Altinn)
*Beskrevet i `README.md` og `docs/arbeidsflyt-skjema.md`.*
- **Steg 1 (Input):** Enkel datamodell eller kravliste konverteres til Figma-rammer.
- **Steg 2 (Figma):** Designere bygger skjermbilder med Felles Designsystem-komponenter.
- **Steg 3 (Faglig iterasjon):** Manuell gjennomgang av ledetekster og rekkefølge i Figma.
- **Steg 4 (Eksport):** Parser oversetter Figma-komponenttreet direkte til Altinn `layout.json`.

---

## 2. Jon-arbeidsflyten (Screenshots & Metodikk ➔ MCP ➔ Figma ➔ Skjemakoder)
*Beskrevet i `docs/jon-workflow-figma-mcp-altinn.md`.*
- **Fase 1 (Metodikk & AI via MCP til Figma):**
  - **Inndata:** Skjermbilder / PDF-skanninger av eksisterende skjemaer (f.eks. KOSTRA 51 eller Byggesak) kombinert med SSB-metodikkregler (bolk-inndeling, tydelige hjelpetekster, enheter).
  - **AI-agent via MCP:** En multimodal agent analyserer skjermbildene og bruker Figmas MCP-verktøy (`create_frame`, `insert_component`) til å generere en ferdig Figma-prototype med Auto Layout.
  - **Faglig iterasjon:** Metodologer og fageksperter justerer, tester og godkjenner i Figma.
- **Fase 2 (Skjemakoder tar over til Altinn repo):**
  - Skjemakoderen bruker godkjent Figma som referanse.
  - Koder opp Altinn 3 JSON layout (`Header`, `Panel`, `Input`, `Group`), kobler mot C#/.schema.json datamodeller og etablerer tekstressurser etter Joakims retningslinjer.

---

## 3. Joakim-arbeidsflyten (Figma ➔ JSON Eksport ➔ AI Copilot ➔ Altinn Repo)
*Beskrevet i `docs/altinn-figma-to-app-joakim/SKILL.md`.*
- **Steg 1 (Figma Design):** Utgangspunktet er en ferdig godkjent Figma-frame bygget med Altinn Studio / Felles Designsystem-komponenter og Auto Layout.
- **Steg 2 (JSON Eksport fra Figma):**
  - Figma-skjemaprototypen eksporteres som et strukturert JSON-komponenttre (f.eks. via Figma REST API, plugin eller `figma-altinn` CLI med `simplified: true`).
  - Dette gir en maskinlesbar representasjon av feltnavn, typer (`Input`, `Header`, `RadioButtons`, `Dropdown`, `Panel`) og layoutstruktur.
- **Steg 3 (AI Tolkning & Regelmotor):**
  - AI-agenten leser den eksporterte Figma JSON-filen.
  - Mapper mot Joakims retningslinjer (`SKILL.md`): identifiserer innholdssider, ignorerer SSB standard boilerplate (`S01_Forside`, `S20_Summary`, `S70_Tidsbruk`).
- **Steg 4 (AI Oppdaterer Altinn Repo-koden):**
  - AI-en genererer og oppdaterer koden direkte i Altinn-repoet:
    - Skriver Altinn layouts: `App/ui/mainlayout/layouts/S05_*.json`.
    - Oppdaterer sidetilordning i `App/ui/mainlayout/Settings.json`.
    - Genererer flerspråklige tekstressurser i `App/config/texts/resource.{nb,nn,en}.json`.
    - Synkroniserer datamodell i tre filer samtidig: C# (`.cs`), JSON Schema (`.schema.json`) og XSD.
- **Resultat:** AI bygger broen mellom det eksporterte Figma JSON-designet og produksjonskoden i Altinn-repositoriet uten manuell koding.

---

## 4. Foran Skjema-arbeidsflyten (Dialogue DSL som Single Source of Truth)
*Utviklet under hackdayen i `dsl/` og `simulator/`.*
- **Haskell Dialogue AST:** Skjemaets struktur, bolker, spørsmålstyper, måleenheter og betinget visningslogikk defineres som en type-sikker datamodell.
- **Deterministisk kompilering:** `schema-dsl-cli` genererer automatisk:
  - Altinn 3 layouts (`S05_*.json`), options-lister og tekstressurser.
  - C# modeller og JSON Schema (`A3_RA-1000_M.cs`).
  - Interaktive nettleser-simulatorer og AST-grafer.
- **Evolusjon i rater:** Muliggjør suksessive prøvekjøringer (Trial 1 ➔ 2 ➔ 3) med automatisk rangering i Altinn Studio.

---

## Visuell demonstrasjon i nettleser
Åpne `simulator/workflow-triptych.html` i nettleseren for å klikke mellom og inspisere alle fire arbeidsflytene individuelt.
