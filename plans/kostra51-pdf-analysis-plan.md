# Plan: Trinnvis analyse og konvertering av «Skjema 51.pdf» (KOSTRA 51Plan 2026) til Dialogue DSL

## 1. Oversikt over PDF-dokumentet

Dokumentet **`Skjema 51.pdf`** består av 6 sider og representerer **KOSTRA 51Plan 2026: Planbehandling, miljø- og kulturminneforvaltning**:

- **Side 1**:
  - Tittel & introduksjon (forklaring av fargekoder: mørk grå = beregnet/forhåndsutfylt, lys grå = betinget utfylling).
  - **Bolk A**: Opplysninger om fylket og skjemaansvarlig (`Fylkesnr`, `Navnet på fylket`, `Navn - skjemaansvarlig`, `Tlf nr`, `E-post - skjemaansvarlig`).
  - **DEL I**: Planarbeid og saksbehandling for kulturminner i fylkeskommunen (B1–F).
  - **Bolk B1**: Tid brukt til arbeid med kulturminner i fylkeskommunen (1. Totalt årsverk [beregnet sum], 1a–1d delposter, 2a midlertidige årsverk). *(Dette var utsnittet i `screenshots/bilde.png` som vi allerede konverterte!)*
  - **Bolk C11**: Temaplaner for kulturminner (1a: Ja/Nei, 1b: Årstall hvis ja).
  - **Bolk C12 (start)**: Innsigelser til kommunale planer begrunnet med kulturminnehensyn (Matrise: 3 kolonner x plantyper).
- **Side 2**:
  - **Bolk C12 (fortsettelse)**: Områderegulering og detaljregulering.
  - **Bolk D1**: Behandling av tiltak/søknader (3 underseksjoner med fler-kolonne matriser).
  - **Bolk E**: Politianmeldelser etter kulturminneloven.
  - **Bolk F (start)**: Automatisk fredete kulturminner (F1: 2 kolonner x 4 rader, F2: 6 kolonner).
- **Side 3**:
  - **Bolk F (fortsettelse)**: F2a delspørsmål, F3 Skjøtsel/tilrettelegging, F4 Kostnader/kostnadsdekning (kroner).
  - **DEL II**: Planarbeid og saksbehandling i fylkeskommunen (B2–D2).
  - **Bolk B2**: Tid til saksbehandling til planbehandling og folkehelse (3, 3a, 3b, 4: årsverk).
  - **Bolk C21**: Egen planlegging (1a årstall, 1b antall planer, 1b1, 1b2).
- **Side 4**:
  - **Bolk C22**: Temaplaner etter pbl (2b–2o: 14 temaer med to-delt spørsmål: Ja/Nei + Hvis ja hvilket år).
  - **Bolk C23**: Behandling av kommunale planer (Matrise: 3 rader x 3 kolonner).
- **Side 5**:
  - **Bolk D2**: Dispensasjonsbehandling (Matriser: pbl § 1-8 strandsonen/vassdrag, og § 19 dispensasjonstyper).
  - **DEL III**: Kommentarer og merknader. Utfylling av skjema.
  - **Bolk G**: Fritekstmerknader til skjemaet.
  - **Bolk H (start)**: Tidsbruk og kilde (H1 elektronisk sakssystem Ja/Nei, H1a maskinelle opptellinger Ja/Nei, H2 timer totalt).
- **Side 6**:
  - **Bolk H (slutt)**: H2a timer framskaffe info, H2b timer fylle ut skjemaet.

---

## 2. Gaps og begrensninger i gjeldende Dialogue DSL

Under analysen av sidene 1–6 er det avdekket fire vesentlige kapabilitets-gaps i vårt nåværende flate Dialogue DSL (`Question` / `QuestionType`):

1. **Tabeller og todimensjonale matriser (Grid/Matrix Controls):**
   - *Forekomst:* Bolk C12, D1, F1, F2, C23, D2.
   - *Problem:* Tabellene har rader (f.eks. `Kommuneplaner`, `Områderegulering`, `Detaljregulering`) og faste kolonner (f.eks. `Behandlede saker i alt`, `Herav innsigelser`, `Herav til mekling`).
   - *Nåværende løsning:* Må "flates ut" til individuelle spørsmål (f.eks. `kommuneplaner_behandlet`, `kommuneplaner_innsigelse`, etc.).
   - *Anbefalt DSL-utvidelse:* Innføre `MatrixQuestion` eller `TableQuestion` med `rowLabels` og `columnDefinitions`.
