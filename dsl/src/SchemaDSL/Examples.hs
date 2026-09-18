{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}

module SchemaDSL.Examples
  ( helloWorldDialogue
  , syntheticHackDialogue
  , kostra51KulturminneDialogue
  , kostra51Side1Dialogue
  , kostra51Side2Dialogue
  , kostra51Side3Dialogue
  , kostra51Side4Dialogue
  , kostra51Side5Dialogue
  , kostra51Side6Dialogue
  , kostra51FullDialogue
  ) where

import Data.Aeson (Value(..))
import qualified Data.Aeson.KeyMap as KM
import qualified Data.Vector as V
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

-- | KOSTRA 51Plan (Planbehandling, miljø- og kulturminneforvaltning 2026)
-- Reverse engineered from screenshots/bilde.png (Bolk B1)
kostra51KulturminneDialogue :: Dialogue
kostra51KulturminneDialogue = Dialogue
  { dialogueId = "kostra51-kulturminner"
  , title      = "51. Planbehandling, miljø- og kulturminneforvaltning 2026"
  , context    = Just SurveyContext
      { surveyCode   = Just "KOSTRA-51-2026"
      , organization = Just "Statistisk sentralbyrå"
      , legalNotice  = Just "B1. Tid brukt til arbeid med kulturminner i fylkeskommunen. Skjemaet skal leveres med færrest mulig ubesvarte celler. Oppgi 0 dersom det ikke har vært aktivitet."
      }
  , steps      =
      [ BolkStep Bolk
          { bolkId      = "bolk_b1"
          , bolkTitle       = "B1. Tid brukt til arbeid med kulturminner i fylkeskommunen"
          , bolkDescription = Just "Skjemaet skal leveres med færrest mulig ubesvarte celler. Oppgi 0 dersom det ikke har vært aktivitet."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "aarsverkKulturminnerAlt"
                  , prompt       = Prompt "1. Hvor mange årsverk brukte fylkeskommunen til kulturminnearbeid i alt?" (Just "Beregnet totalsum av delpostene 1a til 1d (antall årsverk).")
                  , questionType = QDecimal
                  , required     = False
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList
                      [ ("readOnly", Bool True)
                      , ("decimalScale", Number 1)
                      , ("unit", String "Antall årsverk")
                      , ("calculatedSumOf", Array (V.fromList [String "aarsverkArkeologi", String "aarsverkNyereTid", String "aarsverkArealplan", String "aarsverkAnnet"]))
                      ])
                  }
              , Question
                  { fieldId      = "aarsverkArkeologi"
                  , prompt       = Prompt "... 1a. Herav til arkeologi?" (Just "Oppgi antall årsverk med 1 desimal. Ingen forekomster = 0.")
                  , questionType = QDecimal
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("decimalScale", Number 1), ("unit", String "Antall årsverk")])
                  }
              , Question
                  { fieldId      = "aarsverkNyereTid"
                  , prompt       = Prompt "... 1b. Herav til saksbehandling ift. nyere tids kulturminner?" (Just "Oppgi antall årsverk med 1 desimal. Ingen forekomster = 0.")
                  , questionType = QDecimal
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("decimalScale", Number 1), ("unit", String "Antall årsverk")])
                  }
              , Question
                  { fieldId      = "aarsverkArealplan"
                  , prompt       = Prompt "... 1c. Herav til saksbehandling ift. landskap/by/arealplan?" (Just "Oppgi antall årsverk med 1 desimal. Ingen forekomster = 0.")
                  , questionType = QDecimal
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("decimalScale", Number 1), ("unit", String "Antall årsverk")])
                  }
              , Question
                  { fieldId      = "aarsverkAnnet"
                  , prompt       = Prompt "... 1d. Herav til annet?" (Just "Oppgi antall årsverk med 1 desimal. Ingen forekomster = 0.")
                  , questionType = QDecimal
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("decimalScale", Number 1), ("unit", String "Antall årsverk")])
                  }
              , Question
                  { fieldId      = "aarsverkMidlertidige"
                  , prompt       = Prompt "2a. Hvor mange årsverk til kulturminneforvaltning var midlertidige?" (Just "2. Midlertidige årsverk (antall årsverk).")
                  , questionType = QDecimal
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("decimalScale", Number 1), ("unit", String "Antall årsverk")])
                  }
              ]
          }
      ]
  }

