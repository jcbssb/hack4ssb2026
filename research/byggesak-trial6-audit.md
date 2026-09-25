# Revisjon: 20Byggesak-PDF mot Trial 6-DSL

Sammenligner `screenshots/20Byggesak (utfylt).pdf` med `trial6ByggesakDialogue`
(`dsl/src/SchemaDSL/Examples/ByggesakTrial6.hs`). Dato: 2026-09-25.

## Metode

PDF-en er vektorbasert, så cellene kan leses direkte i stedet for fra bilder:

- **Inndatafelt:** de 436 grå boksene (38×12 pt) med verdien som står i dem.
- **Cellebakgrunn:** mørk grå (0.47) = beregnet eller forhåndsutfylt i SSB,
  lys grå (0.82) = åpnes bare ved «Ja» på et inngangsspørsmål eller tall > 0 i et annet
  felt, hvit = vanlig felt (jf. veiledningen på side 1).
- **Plassering:** bokser er gruppert i seksjoner etter overskriftene og i rader/kolonner
  etter posisjon, og sammenlignet celle for celle med matrisene i Trial 6.
- **Kontroll:** tvilstilfeller er sjekket på beskårne sidebilder (bl.a. D1), og mistenkte
  beregninger er regnet ut med eksempeltallene i PDF-en.

Påkrevd-merket `*` lar seg ikke lese pålitelig fra posisjoner og er sjekket på bildene.

## Sammendrag

| | Celler |
|---|---|
| Sammenlignet (finnes i begge) | 410 |
| Samme type (beregnet / betinget / vanlig) | 201 |
| Lys grå i PDF, vanlig felt i Trial 6 (betingelse mangler) | 172 |
| Mørk grå i PDF, ikke beregnet i Trial 6 | 33 |
| Beregnet i Trial 6, men vanlig felt i PDF | 2 (C10 a) |
| Vanlig felt i PDF, betinget i Trial 6 | 2 (C12 1.1 a og 2.1 a) |
| Mangler i Trial 6 | 21 (rad 2.2 i C11–C15, C2, C3 og C14) |
| Finnes i Trial 6, men ikke i PDF | 8 (b1 i D1 2a/4/4a/4b, b1/b2 i D2 2/3) |

Tekstspørsmål, Ja/Nei-spørsmål, merknader og bolk I stemmer, og de 61 beregnede cellene
som allerede er testet mot PDF-en (C11–C14, C3, C4, E1, F3, I) er fortsatt riktige.

## Funn

### 1. Feil formel eller feil celletype (bør rettes)

| Sted | PDF | Trial 6 | Verifisert med eksempeltall |
|---|---|---|---|
| C10 kolonne a «I alt (sum b+c+d)» | vanlig felt, påkrevd | beregnet b+c+d | a = 12, b+c+d = 346: a fylles ut og *kontrolleres* mot summen |
| C14 rad 1 og 2, kolonne a | = C10 a | sum av C11–C13 a | 12 = C10 1a og 2a |
| B kolonne b «Gebyr i rapporteringsåret» | mørk grå (forhåndsutfylt av SSB), ikke påkrevd | vanlig felt, påkrevd | ingen verdi i eksempelet |
| D1 rad 1a, kolonne a | = C10 2a | vanlig felt | 12 = C10 2a |
| D2 rad 1, kolonne a | = C10 2f | vanlig felt | 45 = C10 2f |
| D2 rad 3, kolonne a | = C4 2a | vanlig felt | 579 = C4 2a |
| D1 rad 2a, 4, 4a, 4b | ingen b1, b2 = b (beregnet) | b1 og b2 vanlige felt | b2 = b = 45 i alle fire |
| D2 rad 2 og 3 | ingen b1 eller b2 | b1 og b2 vanlige felt | – |
| E2 kolonne e2 (rad 2, 3a–3d, 4) | e2 = e2a + e2b | vanlig felt (bare kontroll ≤) | 908 = 543+365, 78 = 56+22, 433, 3023, 1868, 1299 |
| F2 rad a, kolonne b–d | = a1 + a2 | vanlige felt | 601 = 345+256, 127 = 83+44, 958 = 923+35 |
| F2 rad a2, kolonne b–d | = a2a + a2b | vanlige felt | 256 = 234+22, 44 = 23+21, 35 = 22+13 |
| G2 rad a, kolonne b–c | = a1 + a2 + a3 | vanlige felt | 120 = 31+63+26, 221 = 76+73+72 |
| G3 rad a, kolonne b–c | = a1 | vanlige felt | 87, 76 |
| G4 rad a, kolonne b–c | = a1 + … + a5 | vanlige felt | 152 = 34+36+38+21+23, 157 |

I F2, G2 og G4 er kolonne a i rad a et vanlig, påkrevd felt; bare «herav»-kolonnene
b og c (og d) summeres.