2. **Koblede to-trinns spørsmål (Compound inline questions: Ja/Nei + Hvis ja Årstall):**
   - *Forekomst:* Bolk C11 (1a) og C22 (2b–2o: 14 temaplaner).
   - *Problem:* I KOSTRA er dette én kompakt rad: Kolonne `a` er Ja/Nei radioknapp; kolonne `b` er et 4-sifret årstall som åpnes hvis kolonne `a` er "Ja".
   - *Nåværende løsning:* To separate `Question` med `condition = Just (Equals "planX_harPlan" "true")`.
3. **Beregninger og summeringsfelter (Calculated Fields / Totals):**
   - *Forekomst:* B1.1 (totalt årsverk = sum av 1a–1d), H2 (timer totalt = sum av H2a + H2b).
   - *Nåværende løsning:* `annotations.readOnly = true` og `annotations.calculatedSumOf`.
4. **Forhåndsutfylte / låste fylkesopplysninger (Prefill / ReadOnly):**
   - *Forekomst:* Bolk A (`Fylkesnr`, `Navnet på fylket`).
   - *Nåværende løsning:* `annotations.readOnly = true` eller kobling til Altinn prefill-datakilder.

---

## 3. Plan for trinnvis behandling

### Trinn 1: Konvertering av Side 1 til Dialogue DSL
- **Mål:** Modellere Side 1 som en komplett, typesikker Dialogue-spesifikasjon.
- **Innhold på Side 1:**
  - **Bolk A (Opplysninger om fylket og skjemaansvarlig):**
    - `fylkesnr`: Tekst / 2-sifret kode (`readOnly: true` / forhåndsutfylt).
    - `fylkesnavn`: Tekst (`readOnly: true` / forhåndsutfylt).
    - `skjemaansvarligNavn`: Tekst (`required: true`).
    - `skjemaansvarligTlf`: Tekst / 8 siffer (`required: true`).
    - `skjemaansvarligEpost`: Tekst / e-post (`required: true`).
  - **Bolk B1 (Tid brukt til arbeid med kulturminner):**
    - `b1_aarsverkKulturminnerAlt`: Desimal, beregnet sum (`readOnly: true`).
    - `b1_aarsverkArkeologi`: Desimal (`required: true`).
    - `b1_aarsverkNyereTid`: Desimal (`required: true`).
    - `b1_aarsverkArealplan`: Desimal (`required: true`).
    - `b1_aarsverkAnnet`: Desimal (`required: true`).
    - `b1_aarsverkMidlertidige`: Desimal (`required: true`).
  - **Bolk C11 (Temaplaner for kulturminner):**
    - `c11_kulturminnerHarPlan`: Boolean (`required: true`).
    - `c11_kulturminnerPlanAar`: Integer / 4 siffer (`required: true`, `condition: IsTrue "c11_kulturminnerHarPlan"`).
  - **Bolk C12 (Innsigelser til kommuneplaner):**
    - `c12_kommuneplanerBehandlet`: Integer.
    - `c12_kommuneplanerInnsigelse`: Integer.
    - `c12_kommuneplanerMekling`: Integer.

### Trinn 2: Implementasjon & Validering av Side 1
- Legg til `kostra51Side1Dialogue` i `dsl/src/SchemaDSL/Examples.hs`.
- Generer `dsl/schemas/kostra51-side1.json` og `dsl/schemas/kostra51-side1-report.md`.
- Kjør `cabal test` for å verifisere gyldig AST og kompilering.

### Senere trinn (Side 2–6):
- Trinn 3: Side 2 (C12 forts., D1 tiltak, E politi, F1 fredete kulturminner).
- Trinn 4: Side 3 (F2a/F3/F4, B2 saksbehandling, C21 egen planlegging).
- Trinn 5: Side 4 (C22 14 temaplaner, C23 matrise).
- Trinn 6: Side 5–6 (D2 dispensasjoner, G merknader, H tidsbruk).
- Trinn 7: Samlet master-skjema eller fler-siders layout i Altinn.