-- | Full Page 1 of KOSTRA 51Plan (Planbehandling, miljø- og kulturminneforvaltning 2026)
-- Reverse engineered from Skjema 51.pdf (Side 1: Bolk A, B1, C11, C12 intro)
kostra51Side1Dialogue :: Dialogue
kostra51Side1Dialogue = Dialogue
  { dialogueId = "kostra51-side1"
  , title      = "51. Planbehandling, miljø- og kulturminneforvaltning 2026 (Side 1)"
  , context    = Just SurveyContext
      { surveyCode   = Just "KOSTRA-51-2026"
      , organization = Just "Statistisk sentralbyrå"
      , legalNotice  = Just "A. Opplysninger om fylket og ansvarlig for rapporteringen. DEL I: Planarbeid og saksbehandling for kulturminner (Bolk B1, C11, C12). Skjemaet skal leveres med færrest mulig ubesvarte celler. Oppgi 0 ved ingen forekomster."
      }
  , steps      =
      -- Bolk A: Opplysninger om fylket og skjemaansvarlig
      [ BolkStep Bolk
          { bolkId      = "bolk_a"
          , bolkTitle       = "A. Opplysninger om fylket og ansvarlig for rapporteringen"
          , bolkDescription = Just "Generelle opplysninger om fylket og kontaktinformasjon til skjemaansvarlig."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "fylkesnr"
                  , prompt       = Prompt "Fylkesnr" (Just "Forhåndsutfylt av SSB.")
                  , questionType = QText
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("readOnly", Bool True), ("placeholder", String "F.eks. 30")])
                  }
              , Question
                  { fieldId      = "fylkesnavn"
                  , prompt       = Prompt "Navnet på fylket" (Just "Forhåndsutfylt av SSB.")
                  , questionType = QText
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("readOnly", Bool True), ("placeholder", String "Fylkeskommune")])
                  }
              , Question
                  { fieldId      = "skjemaansvarligNavn"
                  , prompt       = Prompt "Navn - skjemaansvarlig" (Just "Person ansvarlig for utfylling av skjemaet.")
                  , questionType = QText
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Nothing
                  }
              , Question
                  { fieldId      = "skjemaansvarligTlf"
                  , prompt       = Prompt "Tlf nr" (Just "Telefonnummer til skjemaansvarlig (8 siffer).")
                  , questionType = QText
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("placeholder", String "F.eks. 22864500")])
                  }
              , Question
                  { fieldId      = "skjemaansvarligEpost"
                  , prompt       = Prompt "E-post - skjemaansvarlig" (Just "E-postadresse for oppfølging og bekreftelse.")
                  , questionType = QText
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("placeholder", String "navn@fylke.no")])
                  }
              ]
          }

      -- Bolk B1: Tid brukt til arbeid med kulturminner i fylkeskommunen
      , BolkStep Bolk
          { bolkId      = "bolk_b1"
          , bolkTitle       = "B1. Tid brukt til arbeid med kulturminner i fylkeskommunen"
          , bolkDescription = Just "Oppgi antall årsverk med 1 desimal. Ingen forekomster = 0."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "b1_aarsverkKulturminnerAlt"
                  , prompt       = Prompt "1. Hvor mange årsverk brukte fylkeskommunen til kulturminnearbeid i alt?" (Just "Beregnet totalsum av delpostene 1a til 1d (antall årsverk).")
                  , questionType = QDecimal
                  , required     = False
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList
                      [ ("readOnly", Bool True)
                      , ("decimalScale", Number 1)
                      , ("unit", String "Antall årsverk")
                      , ("calculatedSumOf", Array (V.fromList [String "b1_aarsverkArkeologi", String "b1_aarsverkNyereTid", String "b1_aarsverkArealplan", String "b1_aarsverkAnnet"]))
                      ])
                  }
              , Question
                  { fieldId      = "b1_aarsverkArkeologi"
                  , prompt       = Prompt "... 1a. Herav til arkeologi?" (Just "Oppgi antall årsverk med 1 desimal. Ingen forekomster = 0.")
                  , questionType = QDecimal
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("decimalScale", Number 1), ("unit", String "Antall årsverk")])
                  }
              , Question
                  { fieldId      = "b1_aarsverkNyereTid"
                  , prompt       = Prompt "... 1b. Herav til saksbehandling ift. nyere tids kulturminner?" (Just "Oppgi antall årsverk med 1 desimal. Ingen forekomster = 0.")
                  , questionType = QDecimal
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("decimalScale", Number 1), ("unit", String "Antall årsverk")])
                  }
              , Question
                  { fieldId      = "b1_aarsverkArealplan"
                  , prompt       = Prompt "... 1c. Herav til saksbehandling ift. landskap/by/arealplan?" (Just "Oppgi antall årsverk med 1 desimal. Ingen forekomster = 0.")
                  , questionType = QDecimal
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("decimalScale", Number 1), ("unit", String "Antall årsverk")])
                  }
              , Question
                  { fieldId      = "b1_aarsverkAnnet"
                  , prompt       = Prompt "... 1d. Herav til annet?" (Just "Oppgi antall årsverk med 1 desimal. Ingen forekomster = 0.")
                  , questionType = QDecimal
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("decimalScale", Number 1), ("unit", String "Antall årsverk")])
                  }
              , Question
                  { fieldId      = "b1_aarsverkMidlertidige"
                  , prompt       = Prompt "2a. Hvor mange årsverk til kulturminneforvaltning var midlertidige?" (Just "2. Midlertidige årsverk (antall årsverk).")
                  , questionType = QDecimal
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("decimalScale", Number 1), ("unit", String "Antall årsverk")])
                  }
              ]
          }

      -- Bolk C11: Temaplaner for kulturminner
      , BolkStep Bolk
          { bolkId      = "bolk_c11"
          , bolkTitle       = "C11. Temaplaner for kulturminner etter plan- og bygningsloven"
          , bolkDescription = Just "Gjelder gjeldende temaplaner vedtatt av fylkeskommunen."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "c11_kulturminnerHarPlan"
                  , prompt       = Prompt "1a. Har fylkeskommunen en gjeldende plan etter pbl med spesielt fokus på kulturminner og kulturmiljø?" (Just "Kryss av for Ja eller Nei.")
                  , questionType = QBoolean
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Nothing
                  }
              , Question
                  { fieldId      = "c11_kulturminnerPlanAar"
                  , prompt       = Prompt "1b. Hvilket år ble det sist vedtatt/revidert plan for kulturminner og kulturmiljø?" (Just "Hvis 'Ja' i 1a: oppgi 4-sifret årstall.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "c11_kulturminnerHarPlan")
                  , annotations  = Just (KM.fromList [("placeholder", String "F.eks. 2022")])
                  }
              ]
          }

      -- Bolk C12: Innsigelser til kommunale planer (Kommune-/kommunedelplaner)
      , BolkStep Bolk
          { bolkId      = "bolk_c12_kommune"
          , bolkTitle       = "C12. Innsigelser til kommunale planer - Kommune(del)planer"
          , bolkDescription = Just "Innsigelser begrunnet med hensyn til kulturminner, kulturmiljø og landskap."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "c12_kommuneplanerBehandlet"
                  , prompt       = Prompt "C12.1a Antall behandlede kommune(del)planer i rapporteringsåret" (Just "Totalt antall behandlede planer.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall planer")])
                  }
              , Question
                  { fieldId      = "c12_kommuneplanerInnsigelser"
                  , prompt       = Prompt "C12.1b Antall kommune(del)planer med innsigelser begrunnet med kulturminner" (Just "Herav planer med innsigelser.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall planer")])
                  }
              , Question
                  { fieldId      = "c12_kommuneplanerMekling"
                  , prompt       = Prompt "C12.1c Antall kommune(del)planer brakt til mekling begrunnet med kulturminner" (Just "Herav planer brakt til mekling.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall planer")])
                  }
              ]
          }
      ]
  }

