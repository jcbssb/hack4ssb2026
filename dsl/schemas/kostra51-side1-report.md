# KOSTRA Skjema 51 – Side 1 DSL Extraction Report

## 1. Kildemateriale
- **Kilde**: `screenshots/Skjema 51.pdf` (Side 1)
- **Tittel**: `KOSTRA Skjema 51 - Natur- og nærmiljøforvaltning, friluftsliv, kulturminner og fysisk planlegging 2026`
- **Generert DSL-fil**: `dsl/schemas/kostra51-side1.json`
- **Haskell-definisjon**: `kostra51Side1Dialogue` i `dsl/src/SchemaDSL/Examples.hs`

---

## 2. Struktur og innhold på Side 1

Side 1 i PDF-en dekker to hovedbolker:
1. **Bolk A: Naturforvaltning, nærmiljøforvaltning og friluftsliv**
   - **Bolk A1: Ressursbruk og organisering (årsverk og netto driftsutgifter)**:
     - 4 desimalspørsmål for årsverk:
       - `a1_aarsverk_forvaltning_drift`: Forvaltning og drift (desimal, 1 siffer)
       - `a1_aarsverk_tilrettelegging`: Tilrettelegging (desimal, 1 siffer)
       - `a1_aarsverk_annet`: Annet (desimal, 1 siffer)
       - `a1_aarsverk_sum`: Totalt antall årsverk (beregnet / `readOnly: true`, 1 siffer)
     - 2 heltallsspørsmål for driftsutgifter (i hele 1 000 kr):
       - `a1_netto_driftsutgifter_friluftsliv`: Netto driftsutgifter til natur-, nærmiljø- og friluftsformål
       - `a1_kjop_av_tjenester`: Hvorav kjøp av tjenester fra interkommunale friluftsråd
   - **Bolk A2: Tilrettelegging og tiltak for friluftsliv og natur**:
     - 4 heltallsspørsmål (telling av områder / tiltak):
       - `a2_statlig_sikra_omraader`: Antall statlig sikra friluftslivsområder
       - `a2_tilretteleggingstiltak_sikra`: Hvor mange av disse områdene har fått nye eller vesentlig oppgraderte tilretteleggingstiltak
       - `a2_andre_friluftslivsomraader`: Antall andre friluftslivsområder i kommunen
       - `a2_tilretteleggingstiltak_andre`: Hvor mange av disse andre områdene har fått nye tiltak
2. **Bolk B: Kulturminner og kulturmiljøer**
   - **Bolk B1: Ressursbruk og organisering (årsverk)**:
     - 4 desimalspørsmål for årsverk (tilsvarer bilde.png):
       - `b1_aarsverk_forvaltning`: Kulturminneforvaltning (desimal, 1 siffer)
       - `b1_aarsverk_drift`: Skjøtsel, vedlikehold og drift (desimal, 1 siffer)
       - `b1_aarsverk_annet`: Annet arbeid med kulturminner (desimal, 1 siffer)
       - `b1_aarsverk_sum`: Totalt antall årsverk (beregnet / `readOnly: true`, 1 siffer)

---

## 3. Identifiserte DSL-egenskaper og gap

1. **Aritmetisk beregning (`calculatedSumOf`)**:
   - `a1_aarsverk_sum` og `b1_aarsverk_sum` er summene av de tre foregående feltene.
   - For nå modelleres de med `"annotations": { "readOnly": "true", "decimalScale": "1" }`.
   - *Fremtidig DSL-utvidelse*: Formel- eller totalsumsannotasjon som kompilerer til Altinn 3 beregningsregler (`["sum", ["dataModelField", "..."], ...]`).
2. **Tabellgruppering**:
   - Spørsmålene er organisert under tydelige `Step`-seksjoner (Bolk A1, Bolk A2, Bolk B1), som kompilerer pent til semantiske Altinn 3 `Group`- eller `Panel`-komponenter.
