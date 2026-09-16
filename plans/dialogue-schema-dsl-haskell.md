# Plan: Dialogue Schema DSL i Haskell (Semantisk Representasjon)

**Mål**: Utvikle en minimal Domain-Specific Language (DSL) i Haskell som uttrykker ren **dialogsemantikk** (hva som spørres om, hvilke data som samles inn, betingelser og sekvenser) helt frikoblet fra visuell layout og plattformdetaljer.  
**Målgruppe**: Team Foran Skjema (SSB Hackday 2026)  
**Tilknytning**: Første semantiske steg i pipelinen `DSL (Haskell) ➔ Tolker ➔ [Figma Prototype | Altinn 3 Layout]`.

---

## 1. Filosofi & Arkitektur

### 1.1 Frikobling av Semantikk og Presentasjon
- **DSL-en uttrykker BARE intensjon og dialogflyt**:
  - Hva heter feltet / bindingen?
  - Hva er spørsmålet (ledetekst/prompter)?
  - Hva slags type svar forventes (tekst, heltall, valg fra mengde)?
  - Hvilke regler gjelder (påkrevd, validering, betinget synlighet)?
- **Layout & utførelse overlates til tolkerne (Interpreters)**:
  - *Figma-tolker*: Mapper semantiske spørsmål til frames, autolayout og visuelle designsystem-komponenter.
  - *Altinn 3-tolker*: Mapper semantiske spørsmål til `layout.json`, `dataModelBindings` og `resource.nb.json`.
  - *CLI/Simulerings-tolker*: Kjører dialogen direkte i terminalen for umiddelbar testing.

```
       [Haskell Dialogue DSL] (Ren semantikk)
                  │
        ┌─────────┼─────────┐
        ▼         ▼         ▼
   [CLI Tolker] [Figma Tolker] [Altinn 3 Tolker]
   (Terminal)   (Wireframe)    (App/ui/layouts & model)
```

---

## 2. Minimal Semantisk Datamodell i Haskell

For å støtte Hello World-skjemaet ("Hackday Team Name") holdes DSL-en så enkel som overhodet mulig, men strukturert slik at den enkelt kan utvides med flervalg, forgreninger og gjentagende grupper.

### 2.1 Kjernetyper (`dsl/SchemaDSL.hs`)
```haskell
module SchemaDSL where

-- | Identifikator for datafelt og bindinger
type FieldId = String

-- | Ledetekster og veiledning
data Prompt = Prompt
  { label    :: String
  , helpText :: Maybe String
  } deriving (Show, Eq)

-- | Basistyper for datafangst
data QuestionType
  = QText
  | QInteger
  | QChoice [String]
  deriving (Show, Eq)

-- | Hvert spørsmål representerer ett atomært dialogsteg
data Question = Question
  { fieldId      :: FieldId
  , prompt       :: Prompt
  , questionType :: QuestionType
  , required     :: Bool
  } deriving (Show, Eq)

-- | En dialog består av metadata og en sekvens av dialogsteg
data Dialogue = Dialogue
  { dialogueId    :: String
  , title         :: String
  , steps         :: [Question]
  } deriving (Show, Eq)
```

### 2.2 Hello World Representasjon
```haskell
helloWorldDialogue :: Dialogue
helloWorldDialogue = Dialogue
  { dialogueId = "hack4ssb-hello"
  , title      = "SSB Hackday 2026 - Registrering"
  , steps      =
      [ Question
          { fieldId      = "teamName"
          , prompt       = Prompt
              { label    = "Hva er navnet på ditt Hackday Team?"
              , helpText = Just "Oppgi et unikt lagnavn, f.eks. 'Foran Skjema'"
              }
          , questionType = QText
          , required     = True
          }
      ]
  }
```

---

## 3. Tolk-strategi (Interpreters)

For å sikre at DSL-en mapper mot Figma og Altinn, planlegges to enkle tolkere:

### 3.1 Tolker 1: JSON Intermediate Representation (IR / SSOT Generator)
Haskell-programmet serialiserer dialogen til en nøytral JSON-struktur (`baseline-schema.json`), som fungerer som det portable SSOT-artefaktet for andre systemer:
```json
{
  "dialogueId": "hack4ssb-hello",
  "title": "SSB Hackday 2026 - Registrering",
  "steps": [
    {
      "id": "teamName",
      "label": "Hva er navnet på ditt Hackday Team?",
      "help": "Oppgi et unikt lagnavn, f.eks. 'Foran Skjema'",
      "type": "text",
      "required": true
    }
  ]
}
```
*Formål*: Dette JSON-formatet kan umiddelbart konsumeres av simulatoren, Figma-pluginen eller Altinn-generatoren uten at disse må kjøre Haskell direkte. Haskell forblir den typesikre forfatterkilden (Authoring SSOT), mens JSON-artefaktet er den portable eksekveringskilden (Portable IR SSOT).

### 3.2 Tolker 2: Altinn 3 Generator (`AltinnInterpreter.hs`)
Mapper `Dialogue` direkte til:
- `layout.json`: `Question -> Component (type = "Input", dataModelBindings.simpleBinding = fieldId)`
- `resource.nb.json`: `Prompt -> textResourceBindings`
- `schema.json`: `Question -> JSON Schema property`

### 3.3 Tolker 3: Figma Generator (`FigmaInterpreter.hs`)
Mapper `Dialogue` til en Figma Node Specification (se `plans/figma-schema-prototype.md`):
- `Dialogue` ➔ Root Frame med tittel.
- `Question` ➔ AutoLayout container med Label-tekst, hjelpetekst og Input-rektangel.

---

## 4. Fremdriftsplan og Milepæler

1. **Fase 1: Minimal Haskell-modul**:
   - Opprette `dsl/SchemaDSL.hs` i repoet med kjerne-datastrukturer for `Dialogue`, `Question`, og `Prompt`.
   - Implementere `helloWorldDialogue`.
2. **Fase 2: JSON Serializer**:
   - Legge til en enkel `toJson :: Dialogue -> String` (eller via `aeson` / `show`) for å eksportere den semantiske modellen.
3. **Fase 3: Kobling mot Figma og Altinn**:
   - Bruke den genererte JSON-representasjonen som input til Figma-prototypen og Altinn TT02-generatoren.
4. **Fase 4 (Senere iterasjoner)**:
   - Utvide DSL med forgreninger / logiske betingelser (`Condition`), repeterende grupper (`RepeatingSection`), og valideringspredikater.