-- | Page 2 of KOSTRA 51Plan (C12 forts., D1 tiltak, E politi, F1 automatisk fredete)
kostra51Side2Dialogue :: Dialogue
kostra51Side2Dialogue = Dialogue
  { dialogueId = "kostra51-side2"
  , title      = "51. Planbehandling, miljø- og kulturminneforvaltning 2026 (Side 2)"
  , context    = Just SurveyContext
      { surveyCode   = Just "KOSTRA-51-2026"
      , organization = Just "Statistisk sentralbyrå"
      , legalNotice  = Just "DEL I: C12 forts., D1 Tiltak/søknader, E Politianmeldelser, F1 Automatisk fredete kulturminner."
      }
  , steps      =
      -- Bolk C12 forts: Områdereguleringsplaner og Detaljreguleringsplaner
      [ BolkStep Bolk
          { bolkId      = "bolk_c12_reguleringsplaner"
          , bolkTitle       = "C12. Innsigelser til kommunale planer - Reguleringsplaner"
          , bolkDescription = Just "Innsigelser til områderegulering og detaljregulering begrunnet med kulturminner."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "c12_omraadeplanerBehandlet"
                  , prompt       = Prompt "C12.2a Antall behandlede områdereguleringsplaner" (Just "Totalt antall behandlede planer.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall planer")])
                  }
              , Question
                  { fieldId      = "c12_omraadeplanerInnsigelser"
                  , prompt       = Prompt "C12.2b Antall områdereguleringsplaner med innsigelser begrunnet med kulturminner" (Just "Herav planer med innsigelser.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall planer")])
                  }
              , Question
                  { fieldId      = "c12_omraadeplanerMekling"
                  , prompt       = Prompt "C12.2c Antall områdereguleringsplaner brakt til mekling begrunnet med kulturminner" (Just "Herav planer brakt til mekling.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall planer")])
                  }
              , Question
                  { fieldId      = "c12_detaljplanerBehandlet"
                  , prompt       = Prompt "C12.3a Antall behandlede detaljreguleringsplaner" (Just "Totalt antall behandlede planer.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall planer")])
                  }
              , Question
                  { fieldId      = "c12_detaljplanerInnsigelser"
                  , prompt       = Prompt "C12.3b Antall detaljreguleringsplaner med innsigelser begrunnet med kulturminner" (Just "Herav planer med innsigelser.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall planer")])
                  }
              , Question
                  { fieldId      = "c12_detaljplanerMekling"
                  , prompt       = Prompt "C12.3c Antall detaljreguleringsplaner brakt til mekling begrunnet med kulturminner" (Just "Herav planer brakt til mekling.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall planer")])
                  }
              ]
          }

      -- Bolk D1: Behandling av tiltak/søknader som påvirker kulturminner
      , BolkStep Bolk
          { bolkId      = "bolk_d1"
          , bolkTitle       = "D1. Behandling av tiltak/søknader som påvirker kulturminner"
          , bolkDescription = Just "Bygge- og rivesaker, meldinger og dispensasjonssøknader fra planbestemmelser og kulturminneloven."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "d1_byggeRivesakerUttalelse"
                  , prompt       = Prompt "D1.1 Antall bygge- og rivesaker i områder med hensynssone eller bevaring som fylkeskommunen har gitt uttalelse til" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall saker")])
                  }
              , Question
                  { fieldId      = "d1_rivingFor1850"
                  , prompt       = Prompt "D1.2 Antall behandlede meldinger om riving/endring av ikke-fredete bygninger oppført før 1850" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall meldinger")])
                  }
              , Question
                  { fieldId      = "d1_rivingEtter1850"
                  , prompt       = Prompt "D1.3 Antall behandlede meldinger om riving/endring av verneverdige bygninger oppført etter 1850" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall meldinger")])
                  }
              , Question
                  { fieldId      = "d1_dispPbl19Alt"
                  , prompt       = Prompt "D1.3a Antall søknader om dispensasjon i medhold av pbl § 19 hvor kulturminner blir berørt i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d1_dispPbl19Fraraad"
                  , prompt       = Prompt "D1.3b Herav søknader der fylkeskommunen har frarådet dispensasjon" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d1_dispPbl19Paaklaget"
                  , prompt       = Prompt "D1.3c Herav (kolonne a) søknader der fylkeskommunen har påklaget vedtak om dispensasjon" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d1_dispKmlAlt"
                  , prompt       = Prompt "D1.4 Antall dispensasjonssøknader fra fredningsvedtak i medhold av kulturminneloven §§ 15a, 19, 20 og 22a" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              ]
          }

      -- Bolk E: Politianmeldelser
      , BolkStep Bolk
          { bolkId      = "bolk_e"
          , bolkTitle       = "E. Politianmeldelser med grunnlag i kulturminneloven"
          , bolkDescription = Nothing
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "e_politianmeldelserKml"
                  , prompt       = Prompt "E.1 Antall politianmeldelser med utgangspunkt i kulturminneloven levert inn siste år" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall anmeldelser")])
                  }
              ]
          }

      -- Bolk F: Automatisk fredete kulturminner (F1)
      , BolkStep Bolk
          { bolkId      = "bolk_f1"
          , bolkTitle       = "F1. Saker om planer og tiltak ift. automatisk fredete kulturminner"
          , bolkDescription = Just "Kommune-, reguleringsplaner og offentlige/private tiltak."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "f1_kommuneReguleringsplanerAlt"
                  , prompt       = Prompt "F1.1a Antall kommune- og reguleringsplansaker hvor forholdet til automatisk fredete kulturminner er vurdert" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall saker")])
                  }
              , Question
                  { fieldId      = "f1_andreSakerAlt"
                  , prompt       = Prompt "F1.1b Antall andre saker hvor forholdet til automatisk fredete kulturminner er vurdert" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall saker")])
                  }
              , Question
                  { fieldId      = "f1_andreSakerSjofart"
                  , prompt       = Prompt "F1.1b Herav oversendt sjøfartsmuseum" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall saker")])
                  }
              , Question
                  { fieldId      = "f1_offentligeStoreTiltak"
                  , prompt       = Prompt "F1.1c Saker som gjelder offentlige og større private tiltak mottatt i rapporteringsåret" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall saker")])
                  }
              , Question
                  { fieldId      = "f1_mindrePrivateTiltak"
                  , prompt       = Prompt "F1.1d Antall saker i 1b som gjelder mindre, private tiltak" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall saker")])
                  }
              ]
          }
      ]
  }

