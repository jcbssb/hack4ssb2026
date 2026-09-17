# Implementation Plan: Grouping Questions with Bolk in Dialogue Schema DSL

## 1. Context & Motivation
KOSTRA and SSB statutory forms are organized into formal thematic sections termed **"Bolk"** (e.g., *Bolk A: Opplysninger*, *Bolk B1: Tid brukt til arbeid*, *Bolk C11: Temaplaner*). Each Bolk has:
- A unique identifier (`bolkId`, e.g. `"bolk_a"`, `"bolk_b1"`).
- A title (`title`, e.g. `"B1. Tid brukt til arbeid med kulturminner i fylkeskommunen"`).
- An optional description or guidance (`description`, e.g. `"Denne delen av utfyllingsarbeidet bør fylkeskommunen delegere til kulturminneavdelingen."`).
- An optional condition (`condition`, e.g., show this entire Bolk only if an earlier precondition is met).
- A list of member questions (`questions`).

Currently, `Dialogue.steps` is a flat `[Question]`, which loses structural visual grouping when rendered in Altinn 3 and simulators.

---

## 2. Proposed Design

### A. Core DSL Types (`SchemaDSL.Types`)
Introduce `Step` sum type to allow both standalone questions and grouped question bolker, or a dedicated `Bolk` container:

```haskell
-- | A Bolk or Group of related questions with title, guidance, and optional condition
data Bolk = Bolk
  { bolkId      :: String
  , title       :: String
  , description :: Maybe String
  , condition   :: Maybe Predicate
  , questions   :: [Question]
  } deriving (Show, Eq, Generic)

-- | A Dialogue Step: either an atomic Question or a structured Bolk
data Step
  = QuestionStep Question
  | BolkStep Bolk
  deriving (Show, Eq, Generic)

-- | Top-level semantic dialogue specification
data Dialogue = Dialogue
  { dialogueId :: String
  , title      :: String
  , context    :: Maybe SurveyContext
  , steps      :: [Step]
  } deriving (Show, Eq, Generic)
```

JSON representation for `steps`:
- Pure Question:
  ```json
  { "type": "question", "fieldId": "fylkesnr", ... }
  ```
  *(or retain backward compatibility where an object with `fieldId` is a Question)*
- Bolk:
  ```json
  {
    "type": "bolk",
    "bolkId": "bolk_b1",
    "title": "B1. Tid brukt til arbeid med kulturminner",
    "description": "Antall årsverk...",
    "questions": [ ... ]
  }
  ```

### B. Helper function to flatten questions
To keep data modeling (`SkjemaData.<fieldId>`, C# classes, JSON Schema) uniform and backward-compatible:
```haskell
allDialogueQuestions :: Dialogue -> [Question]
allDialogueQuestions d = concatMap stepQuestions (steps d)
  where
    stepQuestions (QuestionStep q) = [q]
    stepQuestions (BolkStep b)     = questions b
```

### C. Altinn 3 Compiler (`SchemaDSL.Altinn.Compile`)
When emitting Altinn 3 layouts:
- A `Bolk` compiles to:
  1. A `Group` component containing children IDs, OR
  2. A semantically styled `Header` (level h3) + `Paragraph`/`Panel` followed by its questions.
- If `Bolk` has a `condition`, it applies `hidden` rules to the group/header or cascades to its elements.

### D. Data Model & Inject (`SchemaDSL.Altinn.DataModel` & `Inject`)
- Use `allDialogueQuestions` so `A3_RA-1000_M.schema.json` and `A3_RA-1000_M.cs` stay cleanly synchronized without breaking data bindings.

### E. Metaschema (`SchemaDSL.MetaSchema`)
- Update `baseline-schema-meta.json` with `$defs/Bolk` and `$defs/Step` (`anyOf: [Question, Bolk]`).

### F. Skjema 51 DSL Migration (`SchemaDSL.Examples`)
- Refactor all 6 pages (`kostra51Side1Dialogue` through `kostra51Side6Dialogue`) from flat `[Question]` to structured `Bolk` groups:
  - **Side 1**: `Bolk A`, `Bolk B1`, `Bolk C11`, `Bolk C12`.
  - **Side 2**: `Bolk C12_forts`, `Bolk D1`, `Bolk E`, `Bolk F1`.
  - **Side 3**: `Bolk F2`, `Bolk F3`, `Bolk F4`, `Bolk B2`, `Bolk C21`.
  - **Side 4**: `Bolk C22`, `Bolk C23`.
  - **Side 5**: `Bolk D2_1`, `Bolk D2_2`, `Bolk D2_3`, `Bolk G`, `Bolk H1`.
  - **Side 6**: `Bolk H2`.

### G. Simulator and Visualizer (`simulator/dsl-visualizer.html` & `index.html`)
- Update AST rendering in `dsl-visualizer.html` to display `Bolk` nodes enclosing their child question nodes.
- Update `index.html` to render Bolk containers as bordered card sections with title and description.

---

## 3. Step-by-Step Execution Plan

1. **Phase 1: Type System & Serialization**
   - Update `SchemaDSL.Types` with `Bolk` and `Step`.
   - Update `FromJSON` and `ToJSON` with backward compatibility for flat question lists.
   - Update `SchemaDSL.MetaSchema` to reflect the new `Step` / `Bolk` definitions.

2. **Phase 2: Compiler & Data Model Support**
   - Update `SchemaDSL.Altinn.Compile` to handle `Step` (emitting Group/Header/Panel for Bolk).
   - Update `SchemaDSL.Altinn.DataModel` using `allDialogueQuestions`.

3. **Phase 3: Update Test Suite & Existing Examples**
   - Update `helloWorldDialogue` and `syntheticHackDialogue`.
   - Update tests in `Spec.hs` and verify with `cabal test`.

4. **Phase 4: Transform Skjema 51 to Bolk Structure**
   - Convert `kostra51Side1Dialogue` through `kostra51Side6Dialogue` into explicit Bolker matching the PDF structure.
   - Re-emit `dsl/schemas/*.json` and `simulator/schemas.js`.

5. **Phase 5: Re-inject & Validate in Altinn**
   - Run `--inject-kostra51-all` to refresh Altinn layouts, text resources, and models.
   - Verify layout files and test suite pass completely.
