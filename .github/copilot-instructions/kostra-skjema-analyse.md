---
name: kostra-skjema-tolk
description: Veiledning for skjermbildeanalyse av gamle SSB- og KOSTRA-skjemaer (f.eks. Hubbus/skjema.ssb.no, 20Plan). Bruk for å trekke ut semantisk struktur, bolker, felttyper, celletyper, null-semantikk og kontroller som grunnlag for Dialogue Schema DSL.
---

# Tolking og analyse av skjermbilder fra eldre SSB/KOSTRA-skjemaer

Dette dokumentet gir metodiske retningslinjer for skjermbildeanalyse og reversering av eldre SSB/KOSTRA-skjemaer til Dialogue Schema DSL.

---

## 1. Kontekstlogg og innledende observasjoner

Registrert kontekst fra eldre skjemaer (Immersive Reader / OCR-uttrekk):

```text
Haveråen-Brattås, Jon Are  9/17/2026 10:10:41 AM
TEST for KOSTRA 2026
Språk: Bokmål / Nynorsk
Innlogget som: Intern SSB-test
Skjema/Område: KOSTRA
```

- **Målgruppe/Enhet**: Kommune (ett skjema per kommune; bydel/distrikt er normalt ikke aktuelt).
- **Målform**: To språkversjoner til stede (Bokmål og Nynorsk) med veksling for ledetekster og hjelpetekster.

---

## 2. Struktur som skal trekkes ut fra skjermbilde

| Nivå | Visuell indikator i skjermbilde | Mål i Dialogue DSL |
|---|---|---|
| **Skjema** | Tittel / overskrift øverst (f.eks. «20Plan. Plansaksbehandling 2026», «KOSTRA») | `Dialogue.title`, `dialogueId` |
| **Bolk / Seksjon** | Farget bånd / seksjonsoverskrift (f.eks. «A. Opplysninger om kommunen…») | Gruppe / prefiks på felt, eller sideskille |
| **Rad / Spørsmål** | Én visuell linje med ledetekst + innfyllingsfelt | `Question` |
| **Felt / Kontroll** | Inntastingsboks, nedtrekk, radioknapp, avkryssingsboks | `QuestionType` (`QText`, `QInteger`, `QChoice`, osv.) |
| **Hjelpetekst** | Blå «i»-ikoner, infobokser, fotnoter | `Prompt.helpText` / `guidance` |

---

## 3. Celletyper og fargesemantikk i skjermbilder

Fargekoding i eldre SSB/Hubbus-skjemaer er **funksjonell semantikk**, ikke ren formgiving:

| Visuelt utseende | Kontrast / Farge | Semantisk betydning | Håndtering i DSL / Altinn |
|---|---|---|---|
| **Hvit bakgrunn / tydelig ramme** | Hvit, redigerbar | **Ordinær utfylling.** Obligatorisk hvis merket med rød stjerne `*`. | Standard `Question` med `required: true/false`. |
| **Svak / lys grå bakgrunn** | Lys grå (`#F2F2F2`) | **Forhåndsutfylt av SSB** (f.eks. kommunenummer, kommunenavn). Skal ikke tastes inn av bruker. | Prefill / skrivebeskyttet felt (`readOnly: true`). |
| **Tydelig mørk grå bakgrunn** | Mørk grå | **Beregnet felt eller intern låst verdi.** Skal aldri fylles ut manuelt. | Beregnet felt / sum / avledet verdi. |
| **Mellomgrå / svak grå bakgrunn** | Grå | **Betinget felt.** Åpnes kun ved gitte betingelser (f.eks. ja på inngangsspørsmål eller verdi > 0). | Felt med `condition: Just (Equals ...)` / `compilePredicateToHidden`. |

*Merk*: Dersom fyllfargen er vanskelig å skille i et skjermbilde med lav kontrast, skal det eksplisitt flagges som en usikkerhet i rapporten fremfor å gjette.

---

## 4. Obligatoriskhet og kritisk null-semantikk

- `*` foran eller bak feltet indikerer at feltet er obligatorisk.
- **Kritisk SSB-regel for tallfelter:**
  - **Ingen forekomster** i en kategori $\Rightarrow$ fyll inn **0** (null).
  - **Ukjent verdi** $\Rightarrow$ la feltet stå **tomt** (`null` / ubesvart).
  - *Tomt betyr altså ukjent, ikke null!* Ved migrering til datamodeller må `0` og `NULL` skilles strengt for statistikkvalitet.

---

## 5. Valideringer og kontroller

I eldre SSB-skjemaer finnes to alvorlighetsgrader:
1. **KRITISK FEIL/MANGEL** (rød tekst): Blokkerer innsending av skjemaet, krever oppretting.
2. **ADVARSEL OM FEIL/MANGEL** (blå tekst): Gjør oppmerksom på uvanlige verdier, men tillater innsending (ofte med krav om forklaringstekst).

---

## 6. Feltmetadata som skal fanges opp

For hvert felt i skjermbildet registreres:
- `feltnavn` / ID: Unik teknisk ID (behold standard SSB-koder som `KOMMUNE_NR`, `EPOSTADR`, osv.).
- `ledetekst`: Nøyaktig tekstetikett (støtt både bokmål og nynorsk der det fremgår).
- `datatype`:
  - Høyrejustert tall $\Rightarrow$ `QInteger` eller `QDecimal`.
  - Kommunenummer $\Rightarrow$ `QText` (4 siffer, ledende nuller må aldri fjernes!).
  - Telefonnummer $\Rightarrow$ `QText` (8 siffer).
  - E-post $\Rightarrow$ `QText` med e-postvalidering.
- `obligatorisk`: `true` dersom merket med stjerne, ellers `false`.
- `celletype`: Ordinær, forhåndsutfylt, beregnet, eller betinget.
- `hjelpetekst`: Innhold fra infobobler, veiledning og definisjoner.
- `betinget_av`: Hvilket spørsmål eller verdi som styrer feltets synlighet.

---

## 7. Arbeidsflyt for agenten

1. **Skjemadata og metadata**: Registrer skjemanavn, årgang (f.eks. KOSTRA 2026) og enhetstype.
2. **Struktur**: Del inn i logiske bolker/seksjoner (A, B, C …).
3. **Feltgjennomgang**: Gå systematisk gjennom hver linje; skill datainntasting fra ren veiledningstekst.
4. **Semantisk klassifisering**: Bestem celletype og datamodellbinding.
5. **Definisjoner og hjelp**: Sikre at hjelpetekster og regeldefinisjoner dokumenteres fullstendig.
6. **Deficit- og begrensningsrapport**: Flagg uavklarte felt, tabellstrukturer eller betingelser som overskrider dagens DSL-kapasitet.