-- | Page 3 of KOSTRA 51Plan (F2a arkeologiske registreringer, F3, F4, DEL II intro, B2, C21)
kostra51Side3Dialogue :: Dialogue
kostra51Side3Dialogue = Dialogue
  { dialogueId = "kostra51-side3"
  , title      = "51. Planbehandling, miljø- og kulturminneforvaltning 2026 (Side 3)"
  , context    = Just SurveyContext
      { surveyCode   = Just "KOSTRA-51-2026"
      , organization = Just "Statistisk sentralbyrå"
      , legalNotice  = Just "DEL I: F2 Arkeologiske registreringer, F3 Skjøtsel, F4 Kostnader. DEL II: B2 Årsverk plan/folkehelse, C21 Egen planlegging."
      }
  , steps      =
      -- Bolk F2: Arkeologiske registreringer
      [ BolkStep Bolk
          { bolkId      = "bolk_f2"
          , bolkTitle       = "F2. Arkeologiske registreringer"
          , bolkDescription = Just "Registreringer gjennomført i rapporteringsåret."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "f2_regAlt"
                  , prompt       = Prompt "F2.2a Arkeologiske registreringer i alt gjennomført i rapporteringsåret" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall registreringer")])
                  }
              , Question
                  { fieldId      = "f2_regKommuneplan"
                  , prompt       = Prompt "F2.2b Herav ifm. kommune(del)planer" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall registreringer")])
                  }
              , Question
                  { fieldId      = "f2_regNyeKulturminner"
                  , prompt       = Prompt "F2.2a1 Av dette: I hvor mange tilfelle ble det påvist ikke tidligere kjente automatisk fredete kulturminner?" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall tilfeller")])
                  }
              , Question
                  { fieldId      = "f2_regMindrePrivate"
                  , prompt       = Prompt "F2.2a2 Hvor mange av registreringene skyldtes mindre, private tiltak?" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall registreringer")])
                  }
              , Question
                  { fieldId      = "f2_regMindrePrivateNye"
                  , prompt       = Prompt "F2.2a2a I hvor mange av disse ble det påvist ikke tidligere kjente automatisk fredete kulturminner?" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall tilfeller")])
                  }
              , Question
                  { fieldId      = "f2_regKrevdDekning"
                  , prompt       = Prompt "F2.2a3 I hvor mange av registreringene ble det krevd kostnadsdekning etter kml § 10?" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall registreringer")])
                  }
              ]
          }

      -- Bolk F3: Skjøtsel og tilrettelegging
      , BolkStep Bolk
          { bolkId      = "bolk_f3"
          , bolkTitle       = "F3. Skjøtsel og tilrettelegging"
          , bolkDescription = Just "Skjøtsel og tilrettelegging av automatisk fredete kulturminner utført uten tilskudd fra Riksantikvaren."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "f3_skjoetselUtenTilskudd"
                  , prompt       = Prompt "F3.3a På hvor mange lokaliteter har fylkeskommunen utført skjøtsel uten tilskudd fra RA?" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall lokaliteter")])
                  }
              , Question
                  { fieldId      = "f3_tilretteleggingUtenTilskudd"
                  , prompt       = Prompt "F3.3b På hvor mange lokaliteter har fylkeskommunen utført tilrettelegging uten tilskudd fra RA?" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall lokaliteter")])
                  }
              ]
          }

      -- Bolk F4: Kostnader og kostnadsdekning
      , BolkStep Bolk
          { bolkId      = "bolk_f4"
          , bolkTitle       = "F4. Kostnader og kostnadsdekning for automatisk fredete kulturminner"
          , bolkDescription = Nothing
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "f4_kostnaderMindrePrivate"
                  , prompt       = Prompt "F4.4a Hvor store kostnader har fylkeskommunen hatt ifm. registreringer for mindre, private tiltak? (Kroner)" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Kroner")])
                  }
              , Question
                  { fieldId      = "f4_belopKrevdDekning"
                  , prompt       = Prompt "F4.4b Hvor stort samlet beløp har fylkeskommunen krevd dekning for ang. automatisk fredete kulturminner, jf. KML § 10? (Kroner)" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Kroner")])
                  }
              ]
          }

      -- DEL II: Bolk B2 Saksbehandlingstid planbehandling og folkehelse
      , BolkStep Bolk
          { bolkId      = "bolk_b2"
          , bolkTitle       = "B2. Årsverk til planbehandling og koordinering av folkehelsearbeidet"
          , bolkDescription = Just "Ressursbruk målt i antall årsverk."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "b2_aarsverkPlanbehandling"
                  , prompt       = Prompt "B2.3 Hvor mange årsverk brukte fylkeskommunen til planbehandling i alt?" Nothing
                  , questionType = QDecimal
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("decimalScale", Number 1), ("unit", String "Antall årsverk")])
                  }
              , Question
                  { fieldId      = "b2_aarsverkKommuneplaner"
                  , prompt       = Prompt "B2.3a ... Herav til behandling av kommunale planer?" Nothing
                  , questionType = QDecimal
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("decimalScale", Number 1), ("unit", String "Antall årsverk")])
                  }
              , Question
                  { fieldId      = "b2_aarsverkEgnePlaner"
                  , prompt       = Prompt "B2.3b ... Herav til utarbeidelse av egne planer?" Nothing
                  , questionType = QDecimal
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("decimalScale", Number 1), ("unit", String "Antall årsverk")])
                  }
              , Question
                  { fieldId      = "b2_aarsverkFolkehelse"
                  , prompt       = Prompt "B2.4 Hvor mange årsverk brukte fylkeskommunen til koordinering av folkehelsearbeidet?" Nothing
                  , questionType = QDecimal
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("decimalScale", Number 1), ("unit", String "Antall årsverk")])
                  }
              ]
          }

      -- Bolk C21: Egen planlegging
      , BolkStep Bolk
          { bolkId      = "bolk_c21"
          , bolkTitle       = "C21. Fylkeskommunens egen planlegging (Planstrategi og regionale planer)"
          , bolkDescription = Just "Vedtatt planstrategi og regionale planer etter plan- og bygningsloven."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "c21_planstrategiAar"
                  , prompt       = Prompt "C21.1a Når ble gjeldende planstrategi vedtatt? (4-sifret årstall)" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("placeholder", String "F.eks. 2024")])
                  }
              , Question
                  { fieldId      = "c21_regionalePlanerVedtatt"
                  , prompt       = Prompt "C21.1b Hvor mange regionale planer ble vedtatt siste år?" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall planer")])
                  }
              , Question
                  { fieldId      = "c21_regionalePlanerFlereFylker"
                  , prompt       = Prompt "C21.1b1 Hvor mange av disse regionale planene omfatter flere fylker?" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall planer")])
                  }
              , Question
                  { fieldId      = "c21_regionalePlanerIkkeHeleFylket"
                  , prompt       = Prompt "C21.1b2 Hvor mange av planene i 1b dekker ikke hele arealet i fylket?" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall planer")])
                  }
              ]
          }
      ]
  }