### 2. Gjennomsnittlig saksbehandlingstid (rad 2.2) er feil modellert

PDF-en beregner gjennomsnitt for totalkolonnene som **vektede gjennomsnitt** av
underkolonnene, vektet med antall behandlede saker i rad 2:

| Sted | PDF (utfylles / beregnes) | Trial 6 | Verifisert |
|---|---|---|---|
| C11, C15, C3 rad 2.2 | b og c utfylles, a beregnes | bare a (utfylles) | – (a er tom i eksempelet) |
| C12, C13, C2 rad 2.2 | b1, b2 og c utfylles; a, b og d beregnes | b1, b2, c utfylles | C12 b = (334·343 + 545·203) / 546 = 412 |
| C4 rad 2.2 | b, c og d utfylles, a beregnes | a–d utfylles | a = (78·56 + 89·67 + 768·456) / 579 = 622 |
| C14 rad 2.2 | hele raden beregnes | mangler | tallene (227, 172, 489) lar seg ikke gjenskape |
| E1 rad 1 og 3, kolonne c | vektet gjennomsnitt av radene under, vektet med b | vanlige felt | rad 1: 1644, rad 3: 1152 |

Vektet gjennomsnitt kan uttrykkes med dagens `Expr`
(`Div (Add [Mul [snitt_i, antall_i], …]) (Add [antall_i, …])`), men matrise-hjelperen
trenger en måte å peke på vektene i en annen rad.

### 3. Lys grå celler mangler betingelser (172 celler)

PDF-en markerer nesten alle «herav»-celler som lys grå, men Trial 6 har betingelser bare
på rad 1.1, 2.1 og 2.2 i C-bolkene og på C16 rad 2. Det gjelder bl.a.:

- «Herav»-kolonnene i C10 (b–d), C11, C13, C15, C2, C3, D1, D2, E1, E2, F1, F2 og G1–G4.
- Underradene i F2 (a1, a2, a2a, a2b), G2 (a1–a3, b1–b3), G3 (a1) og G4 (a1–a5), også i kolonne a.

PDF-en viser ikke *hva* som åpner hver celle. Mønsteret passer med at en celle åpnes når
radens totalkolonne (eller «i alt»-raden i samme kolonne) er større enn 0, men det må
bekreftes i veiledningen før det kodes.

Små avvik i motsatt retning: C12 rad 1.1 og 2.1 kolonne a er hvite i PDF-en, men
betingede i Trial 6. PDF-en er ikke helt konsekvent her (C13 har de samme cellene lys grå).

### 4. Påkrevde felt

Stemmer med PDF-en for A, C10 og «i alt»-cellene i F1, F2, G1, G2 og G4, bortsett fra:

- **B:** ingen `*` i PDF-en, men påkrevd i Trial 6.
- **C10 kolonne a:** blir påkrevd når den gjøres til vanlig felt (funn 1).
- **E1 rad 3a, kolonne b:** har `*` i PDF-en, sannsynligvis en feil i skjemaet.

## Status i Trial 7

Alle fire funn er rettet i `trial7ByggesakDialogue` (`ByggesakTrial7.hs`):

- Funn 1 og 4: celletyper, kopierte celler, summer, radformer og påkrevd-flagg.
- Funn 2: vektede gjennomsnitt, rundet *ned* til hele dager som i PDF-en (622,69 vises
  som 622) med det nye `Floor`-uttrykket i DSL-en.
- Funn 3: lys grå celler åpnes når radens totalkolonne er større enn 0, og celler i
  underrader når «i alt»-raden over er større enn 0 (`matrixOpening` i matrise-hjelperen).

Samme sammenligning mot PDF-en gir nå:

| | Celler |
|---|---|
| Sammenlignet | 431 (ingen mangler eller ekstra celler) |
| Samme type som i PDF-en | 428 |
| Avvik der PDF-en ikke er konsekvent | 3: C12 1.1 a og 2.1 a (hvite, men lys grå i C13), E2 2 e (lys grå, men hvit i radene under) |

`testTrial7AuditFixes` gjengir 30 flere trykte verdier fra PDF-en (kopierte celler,
summer, b2 = b i D1 og gjennomsnitt i hele dager).

## Anbefalt rekkefølge

1. Funn 1: rett formler og celletyper. Trenger ingen nye DSL-funksjoner, bare
   `matrixCellFormulas`, `rowCols` og kolonneformler per rad.
2. Funn 2: vektede gjennomsnitt, med en liten utvidelse av matrise-hjelperen.
3. Funn 3: betingelser for lys grå celler (regelen «total > 0» er valgt; kan justeres
   hvis veiledningen sier noe annet).
4. Funn 4: påkrevd-flagg i B og C10.

Hver rettelse kan testes som i dag: legg eksempeltallene fra PDF-en inn som svar og sjekk
at beregningene gjengir de trykte verdiene.
