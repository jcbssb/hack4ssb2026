{-# LANGUAGE OverloadedStrings #-}

module SchemaDSL.Examples
  ( helloWorldDialogue
  , syntheticHackDialogue
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
  , steps      =
      [ Question
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
      , Question
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
  , steps      =
      [ Question
          { fieldId      = "lagNavn"
          , prompt       = Prompt "Navn på hack-team" (Just "F.eks. 'Foran Skjema' eller 'Klass-Knuserne'")
          , questionType = QText
          , required     = True
          , condition    = Nothing
          , annotations  = Just (KM.fromList [("placeholder", String "Skriv teamnavn...")])
          }
      , Question
          { fieldId      = "antallDeltakere"
          , prompt       = Prompt "Antall deltakere på laget" (Just "Oppgi heltall mellom 1 og 10.")
          , questionType = QInteger
          , required     = True
          , condition    = Nothing
          , annotations  = Nothing
          }
      , Question
          { fieldId      = "budsjettPizzaKaffe"
          , prompt       = Prompt "Estimert snacks- og kaffebudsjett (i tusen kr)" (Just "F.eks. 1.5 for 1500 kr.")
          , questionType = QDecimal
          , required     = False
          , condition    = Nothing
          , annotations  = Nothing
          }
      , Question
          { fieldId      = "startDato"
          , prompt       = Prompt "Planlagt dato for første hack-sprint" (Just "Velg dato i kalenderen.")
          , questionType = QDate
          , required     = False
          , condition    = Nothing
          , annotations  = Nothing
          }
      , Question
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
      , Question
          { fieldId      = "onskerVeiledning"
          , prompt       = Prompt "Ønsker teamet særskilt veiledning fra Altinn/SSB-mentorer?" (Just "Kryss av om dere trenger mentorstøtte.")
          , questionType = QBoolean
          , required     = False
          , condition    = Nothing
          , annotations  = Nothing
          }
      , Question
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
      , Question
          { fieldId      = "prosjektBeskrivelse"
          , prompt       = Prompt "Utdypende prosjektbeskrivelse og målsetning" (Just "Forklar kort hva teamet skal bygge under hackdayen.")
          , questionType = QTextArea
          , required     = False
          , condition    = Nothing
          , annotations  = Just (KM.fromList [("maxLength", Number 2000)])
          }
      ]
  }