-- | Page 4 of KOSTRA 51Plan (C22 temaplaner, C23 kommunale planer samlet)
kostra51Side4Dialogue :: Dialogue
kostra51Side4Dialogue = Dialogue
  { dialogueId = "kostra51-side4"
  , title      = "51. Planbehandling, miljø- og kulturminneforvaltning 2026 (Side 4)"
  , context    = Just SurveyContext
      { surveyCode   = Just "KOSTRA-51-2026"
      , organization = Just "Statistisk sentralbyrå"
      , legalNotice  = Just "DEL II: C22 Temaplaner etter pbl vedtatt av fylkeskommunen, C23 Behandling av kommunale planer samlet."
      }
  , steps      =
      -- Bolk C22: 14 Temaplaner (Ja/Nei + Hvis Ja hvilket år)
      [ BolkStep Bolk
          { bolkId      = "bolk_c22"
          , bolkTitle       = "C22. Regionale planer med fokus på bestemte temaer (temaplaner)"
          , bolkDescription = Just "Planer etter plan- og bygningsloven vedtatt av fylkeskommunen. Angi om fylkeskommunen har slik plan, og eventuelt sist vedtatte/reviderte årstall."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "c22_naturmangfoldHarPlan"
                  , prompt       = Prompt "C22.2b Plan med fokus på naturmangfold?" Nothing
                  , questionType = QBoolean
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Nothing
                  }
              , Question
                  { fieldId      = "c22_naturmangfoldAar"
                  , prompt       = Prompt "C22.2b Hvis ja: Hvilket år sist vedtatt/revidert for naturmangfold?" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "c22_naturmangfoldHarPlan")
          , annotations  = Just (KM.fromList [("placeholder", String "Årstall")])
          }
      , Question
          { fieldId      = "c22_friluftslivHarPlan"
          , prompt       = Prompt "C22.2c Plan med fokus på friluftsliv?" Nothing
          , questionType = QBoolean
          , required     = True
          , condition    = Nothing
          , annotations  = Nothing
          }
      , Question
          { fieldId      = "c22_friluftslivAar"
          , prompt       = Prompt "C22.2c Hvis ja: Hvilket år sist vedtatt/revidert for friluftsliv?" Nothing
          , questionType = QInteger
          , required     = True
          , condition    = Just (IsTrue "c22_friluftslivHarPlan")
          , annotations  = Just (KM.fromList [("placeholder", String "Årstall")])
          }
      , Question
          { fieldId      = "c22_gronnstrukturHarPlan"
          , prompt       = Prompt "C22.2d Plan med fokus på grønnstruktur i tettsteder?" Nothing
          , questionType = QBoolean
          , required     = True
          , condition    = Nothing
          , annotations  = Nothing
          }
      , Question
          { fieldId      = "c22_gronnstrukturAar"
          , prompt       = Prompt "C22.2d Hvis ja: Hvilket år sist vedtatt/revidert for grønnstruktur?" Nothing
          , questionType = QInteger
          , required     = True
          , condition    = Just (IsTrue "c22_gronnstrukturHarPlan")
          , annotations  = Just (KM.fromList [("placeholder", String "Årstall")])
          }
      , Question
          { fieldId      = "c22_vassdragHarPlan"
          , prompt       = Prompt "C22.2e Plan med fokus på vassdrag (i tillegg til reg. vannforvaltningsplaner)?" Nothing
          , questionType = QBoolean
          , required     = True
          , condition    = Nothing
          , annotations  = Nothing
          }
      , Question
          { fieldId      = "c22_vassdragAar"
          , prompt       = Prompt "C22.2e Hvis ja: Hvilket år sist vedtatt/revidert for vassdrag?" Nothing
          , questionType = QInteger
          , required     = True
          , condition    = Just (IsTrue "c22_vassdragHarPlan")
          , annotations  = Just (KM.fromList [("placeholder", String "Årstall")])
          }
      , Question
          { fieldId      = "c22_fjellomraaderHarPlan"
          , prompt       = Prompt "C22.2f Plan med fokus på fjellområder?" Nothing
          , questionType = QBoolean
          , required     = True
          , condition    = Nothing
          , annotations  = Nothing
          }
      , Question
          { fieldId      = "c22_fjellomraaderAar"
          , prompt       = Prompt "C22.2f Hvis ja: Hvilket år sist vedtatt/revidert for fjellområder?" Nothing
          , questionType = QInteger
          , required     = True
          , condition    = Just (IsTrue "c22_fjellomraaderHarPlan")
          , annotations  = Just (KM.fromList [("placeholder", String "Årstall")])
          }
      , Question
          { fieldId      = "c22_kystsonenHarPlan"
          , prompt       = Prompt "C22.2g Plan med fokus på kystsonen?" Nothing
          , questionType = QBoolean
          , required     = True
          , condition    = Nothing
          , annotations  = Nothing
          }
      , Question
          { fieldId      = "c22_kystsonenAar"
          , prompt       = Prompt "C22.2g Hvis ja: Hvilket år sist vedtatt/revidert for kystsonen?" Nothing
          , questionType = QInteger
          , required     = True
          , condition    = Just (IsTrue "c22_kystsonenHarPlan")
          , annotations  = Just (KM.fromList [("placeholder", String "Årstall")])
          }
      , Question
          { fieldId      = "c22_universellUtformingHarPlan"
          , prompt       = Prompt "C22.2h Plan med fokus på universell utforming?" Nothing
          , questionType = QBoolean
          , required     = True
          , condition    = Nothing
          , annotations  = Nothing
          }
      , Question
          { fieldId      = "c22_universellUtformingAar"
          , prompt       = Prompt "C22.2h Hvis ja: Hvilket år sist vedtatt/revidert for universell utforming?" Nothing
          , questionType = QInteger
          , required     = True
          , condition    = Just (IsTrue "c22_universellUtformingHarPlan")
          , annotations  = Just (KM.fromList [("placeholder", String "Årstall")])
          }
      , Question
          { fieldId      = "c22_folkehelseHarPlan"
          , prompt       = Prompt "C22.2i Plan med fokus på folkehelse?" Nothing
          , questionType = QBoolean
          , required     = True
          , condition    = Nothing
          , annotations  = Nothing
          }
      , Question
          { fieldId      = "c22_folkehelseAar"
          , prompt       = Prompt "C22.2i Hvis ja: Hvilket år sist vedtatt/revidert for folkehelse?" Nothing
          , questionType = QInteger
          , required     = True
          , condition    = Just (IsTrue "c22_folkehelseHarPlan")
          , annotations  = Just (KM.fromList [("placeholder", String "Årstall")])
          }
      , Question
          { fieldId      = "c22_jordvernHarPlan"
          , prompt       = Prompt "C22.2j Plan med fokus på jordvern?" Nothing
          , questionType = QBoolean
          , required     = True
          , condition    = Nothing
          , annotations  = Nothing
          }
      , Question
          { fieldId      = "c22_jordvernAar"
          , prompt       = Prompt "C22.2j Hvis ja: Hvilket år sist vedtatt/revidert for jordvern?" Nothing
          , questionType = QInteger
          , required     = True
          , condition    = Just (IsTrue "c22_jordvernHarPlan")
          , annotations  = Just (KM.fromList [("placeholder", String "Årstall")])
          }
      , Question
          { fieldId      = "c22_energiHarPlan"
          , prompt       = Prompt "C22.2k Plan med fokus på energi?" Nothing
          , questionType = QBoolean
          , required     = True
          , condition    = Nothing
          , annotations  = Nothing
          }
      , Question
          { fieldId      = "c22_energiAar"
          , prompt       = Prompt "C22.2k Hvis ja: Hvilket år sist vedtatt/revidert for energi?" Nothing
          , questionType = QInteger
          , required     = True
          , condition    = Just (IsTrue "c22_energiHarPlan")
          , annotations  = Just (KM.fromList [("placeholder", String "Årstall")])
          }
      , Question
          { fieldId      = "c22_klimaHarPlan"
          , prompt       = Prompt "C22.2l Plan med fokus på klima?" Nothing
          , questionType = QBoolean
          , required     = True
          , condition    = Nothing
          , annotations  = Nothing
          }
      , Question
          { fieldId      = "c22_klimaAar"
          , prompt       = Prompt "C22.2l Hvis ja: Hvilket år sist vedtatt/revidert for klima?" Nothing
          , questionType = QInteger
          , required     = True
          , condition    = Just (IsTrue "c22_klimaHarPlan")
          , annotations  = Just (KM.fromList [("placeholder", String "Årstall")])
          }
      , Question
          { fieldId      = "c22_samordnetArealHarPlan"
          , prompt       = Prompt "C22.2m Plan med fokus på samordnet areal- og transportplanlegging?" Nothing
          , questionType = QBoolean
          , required     = True
          , condition    = Nothing
          , annotations  = Nothing
          }
      , Question
          { fieldId      = "c22_samordnetArealAar"
          , prompt       = Prompt "C22.2m Hvis ja: Hvilket år sist vedtatt/revidert for samordnet areal- og transport?" Nothing
          , questionType = QInteger
          , required     = True
          , condition    = Just (IsTrue "c22_samordnetArealHarPlan")
          , annotations  = Just (KM.fromList [("placeholder", String "Årstall")])
          }
      , Question
          { fieldId      = "c22_naeringsutviklingHarPlan"
          , prompt       = Prompt "C22.2n Plan med fokus på næringsutvikling, inkl. handel og senterstruktur?" Nothing
          , questionType = QBoolean
          , required     = True
          , condition    = Nothing
          , annotations  = Nothing
          }
      , Question
          { fieldId      = "c22_naeringsutviklingAar"
          , prompt       = Prompt "C22.2n Hvis ja: Hvilket år sist vedtatt/revidert for næringsutvikling?" Nothing
          , questionType = QInteger
          , required     = True
          , condition    = Just (IsTrue "c22_naeringsutviklingHarPlan")
          , annotations  = Just (KM.fromList [("placeholder", String "Årstall")])
          }
      , Question
          { fieldId      = "c22_fritidsutbyggingHarPlan"
          , prompt       = Prompt "C22.2o Plan med fokus på fritidsutbygging?" Nothing
          , questionType = QBoolean
          , required     = True
          , condition    = Nothing
          , annotations  = Nothing
          }
      , Question
          { fieldId      = "c22_fritidsutbyggingAar"
          , prompt       = Prompt "C22.2o Hvis ja: Hvilket år sist vedtatt/revidert for fritidsutbygging?" Nothing
          , questionType = QInteger
          , required     = True
          , condition    = Just (IsTrue "c22_fritidsutbyggingHarPlan")
          , annotations  = Just (KM.fromList [("placeholder", String "Årstall")])
          }
              ]
          }

      -- Bolk C23: Behandling av kommunale planer samlet
      , BolkStep Bolk
          { bolkId      = "bolk_c23"
          , bolkTitle       = "C23. Behandling av kommunale planer samlet"
          , bolkDescription = Just "Behandlede planer, innsigelser og meklinger ut fra alle hensyn (kulturminner, miljø, samferdsel mv.)."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "c23_kommuneplanerAlt"
                  , prompt       = Prompt "C23.3a Kommune(del)planer behandlet i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall planer")])
                  }
              , Question
                  { fieldId      = "c23_kommuneplanerInnsigelser"
                  , prompt       = Prompt "C23.3a Kommune(del)planer med innsigelser ut fra alle hensyn" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall planer")])
                  }
              , Question
                  { fieldId      = "c23_kommuneplanerMekling"
                  , prompt       = Prompt "C23.3a Kommune(del)planer brakt til mekling ut fra alle hensyn" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall planer")])
                  }
              , Question
                  { fieldId      = "c23_omraadeplanerAlt"
                  , prompt       = Prompt "C23.3b Områdereguleringsplaner behandlet i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall planer")])
                  }
              , Question
                  { fieldId      = "c23_omraadeplanerInnsigelser"
                  , prompt       = Prompt "C23.3b Områdereguleringsplaner med innsigelser ut fra alle hensyn" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall planer")])
                  }
              , Question
                  { fieldId      = "c23_omraadeplanerMekling"
                  , prompt       = Prompt "C23.3b Områdereguleringsplaner brakt til mekling ut fra alle hensyn" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall planer")])
                  }
              , Question
                  { fieldId      = "c23_detaljplanerAlt"
                  , prompt       = Prompt "C23.3c Detaljreguleringsplaner behandlet i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall planer")])
                  }
              , Question
                  { fieldId      = "c23_detaljplanerInnsigelser"
                  , prompt       = Prompt "C23.3c Detaljreguleringsplaner med innsigelser ut fra alle hensyn" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall planer")])
                  }
              , Question
                  { fieldId      = "c23_detaljplanerMekling"
                  , prompt       = Prompt "C23.3c Detaljreguleringsplaner brakt til mekling ut fra alle hensyn" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall planer")])
                  }
              ]
          }
      ]
  }

