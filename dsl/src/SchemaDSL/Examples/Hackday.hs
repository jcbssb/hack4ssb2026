{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}

module SchemaDSL.Examples.Hackday
  ( helloWorldDialogue
  , syntheticHackDialogue
  , rulesDemoDialogue
  ) where

import Data.Aeson (Value(..))
import qualified Data.Aeson.KeyMap as KM
import SchemaDSL.Types

-- | Minimal "Hello World" baseline dialogue matching baseline-schema.json
helloWorldDialogue :: Dialogue
helloWorldDialogue = Dialogue
  { dialogueId = "hack4ssb-hello"
  , title      = "SSB Hackday 2026 - Registrering"
  , context    = Just SurveyContext
      { surveyCode   = Just "HACK-2026"
      , organization = Just "Statistisk sentralbyrå"
      , legalNotice  = Just "Dette skjemaet samler inn teamregistreringer for Hackday 2026."
      }
  , calculations = []
  , constraints  = []
  , steps      =
      [ QuestionStep Question
          { fieldId      = "teamName"
          , prompt       = Prompt
              { label    = "Hva er navnet på ditt Hackday Team?"
              , helpText = Just "Oppgi et unikt lagnavn, f.eks. 'Foran Skjema'."
              }
          , questionType = QText
          , required     = True
          , condition    = Nothing
          , annotations  = Just (KM.fromList [("placeholder", String "F.eks. Foran Skjema"), ("componentHint", String "Input")])
          }
      , QuestionStep Question
          { fieldId      = "trackChoice"
          , prompt       = Prompt
              { label    = "Hvilket hovedspor jobber teamet med?"
              , helpText = Just "Velg det primære fokusområdet for hack-prosjektet."
              }
          , questionType = QChoice
              [ "AI & Skjemaer"
              , "Figma Prototyping"
              , "Altinn 3 Integrasjon"
              , "Kombinasjon / Helhetlig flyt"
              ]
          , required     = False
          , condition    = Nothing
          , annotations  = Just (KM.fromList [("componentHint", String "RadioButtons")])
          }
      ]
  }

-- | Comprehensive synthetic SSB Hackday dialogue exercising extended DSL semantics:
-- Text, TextArea, Integer, Decimal, Date, Boolean, Choice, MultiChoice, and Conditional visibility logic.
syntheticHackDialogue :: Dialogue
syntheticHackDialogue = Dialogue
  { dialogueId = "hack4ssb-comprehensive"
  , title      = "SSB Hackday 2026 - Teamregistrering & Kartlegging"
  , context    = Just SurveyContext
      { surveyCode   = Just "HACK-SSB-2026-SYNTH"
      , organization = Just "Statistisk sentralbyrå"
      , legalNotice  = Just "Dette er et syntetisk SSB-skjema som demonstrerer full dekning av Dialogue DSL-semantikk på Altinn 3."
      }
  , calculations = []
  , constraints  = []
  , steps      =
      [ QuestionStep Question
          { fieldId      = "lagNavn"
          , prompt       = Prompt "Navn på hack-team" (Just "F.eks. 'Foran Skjema' eller 'Klass-Knuserne'")
          , questionType = QText
          , required     = True
          , condition    = Nothing
          , annotations  = Just (KM.fromList [("placeholder", String "Skriv teamnavn...")])
          }
      , QuestionStep Question
          { fieldId      = "antallDeltakere"
          , prompt       = Prompt "Antall deltakere på laget" (Just "Oppgi heltall mellom 1 og 10.")
          , questionType = QInteger
          , required     = True
          , condition    = Nothing
          , annotations  = Nothing
          }
      , QuestionStep Question
          { fieldId      = "budsjettPizzaKaffe"
          , prompt       = Prompt "Estimert snacks- og kaffebudsjett (i tusen kr)" (Just "F.eks. 1.5 for 1500 kr.")
          , questionType = QDecimal
          , required     = False
          , condition    = Nothing
          , annotations  = Nothing
          }
      , QuestionStep Question
          { fieldId      = "startDato"
          , prompt       = Prompt "Planlagt dato for første hack-sprint" (Just "Velg dato i kalenderen.")
          , questionType = QDate
          , required     = False
          , condition    = Nothing
          , annotations  = Nothing
          }
      , QuestionStep Question
          { fieldId      = "primarTeknologi"
          , prompt       = Prompt "Hovedspor / primær teknologi" (Just "Velg det primære fokusområdet.")
          , questionType = QChoice
              [ "Haskell Dialogue DSL"
              , "Figma Auto Layout Prototype"
              , "Altinn 3 Frontend v4"
              , "LLM Agent Pipeline"
              ]
          , required     = True
          , condition    = Nothing
          , annotations  = Just (KM.fromList [("componentHint", String "RadioButtons")])
          }
      , QuestionStep Question
          { fieldId      = "onskerVeiledning"
          , prompt       = Prompt "Ønsker teamet særskilt veiledning fra Altinn/SSB-mentorer?" (Just "Kryss av om dere trenger mentorstøtte.")
          , questionType = QBoolean
          , required     = False
          , condition    = Nothing
          , annotations  = Nothing
          }
      , QuestionStep Question
          { fieldId      = "stotteTemaer"
          , prompt       = Prompt "Hvilke områder trenger dere mentorstøtte på?" (Just "Velg ett eller flere alternativer.")
          , questionType = QMultiChoice
              [ "Datamodellering & XSD"
              , "Felles Designsystem styling"
              , "Altinn Studio REST API"
              , "SSB SUV-undersøkelsesstandarder"
              ]
          , required     = False
          , condition    = Just (IsTrue "onskerVeiledning")
          , annotations  = Just (KM.fromList [("componentHint", String "Checkboxes")])
          }
      , QuestionStep Question
          { fieldId      = "prosjektBeskrivelse"
          , prompt       = Prompt "Utdypende prosjektbeskrivelse og målsetning" (Just "Forklar kort hva teamet skal bygge under hackdayen.")
          , questionType = QTextArea
          , required     = False
          , condition    = Nothing
          , annotations  = Just (KM.fromList [("maxLength", Number 2000)])
          }
      ]
  }

