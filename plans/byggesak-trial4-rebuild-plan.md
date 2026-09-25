# Plan: Trial 4 for 20Byggesak – ny oppbygging fra PDF med beregninger og kontroller

## Beslutning

Trial 4 bygges på nytt fra `screenshots/20Byggesak (utfylt).pdf` i stedet for å videreføre
Trial 3/4. Begrunnelse:

- Eksisterende trials dekker ca. 15 % av skjemaets ~400 celler (Trial 3: 62 felt, Trial 4: 49).
- Dagens Trial 4 inneholder felt som ikke finnes i skjemaet (B3/B4 «selvkostgrad»,
  D «Matrikkelføring», F3.2 «avsluttet uten avvik») og har mistet C3/C4, D1 og deler av E/F.
- Skjemaets egne regler (mørk grå = beregnet, lys grå = åpnes ved Ja/tall > 0,
  KRITISK FEIL/ADVARSEL) passer direkte på de nye `calculations`/`constraints` i DSL-en.

Det gjenbrukes fra Trial 3: bolk A, B (1a/1b/2a/2b), H og I, samt feltnavnkonvensjonen
(`t4_<bolk>_<navn>`). PDF-teksten er ekstrahert (pypdf, uten OCR) til `research/20byggesak-pdf-tekst.txt` og brukes som kilde –
ingen ny OCR/skjermbildeanalyse.

## Fase 1 – DSL-utvidelser (generelle, ingen Altinn/dotnet-semantikk i kjernen)

### 1a. Numeriske betingelser ✅ (implementert)
- `Predicate` får `Compare Expr Comparison Expr` (JSON: `{"op": "compare", "left", "comparison", "right"}`).
- Brukes for skjemaets lys grå celler: «åpnes når feltet over er > 0».
- Oppdater: `Types.hs`, `Eval.evalPredicate`, `MetaSchema.hs`, Altinn `compilePredicateToHidden`
  og `compilePredicate` (via `compileExpr`), simulatorens `evaluateCondition`.
- Tester: round-trip, evaluering, Altinn-uttrykk.

### 1b. Matrise-hjelper (kun Haskell-byggeklosser, JSON-formatet uendret)
Ny modul `SchemaDSL/Builders.hs`:

```haskell
data Column = Column { colKey :: String, colLabel :: String, colKind :: ColumnKind }
data ColumnKind = Entered | SumOfCols [String] | DiffOfCols String [String]
data Row = Row { rowKey :: String, rowLabel :: String, rowKind :: RowKind }
data RowKind = EnteredRow | SumOfRows [String]

matrix :: String -> [Row] -> [Column] -> ([Question], [Calculation], [Constraint])
```

- Genererer én `Question` per celle (`t4_c12_r2_b1`), med `gridXs` for rutenettvisning.
- Beregnede kolonner/rader blir `Calculation`s (f.eks. `c = a − b`, `d = c + b2`).
- «Herav ≤ i alt» genereres som `Constraint`s, og rest-kolonner får `rest ≥ 0`.
- Hjelpefunksjoner for bolker: `bolkWithRules :: ... -> (Step, [Calculation], [Constraint])`
  slik at dialogen samler regler fra alle bolker med `concat`.

## Fase 2 – Innholdskart fra PDF (Trial 4)