-- | Page 5 of KOSTRA 51Plan (D2 dispensasjoner, G merknader, H tidsbruk intro)
kostra51Side5Dialogue :: Dialogue
kostra51Side5Dialogue = Dialogue
  { dialogueId = "kostra51-side5"
  , title      = "51. Planbehandling, miljø- og kulturminneforvaltning 2026 (Side 5)"
  , context    = Just SurveyContext
      { surveyCode   = Just "KOSTRA-51-2026"
      , organization = Just "Statistisk sentralbyrå"
      , legalNotice  = Just "DEL II: D2 Dispensasjonsbehandling (unntatt kulturminner). DEL III: G Merknader, H Tidsbruk."
      }
  , steps      =
      -- Bolk D2.1: § 1-8 Strandsonen og vassdrag
      [ BolkStep Bolk
          { bolkId      = "bolk_d2_1"
          , bolkTitle       = "D2.1 Dispensasjonsbehandling etter pbl § 1-8 (forbud mot tiltak langs sjø og vassdrag)"
          , bolkDescription = Just "Behandling av søknader om dispensasjon i 100-metersbeltet langs sjø og vassdrag."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "d2_strandsoneBehandlet"
                  , prompt       = Prompt "D2.1a Dispensasjonssøknader etter pbl § 1-8 Strandsonen behandlet i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d2_strandsoneFraraad"
                  , prompt       = Prompt "D2.1a Herav søknader der fylkeskommunen har frarådet dispensasjon" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d2_strandsonePaaklaget"
                  , prompt       = Prompt "D2.1a Herav søknader der fylkeskommunen har påklaget vedtak om dispensasjon" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d2_vassdragBehandlet"
                  , prompt       = Prompt "D2.1b Dispensasjonssøknader etter pbl § 1-8 Vassdrag behandlet i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d2_vassdragFraraad"
                  , prompt       = Prompt "D2.1b Herav søknader der fylkeskommunen har frarådet dispensasjon" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d2_vassdragPaaklaget"
                  , prompt       = Prompt "D2.1b Herav søknader der fylkeskommunen har påklaget vedtak om dispensasjon" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              ]
          }

      -- Bolk D2.2: Dispensasjon fra kommunale planbestemmelser (2a–2g)
      , BolkStep Bolk
          { bolkId      = "bolk_d2_2"
          , bolkTitle       = "D2.2 Dispensasjon fra kommunale planbestemmelser (pbl § 19)"
          , bolkDescription = Just "Behandling av søknader om dispensasjon fra kommune- og reguleringsplanbestemmelser innen ulike saksområder."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "d2_landskapBehandlet"
                  , prompt       = Prompt "D2.2a Landskap og kulturlandskap (LNFR) søknader behandlet i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d2_landskapFraraad"
                  , prompt       = Prompt "D2.2a Herav søknader frarådet dispensasjon" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d2_landskapPaaklaget"
                  , prompt       = Prompt "D2.2a Herav søknader påklaget" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d2_naturomraaderBehandlet"
                  , prompt       = Prompt "D2.2b Større sammenhengende naturområder søknader behandlet i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d2_naturomraaderFraraad"
                  , prompt       = Prompt "D2.2b Herav søknader frarådet" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d2_naturomraaderPaaklaget"
                  , prompt       = Prompt "D2.2b Herav søknader påklaget" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d2_friluftslivBehandlet"
                  , prompt       = Prompt "D2.2c Friluftsliv - retten til fri ferdsel behandlet i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d2_friluftslivFraraad"
                  , prompt       = Prompt "D2.2c Herav søknader frarådet" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d2_friluftslivPaaklaget"
                  , prompt       = Prompt "D2.2c Herav søknader påklaget" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d2_arealTransportBehandlet"
                  , prompt       = Prompt "D2.2d Samordning areal- og transport behandlet i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d2_arealTransportFraraad"
                  , prompt       = Prompt "D2.2d Herav søknader frarådet" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d2_arealTransportPaaklaget"
                  , prompt       = Prompt "D2.2d Herav søknader påklaget" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d2_universellUtformingBehandlet"
                  , prompt       = Prompt "D2.2e Universell utforming og tilgjengelighet behandlet i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d2_universellUtformingFraraad"
                  , prompt       = Prompt "D2.2e Herav søknader frarådet" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d2_universellUtformingPaaklaget"
                  , prompt       = Prompt "D2.2e Herav søknader påklaget" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d2_barnUngeBehandlet"
                  , prompt       = Prompt "D2.2f Barn og unges oppvekstmiljø behandlet i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d2_barnUngeFraraad"
                  , prompt       = Prompt "D2.2f Herav søknader frarådet" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d2_barnUngePaaklaget"
                  , prompt       = Prompt "D2.2f Herav søknader påklaget" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d2_andreBestemmelserBehandlet"
                  , prompt       = Prompt "D2.2g Andre planfaglige bestemmelser behandlet i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d2_andreBestemmelserFraraad"
                  , prompt       = Prompt "D2.2g Herav søknader frarådet" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d2_andreBestemmelserPaaklaget"
                  , prompt       = Prompt "D2.2g Herav søknader påklaget" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              ]
          }

      -- Bolk D2.3: Regionale planer
      , BolkStep Bolk
          { bolkId      = "bolk_d2_3"
          , bolkTitle       = "D2.3 Søknader om dispensasjon fra regionale planer"
          , bolkDescription = Nothing
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "d2_regionalePlanerBehandlet"
                  , prompt       = Prompt "D2.3 Søknader om dispensasjon fra regionale planer behandlet i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d2_regionalePlanerSamtykke"
                  , prompt       = Prompt "D2.3 Herav antall søknader der fylkeskommunen har gitt samtykke" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              , Question
                  { fieldId      = "d2_regionalePlanerIkkeSamtykke"
                  , prompt       = Prompt "D2.3 Herav antall søknader der fylkeskommunen ikke har samtykket" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall søknader")])
                  }
              ]
          }

      -- DEL III: Bolk G Merknader & Bolk H Tidsbruk intro
      , BolkStep Bolk
          { bolkId      = "bolk_g"
          , bolkTitle       = "G. Kommentarer og merknader"
          , bolkDescription = Nothing
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "g_merknader"
                  , prompt       = Prompt "G. Kommentarer og merknader til skjemaet" (Just "Skriv inn dersom du har kommentarer til innhold eller utforming.")
                  , questionType = QTextArea
                  , required     = False
                  , condition    = Nothing
                  , annotations  = Nothing
                  }
              ]
          }

      , BolkStep Bolk
          { bolkId      = "bolk_h1"
          , bolkTitle       = "H. Tidsbruk og elektronisk sakssystem"
          , bolkDescription = Just "Spørsmål om datagrunnlag for rapporteringen."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "h1_elektroniskSakssystem"
                  , prompt       = Prompt "H.1 Er elektronisk sakssystem brukt som grunnlag for rapporteringen?" Nothing
                  , questionType = QBoolean
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Nothing
                  }
              , Question
                  { fieldId      = "h1a_maskinelleOpptellinger"
                  , prompt       = Prompt "H.1a Er tallene framkommet som resultat av maskinelle opptellinger/summeringer?" Nothing
                  , questionType = QBoolean
                  , required     = True
                  , condition    = Just (IsTrue "h1_elektroniskSakssystem")
                  , annotations  = Nothing
                  }
              ]
          }
      ]
  }

