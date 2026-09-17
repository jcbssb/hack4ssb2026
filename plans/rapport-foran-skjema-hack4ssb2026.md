# Rapport: Foran Skjema – Kode-først Dialogue Schema DSL for Altinn 3
**SSB Hackday 2026 | Team «Foran Skjema»**  
*Dato: 17. september 2026*

---

## 1. Bakgrunn og Hensikt (Executive Summary)

I dag krever utvikling og forvaltning av Altinn 3-skjemaer manuell koordinering av en rekke frakoblede filer: JSON layout-definisjoner, separate tekstressurser per språk, options-lister, JSON-skjemamodeller og C#-backend-klasser. Denne manuelle prosessen fører lett til feiljusteringer, unødvendig tidsbruk og høy terskel for å modernisere eldre undersøkelser (f.eks. KOSTRA).

**Team «Foran Skjema»** har etablert en **kode-først Dialogue Schema DSL** (Domain-Specific Language) som fungerer som en *Single Source of Truth (SSOT)* for spørreundersøkelser. Én konsis, semantisk definisjon kompilerer automatisk ut alle nødvendige Altinn 3-artefakter, datamodeller og interaktive nett-simulatorer.

---

## 2. Gjennomført Arbeid og Teknisk Evolusjon

Gjennom hackday-økten har vi tatt løsningen fra idé til en fullskala produksjonsdemonstrasjon i Altinn Studio:

1. **Arkitektur & Typesikker Dialogue DSL (Haskell):**
   - Etablerte typesikre datamodeller for skjemadialoger, spørsmålstyper (tekst, tall, desimaler, datoer, ja/nei, enkeltvalg, flervalg), betingelser (`Predicate`), validering og metadata.
   - Genererte JSON Schema metaspesifikasjoner og full toveis (round-trip) serialisering.

2. **Altinn 3 Kompilator & Fragment-Injektor:**
   - Bygget kompilator som automatisk genererer Altinn 3 v4-kompatible layouts, `options/*.json`, språknøkler for bokmål, nynorsk og engelsk, samt C#- og JSON-datamodeller.
   - Implementerte automatisk injeksjon i eksisterende Altinn-repoer med typesikre bindinger (`SkjemaData.<schemaId>.<fieldId>`).

3. **Interaktiv Simulator & Visuell AST-graf:**
   - Utviklet browserbaserte flater for umiddelbar forhåndsvisning av skjemaene og visuell grafrepresentasjon av dialogstrukturen uten å måtte deploye appen først.

4. **Omvendt Utvikling (Reverse Engineering) av KOSTRA 51:**
   - Matet inn faktiske skjermbilder og PDF-sider fra SSB-undersøkelsen *KOSTRA 51 (Planbehandling, miljø- og kulturminneforvaltning)*.
   - Gjenskapte alle 6 sider med over 60 spørsmål, beregnede delsummer, veiledningstekster og betinget logikk i DSL-en.

5. **Strukturering i «Bolker» og UI-optimalisering:**
   - Utvidet DSL-en med semantisk støtte for **Bolk** (tematiske grupper med overskrift og veiledningstekst).
   - Justerte kompilatoren slik at spørsmålsveiledning legges som Altinn `description` mellom tittel og inputfelt, og elideres automatisk når veiledning mangler for å eliminere unødvendig vertikal luft.

6. **Kronologisk Evolusjonsvisning for Altinn Studio:**
   - Strukturerte siderekkefølgen i Altinn Studio slik at man kan bla gjennom prosjektets evolusjon direkte i forhåndsvisningen:
     * **v1: Hello World** (`S05_hack4ssb_hello`) – Minimal baseline-prototype.
     * **v2: Syntetisk Komplett Skjema** (`S05_hack4ssb_comprehensive`) – Full dekning av alle spørsmålstyper og forgreningsregler.
     * **v3: OCR-prototype** (`S05_kostra51_kulturminner`) – Første tolkning av KOSTRA Bolk B1.
     * **v4: KOSTRA 51 Side 1–6** (`S05_kostra51_side1` til `side6`) – Komplett 6-siders undersøkelse med bolker og datamodell.

---

## 3. Gevinster for SSB og Fremtidig Skjemaproduksjon

* **Én sannhet (Single Source of Truth):**
  Slutt på at feltnavn, hjelpetekster eller datatyper spriker mellom layout, datamodell og backend. Endringer gjøres ett sted og forplanter seg overalt.
* **Radikalt raskere modernisering:**
  Gamle papir- og PDF-skjemaer kan oversettes og verifiseres i Altinn 3 på minutter i stedet for uker.
* **Plattformuavhengighet:**
  DSL-representasjonen er ren forretnings- og dialoglogikk. Den kan oversettes til Altinn 3 i dag, og til fremtidige skjemamotorer eller Figma-prototyper i morgen uten å endre definisjonene.
* **Innebygget kvalitetssikring:**
  Skjema-DSL-en fanger opp feilaktige datatyper, sirkulære avhengigheter og ugyldige tilstander ved kompileringstid (*compile-time validation*), før skjemaet noen gang når testmiljøet.

---
*Team «Foran Skjema» – SSB Hackday 2026*
