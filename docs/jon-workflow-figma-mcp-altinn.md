# Arbeidsflyt for Skjema: Jon-metodikken (Screenshots ➔ AI via MCP ➔ Figma ➔ Altinn 3)

**Team:** Foran Skjema (SSB Hackday 2026)  
**Målgruppe:** Metodologer, fageksperter, UX-designere og skjemautviklere  
**Status:** Dokumentert praksis & metodebeskrivelse  

---

## 1. Oversikt og Formål

"Jon-metodikken" etablerer en rask, visuelt drevet bro fra eksisterende undersøkelsesmetodikk, papirskjemaer og skjermbilder over til testbare Altinn 3-skjemaer. 

Metodikken deler ansvaret i to distinkte, sammenkoblede faser:
1. **Fase 1 (Metodikk & AI-agent via MCP):** Fra skjemakrav, metodiske retningslinjer og skjermbilder til en levende, redigerbar **Figma-prototype**.
2. **Fase 2 (Skjemakoder & Altinn Studio/Repo):** Fra godkjent Figma-prototype til implementasjon, C#/JSON-datamodellering, valideringsregler og Altinn 3 layout-komponenter i kode-repositoriet.

```
┌────────────────────────────────────────────────────────────────────────┐
│  FASE 1: Metodikk & AI (MCP ➔ Figma)                                   │
│                                                                        │
│  [Screenshots / Skisser] + [Metodikk-krav]                             │
│                           │                                            │
│                           ▼                                            │
│            [AI-Agent med Figma MCP-server]                             │
│                           │                                            │
│                           ▼                                            │
│               [Figma Skjemaprototype]                                  │
│                           │                                            │
│                           ▼                                            │
│       (Brukertesting, faglig justering i Figma)                        │
└───────────────────────────┬────────────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────────────────────┐
│  FASE 2: Skjemakoder & Altinn (Figma ➔ Repo)                           │
│                                                                        │
│              [Figma Inspect & Komponent-tre]                           │
│                           │                                            │
│                           ▼  (Følger Joakims Altinn-retningslinjer)    │
│            [Skjemakoder / Altinn Utvikler]                             │
│                           │                                            │
│                           ▼                                            │
│        [Altinn 3 App Repo: Layouts, Tekster, C# Datamodell]            │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Fase 1: Fra Skjermbilder og Metodikk til Figma med AI (MCP)

### 2.1 Forutsetninger og Inndata
- **Skjermbilder / PDF-er:** Skanninger eller screenshots av eksisterende skjemaer (f.eks. `screenshots/20Byggesak (utfylt).pdf`, KOSTRA 51 eller eldre Altinn 2-løsninger).
- **Metodiske krav:** Definerte prinsipper fra SSB seksjon for spørreundersøkelsesmetodikk:
  - Færrest mulig unødige spørsmål.
  - Tydelige ledetekster og hjelpetekster plassert over inputfelter.
  - Logisk oppdeling i temaområder (**Bolker**).
  - Korrekte måleenheter (kroner eksl. mva, antall årsverk med 1 desimal, timer).
- **Figma MCP Server:** En Model Context Protocol (MCP)-server koblet til Figma REST API eller Figmas lokale plugin-socket, som lar AI-agenten:
  - Lese designsystem-tokens og eksisterende komponenter i Figma.
  - Opprette nye frames, seksjoner, tekstbokser og komponentinstanser direkte i Figma-canvaset.

### 2.2 Prosesssteg for AI-agenten
1. **Multimodal analyse av skjermbilde / PDF:**
   - AI analyserer layoutstrukturen, hierarkiet (overskrifter, ledetekster, feltplassering) og datatyper.
   - Identifiserer repeterende feltmønstre (f.eks. vedtatt vs. rapporteringsår, mottatt vs. behandlet).
2. **Kall mot Figma via MCP:**
   - Agenten kaller Figma MCP-verktøy (f.eks. `create_frame`, `insert_component`, `set_auto_layout`).
   - Sider opprettes med **Auto Layout** (vertikal flyt, 24px/32px spacing).
   - Standardkomponenter fra Felles Designsystem / Altinn tas i bruk (`Input`, `Textarea`, `RadioGroup`, `Checkboxes`, `Alert`).
3. **Visuell tilgjengeliggjøring for fageksperter:**
   - Prototypen er umiddelbart tilgjengelig i Figma. Fageksperter og metodologer kan kommentere, justere ordlyd og omgruppere felter direkte.

---

## 3. Fase 2: Skjemakoder tar Figma-designet videre til Altinn 3

Når designet er forankret og godkjent i Figma, overtar skjemautvikleren for å realisere skjemaet som en robust Altinn 3-applikasjon i kode-repositoriet (`altinn-skjema-hacking`).

Arbeidet utføres etter beste praksis dokumentert i `docs/altinn-figma-to-app-joakim/`:

### 3.1 Steg for Skjemautvikleren

#### Steg A: Sidetype-identifisering & Rekkefølge
- Skjemakoderen skiller innholdssider fra boilerplate/oppsummeringssider:
  - **Innholdssider:** F.eks. `S05_Byggesak_DelA`, `S05_Byggesak_DelB`.
  - **Oppsummering & Avslutning:** `S20_Summary`, `S70_Tidsbruk`, `S90_Kommentarogkontakt`.
- Registreres i `App/ui/mainlayout/Settings.json` under `pages.groups[0].order`.

#### Steg B: Komponentmapping og Layout (`App/ui/mainlayout/layouts/*.json`)
Skjemakoderen oversetter Figma Auto Layout-elementer til Altinn 3 JSON-komponenter:

| Figma-element | Altinn 3 Komponent | Konfigurasjon |
| :--- | :--- | :--- |
| Tittel / Ramme-overskrift | `Header` | `"size": "h2"` eller `"h3"` |
| Hjelpetekst / Veiledningsboks | `Panel` | `"variant": "info"`, `"showIcon": true` |
| Tekstfelt / Tallfelt | `Input` | Koblet mot datamodell, `"formatting"` for tall |
| Radioknapper (envalg) | `RadioButtons` | Refererer `"optionsId"` |
| Avkrysningsbokser (flervalg) | `Checkboxes` | Refererer `"optionsId"` |
| Langt tekstfelt / Merknader | `TextArea` | `"maxLength": 999` |
| Seksjonsinndeling | `Group` / `Panel` | Gruppe med underkomponenter |

- **Rutenettoppstilling (Grid):** Elementer som ligger side-om-side i Figma (f.eks. vedtatt vs. rapporteringsår) settes opp med `"grid": { "xs": 6 }` i Altinn-layouten.

#### Steg C: Datamodellsynkronisering (C# & XSD/JSON Schema)
- Felter navngis etter konvensjonen: `[Side/Bolk]_[Feltnavn]`.
- Skjemakoderen oppdaterer datamodellene:
  - `App/models/A3_RA-1000_M.schema.json` (JSON Schema)
  - `App/models/A3_RA-1000_M.cs` (C# klasser med deserialisering og typer)
- Alle komponenter bindes med `"dataModelBindings": { "simpleBinding": "SkjemaData.feltnavn" }`.

#### Steg D: Tekstressurser og Flerspråklighet (`App/config/texts/`)
- Ingen hardkodede tekster i layout-filene.
- Alle ledetekster, hjelpetekster og feilmeldinger plasseres i ressursfilene:
  - `resource.nb.json` (Bokmål)
  - `resource.nn.json` (Nynorsk)
  - `resource.en.json` (Engelsk)
- Nøkkelstruktur: `lang.[skjemanavn].[feltid].label` og `.help`.

#### Steg E: Forretningslogikk, Beregninger og Validering
- Beregnede felter (f.eks. totalsummer som $b + c + d$) markeres som `"readOnly": true` i layouten, og logikken implementeres i Altinn C# backend eller via kalkuleringsformler.
- Betinget visning oversettes til Altinn Expressions (`["equals", ["argv", 0], true]`).

---

## 4. Gevinster med Jon-metodikken

1. **Halvering av tid fra idé til testbart skjema:** Metodologer og designere slipper å vente på at utviklere koder opp tidlige utkast for hånd.
2. **Designsystem-troskap:** AI-agenten bruker eksisterende Figma designkomponenter direkte, noe som sikrer konsistent universell utforming og gjenkjennelighet for respondentene.
3. **Smidig overlevering:** Skjemakoderen mottar et ryddig, strukturert Figma-komponenttre med klare navneregler som mapper 1:1 mot Altinns arkitektur.
4. **Iterativ trygghet:** Metodiske endringer kan testes og iteres i Figma før koden ferdigstilles i Git og Altinn Studio.