-- | Page 6 of KOSTRA 51Plan (H2 tidsbruk timer totalt og delposter)
kostra51Side6Dialogue :: Dialogue
kostra51Side6Dialogue = Dialogue
  { dialogueId = "kostra51-side6"
  , title      = "51. Planbehandling, miljø- og kulturminneforvaltning 2026 (Side 6)"
  , context    = Just SurveyContext
      { surveyCode   = Just "KOSTRA-51-2026"
      , organization = Just "Statistisk sentralbyrå"
      , legalNotice  = Just "DEL III: Bolk H Tidsbruk for rapportering."
      }
  , steps      =
      [ BolkStep Bolk
          { bolkId      = "bolk_h2"
          , bolkTitle       = "H2. Tidsbruk for rapportering"
          , bolkDescription = Just "Oppgi anslag på tidsbruk for framskaffing av informasjon og utfylling av skjemaet."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "h2_timerTotalt"
                  , prompt       = Prompt "H.2 Antall timer det tok å rapportere i alt" (Just "Beregnet totalsum av 2a og 2b (hele timer).")
                  , questionType = QInteger
                  , required     = False
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList
                      [ ("readOnly", Bool True)
                      , ("unit", String "Timer")
                      , ("calculatedSumOf", Array (V.fromList [String "h2a_timerFramskaffe", String "h2b_timerFylleUt"]))
                      ])
                  }
              , Question
                  { fieldId      = "h2a_timerFramskaffe"
                  , prompt       = Prompt "H.2a Antall timer det tok å framskaffe informasjonen" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Timer")])
                  }
              , Question
                  { fieldId      = "h2b_timerFylleUt"
                  , prompt       = Prompt "H.2b Antall timer det tok å fylle ut skjemaet" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Timer")])
                  }
              ]
          }
      ]
  }

-- | Complete KOSTRA 51 survey aggregating all 6 pages into a unified Dialogue SSOT
kostra51FullDialogue :: Dialogue
kostra51FullDialogue = Dialogue
  { dialogueId = "kostra51-full"
  , title      = "51. Planbehandling, miljø- og kulturminneforvaltning 2026 (Komplett undersøkelse)"
  , context    = Just SurveyContext
      { surveyCode   = Just "KOSTRA-51-2026"
      , organization = Just "Statistisk sentralbyrå"
      , legalNotice  = Just "Samlet rapportering for planbehandling, miljø- og kulturminneforvaltning (Side 1 til 6). Skjemaet skal leveres med færrest mulig ubesvarte celler. Oppgi 0 ved ingen forekomster."
      }
  , steps      = concat
      [ steps kostra51Side1Dialogue
      , steps kostra51Side2Dialogue
      , steps kostra51Side3Dialogue
      , steps kostra51Side4Dialogue
      , steps kostra51Side5Dialogue
      , steps kostra51Side6Dialogue
      ]
  }