-- | Small demo of calculations and constraints: a budget split into parts,
-- with a derived sum, remainder and share, and rules relating them.
rulesDemoDialogue :: Dialogue
rulesDemoDialogue = Dialogue
  { dialogueId = "hack4ssb-rules"
  , title      = "Regler-demo: Fordeling av budsjett"
  , context    = Just SurveyContext
      { surveyCode   = Just "HACK-2026-RULES"
      , organization = Just "Statistisk sentralbyrå"
      , legalNotice  = Just "Demonstrerer beregnede felt (sum, rest, andel) og kontroller mellom felt."
      }
  , calculations =
      [ Calculation "sumDeler" (sumOf ["personell", "drift", "investering"])
      , Calculation "rest" (Sub (Field "totalBudsjett") (Field "sumDeler"))
      , Calculation "andelPersonell" (Mul [Div (Field "personell") (Field "totalBudsjett"), Const 100])
      ]
  , constraints  =
      [ Constraint
          { constraintId        = "total-positiv"
          , constraintLeft      = Field "totalBudsjett"
          , comparison          = CmpGt
          , constraintRight     = Const 0
          , message             = "Totalbudsjettet må være større enn 0."
          , severity            = SevError
          , constraintCondition = Nothing
          , reportOn            = []
          }
      , Constraint
          { constraintId        = "deler-innenfor-total"
          , constraintLeft      = Field "sumDeler"
          , comparison          = CmpLte
          , constraintRight     = Field "totalBudsjett"
          , message             = "Summen av personell, drift og investering kan ikke overstige totalbudsjettet."
          , severity            = SevError
          , constraintCondition = Nothing
          , reportOn            = []
          }
      , Constraint
          { constraintId        = "fullt-fordelt"
          , constraintLeft      = Field "rest"
          , comparison          = CmpEq
          , constraintRight     = Const 0
          , message             = "Du har svart at hele budsjettet er fordelt, men det gjenstår et restbeløp."
          , severity            = SevWarning
          , constraintCondition = Just (IsTrue "heltFordelt")
          , reportOn            = []
          }
      ]
  , steps      =
      [ BolkStep Bolk
          { bolkId          = "budsjett"
          , bolkTitle       = "Budsjett og fordeling"
          , bolkDescription = Just "Oppgi totalbudsjett og hvordan det fordeles. Sum, rest og andel beregnes automatisk."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ amount "totalBudsjett" "Totalbudsjett (1000 kr)" True
              , amount "personell" "Herav personell (1000 kr)" False
              , amount "drift" "Herav drift (1000 kr)" False
              , amount "investering" "Herav investering (1000 kr)" False
              , derived "sumDeler" "Sum fordelt (beregnet)"
              , derived "rest" "Rest som ikke er fordelt (beregnet)"
              , derived "andelPersonell" "Andel personell i prosent (beregnet)"
              , Question
                  { fieldId      = "restBegrunnelse"
                  , prompt       = Prompt "Hvorfor er ikke hele budsjettet fordelt?" (Just "Vises bare når resten er større enn 0.")
                  , questionType = QTextArea
                  , required     = False
                  , condition    = Just (Compare (Field "rest") CmpGt (Const 0))
                  , annotations  = Nothing
                  }
              , Question
                  { fieldId      = "heltFordelt"
                  , prompt       = Prompt "Er hele budsjettet fordelt?" (Just "Svarer du ja, kontrolleres det at resten er 0.")
                  , questionType = QBoolean
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Nothing
                  }
              ]
          }
      ]
  }
  where
    amount fid lbl req = Question
      { fieldId      = fid
      , prompt       = Prompt lbl (Just "Hele tusen kroner. Tomt felt regnes som 0.")
      , questionType = QDecimal
      , required     = req
      , condition    = Nothing
      , annotations  = Just (KM.fromList [("decimalScale", Number 0)])
      }
    derived fid lbl = Question
      { fieldId      = fid
      , prompt       = Prompt lbl Nothing
      , questionType = QDecimal
      , required     = False
      , condition    = Nothing
      , annotations  = Just (KM.fromList [("readOnly", Bool True), ("decimalScale", Number 1)])
      }