| Bolk | Innhold | Beregnet (verifisert mot utfylte tall) | Kontroller |
|---|---|---|---|
| A | 5 kontaktfelt | – | påkrevd |
| B | 1a/1b, 2a/2b gebyr (kr) | – | ≥ 0 |
| C10 | 2 rader × a–f | a = b + c + d | alle celler påkrevd; behandlet ≤ mottatt (advarsel) |
| C11 | rader 1, 1.1, 2, 2.1, 2.2 × a–c | c = a − b (100 − 44 = 56) | c ≥ 0 (feil); 1.1 ≤ 1a; 2.1 ≤ 2a |
| C12, C13, C2 | 5 rader × a, b, b1, b2, c, d | b = b1 + b2, c = a − b, d = c + b2 | c ≥ 0; herav ≤ i alt |
| C14 | summeringskontroll | alle celler = C11 + C12 + C13 (bekreftes i veiledning) | – |
| C15 | 5 rader × a–c | c = a − b (23 − 233 = −210) | c ≥ 0 |
| C16 | 2 rader × a–c | – | – |
| eKOSTRA | Ja/Nei + kommentar (C11–C2 og D1–D2) | – | – |
| C3 | 5 rader × a–c | c = a − b (897 − 89 = 808) | c ≥ 0 |
| C4 | 5 rader × a–d | a = b + c + d (435 + 564 + 65 = 1064) | – |
| D1 | 9 rader × a, b, b1, b2, c | 1b = sum av rader under (bekreftes) | b ≤ a; b1 + b2 ≤ b; b + c ≤ a |
| D2 | 3 rader × a–c | – | samme som D1 |
| E | E0a, E0b (Ja/Nei) | – | styrer E1/E2 |
| E1 | 8 rader × b, b1, b2, c, d | rad 1 = 2 + 3 + 4; rad 3 = 3a + 3b + 3c + 3d (1353 = 345 + 972 + 36) | b1 + b2 ≤ b |
| E2 | 8 rader × e, e1, e2, e2a, e2b | radsummer som E1 | e1 + e2 = e; e2a + e2b ≤ e2 |
| F0a, F1, F2 | Ja/Nei + matriser (a–d) | a = b + c (bekreftes) | herav ≤ i alt; betinget av F0a |
| F3 | a + a1–a21 | a = sum a1–a21 (945) | – |
| F4 | 2 felt | – | F4.1 + F4.2 ≤ F2.a |
| G0, G1–G4 | Ja/Nei + matriser (a–c) | – (sumrelasjon ikke bekreftet av eksempeltall) | herav ≤ i alt; betinget av G0 |
| H | kommentar (maks 999 tegn) | – | – |
| I | 1, 1a (betinget), 2a, 2b | 2 = 2a + 2b (21 + 11 = 32) | – |

«Bekreftes» = relasjonen står i skjemateksten, men eksempeltallene er ikke konsistente;
avklares mot veiledningen før den kodes som beregning (ellers kun kontroll).

## Fase 3 – Implementasjon

1. Erstatt `trial4ByggesakDialogue` i `Examples/Byggesak.hs` (samme `dialogueId` og side
   `S05_trial4_byggesak`), bygget bolk for bolk med matrise-hjelperen.
2. Altinn-injeksjon: `updateCSharpModel` hopper i dag over klasser som finnes. Utvid den til å
   erstatte eksisterende `Trial4_byggesak`-klasse (ren tekstgenerering, ingen dotnet-avhengighet),
   ellers mangler nye felt i C#-modellen.
3. `--update-all` regenererer `dsl/schemas/trial4-byggesak.json` og `simulator/schemas.js`.

## Fase 4 – Verifisering

- **PDF som fasit:** en test med de utfylte verdiene fra PDF-en som `Answers`;
  `applyCalculations` skal reprodusere de trykte beregnede cellene (C11–C13, C15, C3, C4, E1, F3, I).
- `validateRules` gir ingen feil; dekningstest: antall felt per bolk mot innholdskartet.
- Simulator: `?schema=trial4-byggesak`, manuell gjennomgang av et utvalg bolker.
  (Obs: ett spørsmål per steg blir langt med ~400 felt – vurder senere «én bolk per steg».)
- Altinn: `--inject-trial4` mot `altinn-skjema-hacking`, sjekk Number-komponenter og
  `A3_RA-1000_M.validation.json` i nettleser.

## Rekkefølge og omfang

1. Fase 1a (liten) → 1b (medium) med tester.
2. Fase 2/3 bolkvis: A–C10 → C11–C15 → C16–C4 → D → E → F → G → H–I, grønn test etter hver.
3. Fase 4 til slutt, PDF-fasit-testen utvides fortløpende per bolk.
