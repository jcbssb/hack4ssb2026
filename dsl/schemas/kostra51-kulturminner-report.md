# Extraction Deficit & Findings Report: KOSTRA 51Plan (Kulturminner 2026)

## 1. Source Image
- **Path:** `screenshots/bilde.png`
- **Scope:** Bolk B1 fra KOSTRA-skjema `51. Planbehandling, miljø- og kulturminneforvaltning 2026`

## 2. Extracted Summary
- **Skjematittel:** `51. Planbehandling, miljø- og kulturminneforvaltning 2026`
- **Seksjon/Bolk:** `B1. Tid brukt til arbeid med kulturminner i fylkeskommunen.`
- **Antall felter:** 6 felter
  1. `aarsverkKulturminnerAlt` (Spørsmål 1, beregnet/låst sumfelt)
  2. `aarsverkArkeologi` (Spørsmål 1a, desimaltall)
  3. `aarsverkNyereTid` (Spørsmål 1b, desimaltall)
  4. `aarsverkArealplan` (Spørsmål 1c, desimaltall)
  5. `aarsverkAnnet` (Spørsmål 1d, desimaltall)
  6. `aarsverkMidlertidige` (Spørsmål 2a, desimaltall)
- **Felles enhet:** `Antall årsverk` (desimaltall med 1 desimal)

## 3. Semantic Confidence
- **Teksttydelighet:** 100% lesbar (overskrifter, spm-nummerering 1, 1a-1d, 2, 2a, og kolonneoverskrift er helt skarpe).
- **Fargesemantikk:**
  - Felt 1 har grå bakgrunn: Klassifisert som beregnet sum / skrivebeskyttet (`readOnly: true`).
  - Felt 1a–1d og 2a har hvit bakgrunn: Klassifisert som ordinær utfylling (`required: true` iht. `* Obligatorisk felt`).

## 4. Ambiguities & Clarifications Resolved
- **Datatype for årsverk:** Avklart med bruker til `QDecimal` med 1 desimal.
- **Totalsum 1:** Avklart til dynamisk beregnet sum / readOnly i Altinn.

## 5. DSL & Architecture Limitations
- **Tabell/matrise-representasjon:** Skjermbildet benytter en 2-kolonners tabell der ledetekster er til venstre og inputfelt er samlet under kolonneoverskriften `Antall årsverk`. I nåværende Dialogue DSL representeres hvert ledd som en flat `Question` med `grid`-innrykk. En fremtidig DSL-utvidelse kan innføre en `TableSection` eller `MatrixQuestion` for tabeller med delposter.
- **Beregningsregler (Calculations):** DSL-et har foreløpig `annotations.calculatedSumOf`, som mappes til `readOnly: true` i Altinn. En deklarativ `Calculation`-type i AST-et vil tillate automatisk generering av Altinn v4 dynamiske expressions (`["sum", ["dataModel", ...]]`).
