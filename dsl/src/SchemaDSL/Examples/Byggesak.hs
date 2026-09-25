{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}

module SchemaDSL.Examples.Byggesak
  ( trial1ByggesakDialogue
  , trial2ByggesakDialogue
  , trial3ByggesakDialogue
  , trial4ByggesakDialogue
  ) where

import Data.Aeson (Value(..))
import qualified Data.Aeson.KeyMap as KM
import SchemaDSL.Types

-- | Trial 1: Baseline extraction of 20Byggesak (Side 1 metadata & kontaktinfo + gebyrer intro)
-- Demonstrating the initial stage of schema evolution from PDF to Altinn 3
trial1ByggesakDialogue :: Dialogue
trial1ByggesakDialogue = Dialogue
  { dialogueId = "trial1-byggesak"
  , title      = "20. Byggesak 2026 (Trial 1: Grunnlagsdata og kontaktinfo)"
  , context    = Just SurveyContext
      { surveyCode   = Just "KOSTRA-20-2026"
      , organization = Just "Statistisk sentralbyrå"
      , legalNotice  = Just "Byggesaksbehandling, opprettelse og endring av eiendom, oppmåling og seksjonering 2026. Del A: Kontaktinformasjon og veiledning. Del B: Gebyrer."
      }
  , calculations = []
  , constraints  = []
  , steps      =
      -- Bolk A: Opplysninger om skjema og kontaktinformasjon
      [ BolkStep Bolk
          { bolkId          = "bolk_a"
          , bolkTitle       = "A. Opplysninger om skjema og kontaktinformasjon"
          , bolkDescription = Just "Utfylling av kontaktinformasjon om kommunen og ansvarlig for rapporteringen."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t1_kommunenummer"
                  , prompt       = Prompt "Kommunenummer" (Just "4-sifret kommunenummer.")
                  , questionType = QText
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("placeholder", String "F.eks. 0301"), ("componentHint", String "Input")])
                  }
              , Question
                  { fieldId      = "t1_kommunensNavn"
                  , prompt       = Prompt "Kommunens navn" Nothing
                  , questionType = QText
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("placeholder", String "F.eks. Oslo"), ("componentHint", String "Input")])
                  }
              , Question
                  { fieldId      = "t1_navnSkjemaansvarlig"
                  , prompt       = Prompt "Navn skjemaansvarlig" (Just "Fullt navn på kontaktperson for rapporteringen.")
                  , questionType = QText
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("componentHint", String "Input")])
                  }
              , Question
                  { fieldId      = "t1_telefonnummer"
                  , prompt       = Prompt "Telefonnummer" Nothing
                  , questionType = QText
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("placeholder", String "8 siffer"), ("componentHint", String "Input")])
                  }
              , Question
                  { fieldId      = "t1_epostSkjemaansvarlig"
                  , prompt       = Prompt "E-post skjemaansvarlig" (Just "Offisiell e-postadresse i kommunen.")
                  , questionType = QText
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("placeholder", String "navn@kommune.no"), ("componentHint", String "Input")])
                  }
              ]
          }

      -- Bolk B: Gebyrer (Del 1)
      , BolkStep Bolk
          { bolkId          = "bolk_b"
          , bolkTitle       = "B. Gebyrer"
          , bolkDescription = Just "Byggesaksgebyr og gebyr for opprettelse av grunneiendom (kroner eksl. mva)."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t1_gebyrEneboligVedtatt"
                  , prompt       = Prompt "1a. Byggesaksgebyr vedtatt for inneværende år for oppføring av enebolig (PBL § 20-1 a)" (Just "Kroner eksl. mva.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Kroner")])
                  }
              , Question
                  { fieldId      = "t1_gebyrEneboligRapportering"
                  , prompt       = Prompt "1b. Byggesaksgebyr i rapporteringsåret for oppføring av enebolig" (Just "Kroner eksl. mva.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Kroner")])
                  }
              , Question
                  { fieldId      = "t1_gebyrTomt750mVedtatt"
                  , prompt       = Prompt "2a. Gebyr vedtatt for inneværende år for opprettelse av grunneiendom på 750 m2" (Just "Matrikkellova §§ 5 og 32. Kroner eksl. mva.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Kroner")])
                  }
              , Question
                  { fieldId      = "t1_gebyrTomt750mRapportering"
                  , prompt       = Prompt "2b. Gebyr i rapporteringsåret for opprettelse av grunneiendom på 750 m2" (Just "Matrikkellova §§ 5 og 32. Kroner eksl. mva.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Kroner")])
                  }
              ]
          }
      ]
  }

-- | Trial 2: Complete reverse-engineering of 20Byggesak (Pages 1-9)
-- Capturing administrative data, fees, application volumes, permits, surveying, appeals, supervision, enforcement, comments, and time usage.
trial2ByggesakDialogue :: Dialogue
trial2ByggesakDialogue = Dialogue
  { dialogueId = "trial2-byggesak"
  , title      = "20. Byggesak 2026 (Trial 2: Fullstendig undersøkelse Side 1-9)"
  , context    = Just SurveyContext
      { surveyCode   = Just "KOSTRA-20-2026"
      , organization = Just "Statistisk sentralbyrå"
      , legalNotice  = Just "Byggesaksbehandling, opprettelse og endring av eiendom, oppmåling og seksjonering 2026. Del A-I. Skjemaet skal leveres med færrest mulig ubesvarte celler. Oppgi 0 ved ingen forekomster."
      }
  , calculations = []
  , constraints  = []
  , steps      =
      -- Seksjon A: Kontaktinformasjon
      [ BolkStep Bolk
          { bolkId          = "bolk_a"
          , bolkTitle       = "A. Opplysninger om skjema og kontaktinformasjon"
          , bolkDescription = Just "Utfylling av kontaktinformasjon om kommunen og ansvarlig for rapporteringen."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t2_kommunenummer"
                  , prompt       = Prompt "Kommunenummer" (Just "4-sifret kommunenummer forhåndsutfylt eller kontrollert.")
                  , questionType = QText
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("placeholder", String "F.eks. 0301"), ("componentHint", String "Input")])
                  }
              , Question
                  { fieldId      = "t2_kommunensNavn"
                  , prompt       = Prompt "Kommunens navn" Nothing
                  , questionType = QText
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("placeholder", String "F.eks. Oslo"), ("componentHint", String "Input")])
                  }
              , Question
                  { fieldId      = "t2_navnSkjemaansvarlig"
                  , prompt       = Prompt "Navn skjemaansvarlig" (Just "Fullt navn på kontaktperson.")
                  , questionType = QText
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("componentHint", String "Input")])
                  }
              , Question
                  { fieldId      = "t2_telefonnummer"
                  , prompt       = Prompt "Telefonnummer" Nothing
                  , questionType = QText
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("placeholder", String "8 siffer"), ("componentHint", String "Input")])
                  }
              , Question
                  { fieldId      = "t2_epostSkjemaansvarlig"
                  , prompt       = Prompt "E-post skjemaansvarlig" (Just "Offisiell e-postadresse i kommunen.")
                  , questionType = QText
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("placeholder", String "navn@kommune.no"), ("componentHint", String "Input")])
                  }
              ]
          }

      -- Seksjon B: Gebyrer
      , BolkStep Bolk
          { bolkId          = "bolk_b"
          , bolkTitle       = "B. Gebyrer"
          , bolkDescription = Just "Byggesaksgebyr og opprettelse av grunneiendom (kroner eksl. mva)."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t2_gebyrEneboligVedtatt"
                  , prompt       = Prompt "1a. Byggesaksgebyr vedtatt for inneværende år for oppføring av enebolig (PBL § 20-1 a)" (Just "Kroner eksl. mva.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Kroner")])
                  }
              , Question
                  { fieldId      = "t2_gebyrEneboligRapportering"
                  , prompt       = Prompt "1b. Byggesaksgebyr i rapporteringsåret for oppføring av enebolig" (Just "Kroner eksl. mva.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Kroner")])
                  }
              , Question
                  { fieldId      = "t2_gebyrTomt750mVedtatt"
                  , prompt       = Prompt "2a. Gebyr vedtatt for inneværende år for opprettelse av grunneiendom på 750 m2" (Just "Matrikkellova §§ 5 og 32. Kroner eksl. mva.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Kroner")])
                  }
              , Question
                  { fieldId      = "t2_gebyrTomt750mRapportering"
                  , prompt       = Prompt "2b. Gebyr i rapporteringsåret for opprettelse av grunneiendom på 750 m2" (Just "Matrikkellova §§ 5 og 32. Kroner eksl. mva.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Kroner")])
                  }
              ]
          }

      -- Seksjon C10: Hovedtall søknadsvolum
      , BolkStep Bolk
          { bolkId          = "bolk_c10"
          , bolkTitle       = "C10. Antall byggesøknader, dispensasjonssøknader og deling (Hovedtall)"
          , bolkDescription = Just "Omfang av søknader mottatt og behandlet i rapporteringsåret fordelt på søknadstyper."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t2_c10_rammesoknaderMottatt"
                  , prompt       = Prompt "C10.1b Rammesøknader mottatt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              , Question
                  { fieldId      = "t2_c10_rammesoknaderBehandlet"
                  , prompt       = Prompt "C10.2b Rammesøknader behandlet/vedtatt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              , Question
                  { fieldId      = "t2_c10_ettTrinnMedAnsvarMottatt"
                  , prompt       = Prompt "C10.1c Ett-trinnssøknader med ansvarsrett mottatt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              , Question
                  { fieldId      = "t2_c10_ettTrinnMedAnsvarBehandlet"
                  , prompt       = Prompt "C10.2c Ett-trinnssøknader med ansvarsrett behandlet" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              , Question
                  { fieldId      = "t2_c10_ettTrinnUtenAnsvarMottatt"
                  , prompt       = Prompt "C10.1d Ett-trinnssøknader uten ansvarsrett mottatt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              , Question
                  { fieldId      = "t2_c10_ettTrinnUtenAnsvarBehandlet"
                  , prompt       = Prompt "C10.2d Ett-trinnssøknader uten ansvarsrett behandlet" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              , Question
                  { fieldId      = "t2_c10_dispensasjonMottatt"
                  , prompt       = Prompt "C10.1e Dispensasjonssøknader mottatt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              , Question
                  { fieldId      = "t2_c10_dispensasjonBehandlet"
                  , prompt       = Prompt "C10.2e Dispensasjonssøknader behandlet" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              , Question
                  { fieldId      = "t2_c10_delingMottatt"
                  , prompt       = Prompt "C10.1f Opprettelse/endring av eiendom (deling) mottatt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              , Question
                  { fieldId      = "t2_c10_delingBehandlet"
                  , prompt       = Prompt "C10.2f Opprettelse/endring av eiendom (deling) behandlet" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              ]
          }

      -- Seksjon C11-C15: Saksbehandlingstider og eKOSTRA
      , BolkStep Bolk
          { bolkId          = "bolk_c11_c16"
          , bolkTitle       = "C11-C16. Saksbehandlingstid og tillatelser"
          , bolkDescription = Just "Saksbehandlingstider, fristoverskridelser og tillatelser (IG, MB, FA)."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t2_c11_rammeTidDager"
                  , prompt       = Prompt "C11.2.2 Rammesøknader gjennomsnittlig saksbehandlingstid" (Just "Kalenderdager.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Dager")])
                  }
              , Question
                  { fieldId      = "t2_c12_ettTrinnMedAnsvarTidDager"
                  , prompt       = Prompt "C12.2.2 Ett-trinnssøknader med ansvarsrett gjennomsnittlig saksbehandlingstid" (Just "Kalenderdager.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Dager")])
                  }
              , Question
                  { fieldId      = "t2_c13_ettTrinnUtenAnsvarTidDager"
                  , prompt       = Prompt "C13.2.2 Ett-trinnssøknader uten ansvarsrett gjennomsnittlig saksbehandlingstid" (Just "Kalenderdager.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Dager")])
                  }
              , Question
                  { fieldId      = "t2_c16_igBehandlet"
                  , prompt       = Prompt "C16.1a Igangsettingstillatelser (IG) behandlet" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              , Question
                  { fieldId      = "t2_c16_mbBehandlet"
                  , prompt       = Prompt "C16.1b Midlertidige brukstillatelser (MB) behandlet" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              , Question
                  { fieldId      = "t2_c16_faBehandlet"
                  , prompt       = Prompt "C16.1c Ferdigattester (FA) behandlet" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              , Question
                  { fieldId      = "t2_eKostraTattIBruk"
                  , prompt       = Prompt "Har kommunen tatt i bruk eByggesak for rapportering av omfang og saksbehandlingstid (eKOSTRA)?" Nothing
                  , questionType = QBoolean
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Nothing
                  }
              ]
          }

      -- Seksjon C3-C4: Oppmåling og eierseksjonering
      , BolkStep Bolk
          { bolkId          = "bolk_c3_c4"
          , bolkTitle       = "C3-C4. Oppmålingsforretninger og eierseksjonering"
          , bolkDescription = Just "Rekvisisjoner for oppmålingsforretning og eierseksjoneringssaker."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t2_c3_oppmaalingMottatt"
                  , prompt       = Prompt "C3.1 Rekvisisjoner for oppmålingsforretning mottatt i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              , Question
                  { fieldId      = "t2_c3_oppmaalingBehandlet"
                  , prompt       = Prompt "C3.2 Rekvisisjoner for oppmålingsforretning behandlet i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              , Question
                  { fieldId      = "t2_c4_seksjoneringMottatt"
                  , prompt       = Prompt "C4.1 Søknader om seksjonering mottatt i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              , Question
                  { fieldId      = "t2_c4_seksjoneringBehandlet"
                  , prompt       = Prompt "C4.2 Søknader om seksjonering behandlet i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              ]
          }

      -- Seksjon D: Resultat av saksbehandling og vernede byggverk
      , BolkStep Bolk
          { bolkId          = "bolk_d"
          , bolkTitle       = "D. Resultat av søknadsbehandling og vernehensyn"
          , bolkDescription = Just "Innvilgelser, avslagsvedtak, tiltak i LNF-områder, strandsone og kulturminner."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t2_d1_vedtakAlt"
                  , prompt       = Prompt "D1.1a Byggesøknader vedtatt i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall vedtak")])
                  }
              , Question
                  { fieldId      = "t2_d1_vedtakInnvilget"
                  , prompt       = Prompt "D1.1b Herav innvilget i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall vedtak")])
                  }
              , Question
                  { fieldId      = "t2_d1_vedtakAvslag"
                  , prompt       = Prompt "D1.1c Herav avslag" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall vedtak")])
                  }
              , Question
                  { fieldId      = "t2_d1_lnfrNyeBygg"
                  , prompt       = Prompt "D1.2 Vedtak som gjaldt nye byggverk i LNFR-områder utenfor 100-metersbeltet langs saltvann" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall vedtak")])
                  }
              , Question
                  { fieldId      = "t2_d1_strandsoneNyeBygg"
                  , prompt       = Prompt "D1.3 Vedtak som gjaldt nye byggverk i 100-metersbeltet langs saltvann" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall vedtak")])
                  }
              , Question
                  { fieldId      = "t2_d1_ikkeFredetFor1850"
                  , prompt       = Prompt "D1.6 Vedtak som gjaldt tiltak i ikke-fredete byggverk oppført før 1850" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall vedtak")])
                  }
              , Question
                  { fieldId      = "t2_d1_fredetByggverk"
                  , prompt       = Prompt "D1.7 Vedtak som gjaldt tiltak i fredete byggverk uansett oppføringsår" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall vedtak")])
                  }
              ]
          }

      -- Seksjon E: Klagesaksbehandling
      , BolkStep Bolk
          { bolkId          = "bolk_e"
          , bolkTitle       = "E. Klagesaksbehandling"
          , bolkDescription = Just "Klagesaker behandlet i kommunen og klager oversendt til Statsforvalteren."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t2_e0a_harKlager"
                  , prompt       = Prompt "E0a. Har kommunen mottatt eller behandlet klager i rapporteringsåret?" Nothing
                  , questionType = QBoolean
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Nothing
                  }
              , Question
                  { fieldId      = "t2_e1_klagerKommuneAlt"
                  , prompt       = Prompt "E1.1 Klagesaker behandlet i kommunen i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t2_e0a_harKlager")
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              , Question
                  { fieldId      = "t2_e1_klagerTattTilFoelge"
                  , prompt       = Prompt "E1.1b1 Herav klagesaker tatt til følge av kommunen" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t2_e0a_harKlager")
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              , Question
                  { fieldId      = "t2_e1_klagerOversendtStatsforvalter"
                  , prompt       = Prompt "E1.1b2 Herav klagesaker oversendt Statsforvalteren" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t2_e0a_harKlager")
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              , Question
                  { fieldId      = "t2_e0b_statsforvalterBehandlet"
                  , prompt       = Prompt "E0b. Har Statsforvalteren behandlet kommunale vedtak ang. klager i rapporteringsåret?" Nothing
                  , questionType = QBoolean
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Nothing
                  }
              ]
          }

      -- Seksjon F: Tilsyn
      , BolkStep Bolk
          { bolkId          = "bolk_f"
          , bolkTitle       = "F. Tilsyn og ulovlighetsoppfølging"
          , bolkDescription = Just "Gjennomførte tilsyn (byggesaker og ikke-omsøkte tiltak) og tema etter TEK17."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t2_f0a_erUtfoertTilsyn"
                  , prompt       = Prompt "F0a. Er det utført tilsyn med tiltak i rapporteringsåret?" Nothing
                  , questionType = QBoolean
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Nothing
                  }
              , Question
                  { fieldId      = "t2_f2_tilsynAlt"
                  , prompt       = Prompt "F2.a Antall gjennomførte tilsyn i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t2_f0a_erUtfoertTilsyn")
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              , Question
                  { fieldId      = "t2_f2_tilsynOmsoekte"
                  , prompt       = Prompt "F2.a1 Antall tilsyn med omsøkte tiltak (byggesaker)" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t2_f0a_erUtfoertTilsyn")
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              , Question
                  { fieldId      = "t2_f2_tilsynIkkeOmsoekte"
                  , prompt       = Prompt "F2.a2 Antall tilsyn med ikke-omsøkte tiltak (unntak og ulovligheter)" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t2_f0a_erUtfoertTilsyn")
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              , Question
                  { fieldId      = "t2_f4_tilsynOk"
                  , prompt       = Prompt "F4.1 Antall tilsyn der alt var OK (ingen feil/mangler påvist)" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t2_f0a_erUtfoertTilsyn")
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              , Question
                  { fieldId      = "t2_f4_tilsynAvdekketUlovlighet"
                  , prompt       = Prompt "F4.2 Antall tilsyn som avdekket ulovlighet/forhold som krever oppfølging" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t2_f0a_erUtfoertTilsyn")
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              ]
          }

      -- Seksjon G: Pålegg og sanksjoner
      , BolkStep Bolk
          { bolkId          = "bolk_g"
          , bolkTitle       = "G. Pålegg, sanksjoner og andre virkemidler"
          , bolkDescription = Just "Gitte pålegg (retting, opphør, stans), tvangsmulkt, overtredelsesgebyr og anmeldelser."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t2_g0_erGittPaaleggEllerSanksjoner"
                  , prompt       = Prompt "G0. Er det gitt pålegg, brukt sanksjoner eller andre virkemidler i rapporteringsåret?" Nothing
                  , questionType = QBoolean
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Nothing
                  }
              , Question
                  { fieldId      = "t2_g1_paaleggAlt"
                  , prompt       = Prompt "G1.a Antall pålegg gitt i rapporteringsåret i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t2_g0_erGittPaaleggEllerSanksjoner")
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              , Question
                  { fieldId      = "t2_g1_paaleggRetting"
                  , prompt       = Prompt "G1.b1 Pålegg om retting (pbl § 32-3)" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t2_g0_erGittPaaleggEllerSanksjoner")
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              , Question
                  { fieldId      = "t2_g1_paaleggOpphoer"
                  , prompt       = Prompt "G1.b2 Pålegg om opphør av bruk (pbl § 32-3 og § 32-4)" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t2_g0_erGittPaaleggEllerSanksjoner")
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              , Question
                  { fieldId      = "t2_g1_paaleggStans"
                  , prompt       = Prompt "G1.b3 Pålegg om stans (pbl § 32-3 og § 32-4)" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t2_g0_erGittPaaleggEllerSanksjoner")
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              , Question
                  { fieldId      = "t2_g3_sanksjonerAlt"
                  , prompt       = Prompt "G3.a Antall sanksjoner brukt i rapporteringsåret i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t2_g0_erGittPaaleggEllerSanksjoner")
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              , Question
                  { fieldId      = "t2_g3_overtredelsesgebyr"
                  , prompt       = Prompt "G3.a1 Overtredelsesgebyr (pbl § 32-8 og SAK10 kap. 16)" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t2_g0_erGittPaaleggEllerSanksjoner")
                  , annotations  = Just (KM.fromList [("unit", String "Antall")])
                  }
              ]
          }

      -- Seksjon H: Merknader og kommentarer
      , BolkStep Bolk
          { bolkId          = "bolk_h"
          , bolkTitle       = "H. Kommentarer og merknader til skjemaet"
          , bolkDescription = Just "Åpent merknadsfelt for tilbakemelding om uklarheter eller forbedringsforslag."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t2_merknader"
                  , prompt       = Prompt "Kommentarer og merknader til utfyllingen (maks 999 tegn)" Nothing
                  , questionType = QTextArea
                  , required     = False
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("placeholder", String "Skriv eventuelle merknader her...")])
                  }
              ]
          }

      -- Seksjon I: Grunnlag for rapportering og tidsbruk
      , BolkStep Bolk
          { bolkId          = "bolk_i"
          , bolkTitle       = "I. Grunnlag for rapportering og tidsbruk"
          , bolkDescription = Just "Elektronisk sakssystem og tidsbruk for framskaffing og utfylling."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t2_elektroniskSakssystemBrukt"
                  , prompt       = Prompt "I.1 Er elektronisk sakssystem brukt som grunnlag for store deler av rapporteringen?" Nothing
                  , questionType = QBoolean
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Nothing
                  }
              , Question
                  { fieldId      = "t2_maskinelleOpptellinger"
                  , prompt       = Prompt "I.1a Hvis ja: Er tallene framkommet som resultat av maskinelle opptellinger/summeringer?" Nothing
                  , questionType = QBoolean
                  , required     = True
                  , condition    = Just (IsTrue "t2_elektroniskSakssystemBrukt")
                  , annotations  = Nothing
                  }
              , Question
                  { fieldId      = "t2_timerTotalt"
                  , prompt       = Prompt "I.2 Antall timer det tok å rapportere totalt" (Just "Hele timer.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Timer")])
                  }
              , Question
                  { fieldId      = "t2_timerUtfylling"
                  , prompt       = Prompt "I.2a Antall timer det tok å fylle ut skjemaet" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Timer")])
                  }
              , Question
                  { fieldId      = "t2_timerFremskaffe"
                  , prompt       = Prompt "I.2b Antall timer det tok å framskaffe informasjonen" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Timer")])
                  }
              ]
          }
      ]
  }

-- | Trial 3: Production Semantics, Ergonomics & Refined Grid Layouts for 20Byggesak
-- Evolves Trial 2 by introducing:
-- 1. Calculated Summary bindings (C10 totals, I2 total hours read-only calculated indicators)
-- 2. Multi-column Altinn responsive grid pairings (gridXs: 6, 4) for vedtatt vs rapportering and mottatt vs behandlet
-- 3. Dynamic conditional gating on follow-up questions
-- 4. Precise currency and time unit constraints
trial3ByggesakDialogue :: Dialogue
trial3ByggesakDialogue = Dialogue
  { dialogueId = "trial3-byggesak"
  , title      = "20. Byggesak 2026 (Trial 3: Produksjonssemantikk & Rutenett-ergonomi)"
  , context    = Just SurveyContext
      { surveyCode   = Just "KOSTRA-20-2026"
      , organization = Just "Statistisk sentralbyrå"
      , legalNotice  = Just "Byggesaksbehandling, opprettelse og endring av eiendom, oppmåling og seksjonering 2026. Del A-I med automatisk summering, validering og responsiv rutenettoppstilling."
      }
  , calculations = []
  , constraints  = []
  , steps      =
      -- Seksjon A: Kontaktinformasjon med 2-kolonne oppsett for telefon/e-post
      [ BolkStep Bolk
          { bolkId          = "bolk_a"
          , bolkTitle       = "A. Opplysninger om skjema og kontaktinformasjon"
          , bolkDescription = Just "Utfylling av kontaktinformasjon om kommunen og ansvarlig for rapporteringen."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t3_kommunenummer"
                  , prompt       = Prompt "Kommunenummer" (Just "4-sifret kommunenummer.")
                  , questionType = QText
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("placeholder", String "F.eks. 0301"), ("gridXs", Number 6), ("componentHint", String "Input")])
                  }
              , Question
                  { fieldId      = "t3_kommunensNavn"
                  , prompt       = Prompt "Kommunens navn" Nothing
                  , questionType = QText
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("placeholder", String "F.eks. Oslo"), ("gridXs", Number 6), ("componentHint", String "Input")])
                  }
              , Question
                  { fieldId      = "t3_navnSkjemaansvarlig"
                  , prompt       = Prompt "Navn skjemaansvarlig" (Just "Fullt navn på kontaktperson for rapporteringen.")
                  , questionType = QText
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("gridXs", Number 12), ("componentHint", String "Input")])
                  }
              , Question
                  { fieldId      = "t3_telefonnummer"
                  , prompt       = Prompt "Telefonnummer" Nothing
                  , questionType = QText
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("placeholder", String "8 siffer"), ("gridXs", Number 6), ("componentHint", String "Input")])
                  }
              , Question
                  { fieldId      = "t3_epostSkjemaansvarlig"
                  , prompt       = Prompt "E-post skjemaansvarlig" (Just "Offisiell e-postadresse i kommunen.")
                  , questionType = QText
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("placeholder", String "navn@kommune.no"), ("gridXs", Number 6), ("componentHint", String "Input")])
                  }
              ]
          }

      -- Seksjon B: Gebyrer med 2-kolonne sammenligning (vedtatt vs rapportering)
      , BolkStep Bolk
          { bolkId          = "bolk_b"
          , bolkTitle       = "B. Gebyrer"
          , bolkDescription = Just "Byggesaksgebyr og opprettelse av grunneiendom (kroner eksl. mva). Sammenligning av vedtatt gebyr mot rapporteringsåret."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t3_gebyrEneboligVedtatt"
                  , prompt       = Prompt "1a. Byggesaksgebyr for enebolig: Vedtatt for inneværende år" (Just "PBL § 20-1 a. Kroner eksl. mva.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Kroner"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t3_gebyrEneboligRapportering"
                  , prompt       = Prompt "1b. Byggesaksgebyr for enebolig: I rapporteringsåret" (Just "PBL § 20-1 a. Kroner eksl. mva.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Kroner"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t3_gebyrTomt750mVedtatt"
                  , prompt       = Prompt "2a. Gebyr for 750 m² tomt: Vedtatt for inneværende år" (Just "Matrikkellova §§ 5 og 32. Kroner eksl. mva.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Kroner"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t3_gebyrTomt750mRapportering"
                  , prompt       = Prompt "2b. Gebyr for 750 m² tomt: I rapporteringsåret" (Just "Matrikkellova §§ 5 og 32. Kroner eksl. mva.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Kroner"), ("gridXs", Number 6)])
                  }
              ]
          }

      -- Seksjon C10: Omfang søknader med beregnet samlet volum (readOnly summeringer)
      , BolkStep Bolk
          { bolkId          = "bolk_c10"
          , bolkTitle       = "C10. Antall byggesøknader, dispensasjonssøknader og deling (Hovedtall)"
          , bolkDescription = Just "Omfang av søknader mottatt og behandlet i rapporteringsåret. Totalsummer beregnes og kontrolleres automatisk."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              -- Rammesøknader (mottatt og behandlet)
              [ Question
                  { fieldId      = "t3_c10_rammesoknaderMottatt"
                  , prompt       = Prompt "C10.1b Rammesøknader: Mottatt i rapporteringsåret" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t3_c10_rammesoknaderBehandlet"
                  , prompt       = Prompt "C10.2b Rammesøknader: Behandlet/vedtatt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              -- Ett-trinns med ansvar
              , Question
                  { fieldId      = "t3_c10_ettTrinnMedAnsvarMottatt"
                  , prompt       = Prompt "C10.1c Ett-trinns m/ansvarsrett: Mottatt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t3_c10_ettTrinnMedAnsvarBehandlet"
                  , prompt       = Prompt "C10.2c Ett-trinns m/ansvarsrett: Behandlet" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              -- Ett-trinns uten ansvar
              , Question
                  { fieldId      = "t3_c10_ettTrinnUtenAnsvarMottatt"
                  , prompt       = Prompt "C10.1d Ett-trinns u/ansvarsrett: Mottatt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t3_c10_ettTrinnUtenAnsvarBehandlet"
                  , prompt       = Prompt "C10.2d Ett-trinns u/ansvarsrett: Behandlet" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              -- Dispensasjoner
              , Question
                  { fieldId      = "t3_c10_dispensasjonMottatt"
                  , prompt       = Prompt "C10.1e Dispensasjonssøknader: Mottatt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t3_c10_dispensasjonBehandlet"
                  , prompt       = Prompt "C10.2e Dispensasjonssøknader: Behandlet" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              -- Deling
              , Question
                  { fieldId      = "t3_c10_delingMottatt"
                  , prompt       = Prompt "C10.1f Opprettelse/endring (deling): Mottatt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t3_c10_delingBehandlet"
                  , prompt       = Prompt "C10.2f Opprettelse/endring (deling): Behandlet" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              -- Beregnet kontrollsum for byggesøknader i alt (b + c + d)
              , Question
                  { fieldId      = "t3_c10_byggesoknaderMottattSum"
                  , prompt       = Prompt "C10.1a Byggesøknader mottatt i alt (Sum b+c+d)" (Just "Beregnet totalsum av rammesøknader og ett-trinnssøknader.")
                  , questionType = QInteger
                  , required     = False
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("readOnly", Bool True), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t3_c10_byggesoknaderBehandletSum"
                  , prompt       = Prompt "C10.2a Byggesøknader behandlet i alt (Sum b+c+d)" (Just "Beregnet totalsum av behandlede byggesøknader.")
                  , questionType = QInteger
                  , required     = False
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("readOnly", Bool True), ("gridXs", Number 6)])
                  }
              ]
          }

      -- Seksjon C11-C16: Saksbehandlingstider og eKOSTRA
      , BolkStep Bolk
          { bolkId          = "bolk_c11_c16"
          , bolkTitle       = "C11-C16. Saksbehandlingstid og tillatelser"
          , bolkDescription = Just "Saksbehandlingstider i kalenderdager og tillatelser (IG, MB, FA)."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t3_c11_rammeTidDager"
                  , prompt       = Prompt "C11.2.2 Rammesøknader gjennomsnittlig saksbehandlingstid" (Just "Kalenderdager.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Dager"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t3_c12_ettTrinnMedAnsvarTidDager"
                  , prompt       = Prompt "C12.2.2 Ett-trinns m/ansvarsrett gjennomsnittstid" (Just "Kalenderdager.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Dager"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t3_c13_ettTrinnUtenAnsvarTidDager"
                  , prompt       = Prompt "C13.2.2 Ett-trinns u/ansvarsrett gjennomsnittstid" (Just "Kalenderdager.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Dager"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t3_c16_igBehandlet"
                  , prompt       = Prompt "C16.1a Igangsettingstillatelser (IG)" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t3_c16_mbBehandlet"
                  , prompt       = Prompt "C16.1b Midlertidige brukstillatelser (MB)" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t3_c16_faBehandlet"
                  , prompt       = Prompt "C16.1c Ferdigattester (FA)" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t3_eKostraTattIBruk"
                  , prompt       = Prompt "Har kommunen tatt i bruk eByggesak for rapportering av omfang og saksbehandlingstid (eKOSTRA)?" Nothing
                  , questionType = QBoolean
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("gridXs", Number 12)])
                  }
              ]
          }

      -- Seksjon C3-C4: Oppmåling og eierseksjonering
      , BolkStep Bolk
          { bolkId          = "bolk_c3_c4"
          , bolkTitle       = "C3-C4. Oppmålingsforretninger og eierseksjonering"
          , bolkDescription = Just "Rekvisisjoner for oppmålingsforretning og eierseksjoneringssaker."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t3_c3_oppmaalingMottatt"
                  , prompt       = Prompt "C3.1 Oppmåling: Mottatte rekvisisjoner" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t3_c3_oppmaalingBehandlet"
                  , prompt       = Prompt "C3.2 Oppmåling: Behandlede rekvisisjoner" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t3_c4_seksjoneringMottatt"
                  , prompt       = Prompt "C4.1 Seksjonering: Mottatte søknader" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t3_c4_seksjoneringBehandlet"
                  , prompt       = Prompt "C4.2 Seksjonering: Behandlede søknader" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              ]
          }

      -- Seksjon D: Resultat av søknadsbehandling og vernehensyn
      , BolkStep Bolk
          { bolkId          = "bolk_d"
          , bolkTitle       = "D. Resultat av søknadsbehandling og vernehensyn"
          , bolkDescription = Just "Innvilgelser, avslagsvedtak, tiltak i LNF-områder, strandsone og kulturminner."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t3_d1_vedtakAlt"
                  , prompt       = Prompt "D1.1a Byggesøknader vedtatt i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t3_d1_vedtakInnvilget"
                  , prompt       = Prompt "D1.1b Herav innvilget i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t3_d1_vedtakAvslag"
                  , prompt       = Prompt "D1.1c Herav avslag" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t3_d1_lnfrNyeBygg"
                  , prompt       = Prompt "D1.2 Nye byggverk i LNFR utenfor 100-metersbeltet langs saltvann" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t3_d1_strandsoneNyeBygg"
                  , prompt       = Prompt "D1.3 Nye byggverk i 100-metersbeltet langs saltvann" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t3_d1_ikkeFredetFor1850"
                  , prompt       = Prompt "D1.6 Tiltak i ikke-fredete byggverk oppført før 1850" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t3_d1_fredetByggverk"
                  , prompt       = Prompt "D1.7 Tiltak i fredete byggverk uansett oppføringsår" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              ]
          }

      -- Seksjon E: Klagesaksbehandling med inngangsspørsmål
      , BolkStep Bolk
          { bolkId          = "bolk_e"
          , bolkTitle       = "E. Klagesaksbehandling"
          , bolkDescription = Just "Klagesaker behandlet i kommunen og klager oversendt til Statsforvalteren."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t3_e0a_harKlager"
                  , prompt       = Prompt "E0a. Har kommunen mottatt eller behandlet klager i rapporteringsåret?" Nothing
                  , questionType = QBoolean
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t3_e0b_statsforvalterBehandlet"
                  , prompt       = Prompt "E0b. Har Statsforvalteren behandlet kommunale vedtak ang. klager?" Nothing
                  , questionType = QBoolean
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t3_e1_klagerKommuneAlt"
                  , prompt       = Prompt "E1.1 Klagesaker behandlet i kommunen i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t3_e0a_harKlager")
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t3_e1_klagerTattTilFoelge"
                  , prompt       = Prompt "E1.1b1 Herav klager tatt til følge" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t3_e0a_harKlager")
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t3_e1_klagerOversendtStatsforvalter"
                  , prompt       = Prompt "E1.1b2 Herav oversendt Statsforvalteren" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t3_e0a_harKlager")
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 4)])
                  }
              ]
          }

      -- Seksjon F: Tilsyn med inngangsspørsmål
      , BolkStep Bolk
          { bolkId          = "bolk_f"
          , bolkTitle       = "F. Tilsyn og ulovlighetsoppfølging"
          , bolkDescription = Just "Gjennomførte tilsyn (byggesaker og ikke-omsøkte tiltak) og tilsynskonklusjon."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t3_f0a_erUtfoertTilsyn"
                  , prompt       = Prompt "F0a. Er det utført tilsyn med tiltak i rapporteringsåret?" Nothing
                  , questionType = QBoolean
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("gridXs", Number 12)])
                  }
              , Question
                  { fieldId      = "t3_f2_tilsynAlt"
                  , prompt       = Prompt "F2.a Antall gjennomførte tilsyn i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t3_f0a_erUtfoertTilsyn")
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t3_f2_tilsynOmsoekte"
                  , prompt       = Prompt "F2.a1 Tilsyn med omsøkte tiltak" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t3_f0a_erUtfoertTilsyn")
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t3_f2_tilsynIkkeOmsoekte"
                  , prompt       = Prompt "F2.a2 Tilsyn med ikke-omsøkte tiltak" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t3_f0a_erUtfoertTilsyn")
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t3_f4_tilsynOk"
                  , prompt       = Prompt "F4.1 Tilsyn der alt var OK (ingen avvik)" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t3_f0a_erUtfoertTilsyn")
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t3_f4_tilsynAvdekketUlovlighet"
                  , prompt       = Prompt "F4.2 Tilsyn som avdekket ulovlighet/oppfølging" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t3_f0a_erUtfoertTilsyn")
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              ]
          }

      -- Seksjon G: Pålegg og sanksjoner med inngangsspørsmål
      , BolkStep Bolk
          { bolkId          = "bolk_g"
          , bolkTitle       = "G. Pålegg, sanksjoner og andre virkemidler"
          , bolkDescription = Just "Gitte pålegg (retting, opphør, stans), tvangsmulkt og overtredelsesgebyr."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t3_g0_erGittPaaleggEllerSanksjoner"
                  , prompt       = Prompt "G0. Er det gitt pålegg eller brukt sanksjoner i rapporteringsåret?" Nothing
                  , questionType = QBoolean
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("gridXs", Number 12)])
                  }
              , Question
                  { fieldId      = "t3_g1_paaleggAlt"
                  , prompt       = Prompt "G1.a Gitte pålegg i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t3_g0_erGittPaaleggEllerSanksjoner")
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t3_g3_overtredelsesgebyr"
                  , prompt       = Prompt "G3.a1 Overtredelsesgebyr (pbl § 32-8)" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t3_g0_erGittPaaleggEllerSanksjoner")
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t3_g1_paaleggRetting"
                  , prompt       = Prompt "G1.b1 Pålegg om retting (pbl § 32-3)" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t3_g0_erGittPaaleggEllerSanksjoner")
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t3_g1_paaleggOpphoer"
                  , prompt       = Prompt "G1.b2 Pålegg om opphør av bruk" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t3_g0_erGittPaaleggEllerSanksjoner")
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t3_g1_paaleggStans"
                  , prompt       = Prompt "G1.b3 Pålegg om stans av arbeid" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t3_g0_erGittPaaleggEllerSanksjoner")
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 4)])
                  }
              ]
          }

      -- Seksjon H: Merknader
      , BolkStep Bolk
          { bolkId          = "bolk_h"
          , bolkTitle       = "H. Kommentarer og merknader til skjemaet"
          , bolkDescription = Just "Åpent merknadsfelt for tilbakemelding om uklarheter eller forbedringsforslag."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t3_merknader"
                  , prompt       = Prompt "Kommentarer og merknader til utfyllingen (maks 999 tegn)" Nothing
                  , questionType = QTextArea
                  , required     = False
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("placeholder", String "Skriv eventuelle merknader her..."), ("gridXs", Number 12)])
                  }
              ]
          }

      -- Seksjon I: Grunnlag for rapportering og beregnet tidsbruk
      , BolkStep Bolk
          { bolkId          = "bolk_i"
          , bolkTitle       = "I. Grunnlag for rapportering og tidsbruk"
          , bolkDescription = Just "Elektronisk sakssystem og tidsbruk for framskaffing og utfylling."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t3_elektroniskSakssystemBrukt"
                  , prompt       = Prompt "I.1 Er elektronisk sakssystem brukt som grunnlag for store deler av rapporteringen?" Nothing
                  , questionType = QBoolean
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t3_maskinelleOpptellinger"
                  , prompt       = Prompt "I.1a Hvis ja: Er tallene resultat av maskinelle opptellinger?" Nothing
                  , questionType = QBoolean
                  , required     = True
                  , condition    = Just (IsTrue "t3_elektroniskSakssystemBrukt")
                  , annotations  = Just (KM.fromList [("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t3_timerUtfylling"
                  , prompt       = Prompt "I.2a Timer brukt til å fylle ut skjemaet" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Timer"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t3_timerFremskaffe"
                  , prompt       = Prompt "I.2b Timer brukt til å framskaffe informasjonen" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Timer"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t3_timerTotalt"
                  , prompt       = Prompt "I.2 Beregnet total tidsbruk (Sum 2a + 2b)" (Just "Automatisk beregnet total tidsbruk.")
                  , questionType = QInteger
                  , required     = False
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Timer"), ("readOnly", Bool True), ("gridXs", Number 4)])
                  }
              ]
          }
      ]
  }

-- | Trial 4: Enterprise Completeness, Cross-validation & Production Automation for 20Byggesak
-- Evolves Trial 3 by:
-- 1. Full schema completion: Del A through Del I with all validation rules and sub-totals
-- 2. Added Del D: Matrikkelføring og eiendomstildeling
-- 3. Strict cross-field validations (e.g. behandlet <= mottatt + rest)
-- 4. Multi-target live demo readiness: Altinn 3 production layout, interactive simulator & AST visualizer
trial4ByggesakDialogue :: Dialogue
trial4ByggesakDialogue = Dialogue
  { dialogueId = "trial4-byggesak"
  , title      = "20. Byggesak 2026 (Trial 4: Komplett Produksjonsversjon med Kryssvalidering)"
  , context    = Just SurveyContext
      { surveyCode   = Just "KOSTRA-20-2026"
      , organization = Just "Statistisk sentralbyrå"
      , legalNotice  = Just "Byggesaksbehandling, opprettelse og endring av eiendom, oppmåling og seksjonering 2026. Fullverdig Del A-I med kryssvalidering, automatiske summeringer og full Altinn 3 produksjonslayout."
      }
  , calculations =
      [ Calculation "t4_timerTotalt" (sumOf ["t4_timerFremskaffe", "t4_timerUtfylling"])
      ]
  , constraints  =
      [ Constraint
          { constraintId        = "t4_e1_herav"
          , constraintLeft      = sumOf ["t4_e1_klagerTattTilFoelge", "t4_e1_klagerOversendtStatsforvalter"]
          , comparison          = CmpLte
          , constraintRight     = Field "t4_e1_klagerKommuneAlt"
          , message             = "Klager tatt til følge og oversendt Statsforvalteren kan til sammen ikke overstige klagesaker i alt (E1.1)."
          , severity            = SevError
          , constraintCondition = Nothing
          , reportOn            = []
          }
      , Constraint
          { constraintId        = "t4_f_herav"
          , constraintLeft      = sumOf ["t4_f3_tilsynAvsluttetUtenAvvik", "t4_f4_tilsynAvdekketUlovlighet"]
          , comparison          = CmpLte
          , constraintRight     = Field "t4_f2_tilsynAlt"
          , message             = "Tilsyn uten avvik (F3.2) og tilsyn med ulovlighet (F4.2) kan til sammen ikke overstige antall tilsyn i alt (F2.a)."
          , severity            = SevError
          , constraintCondition = Just (IsTrue "t4_f0a_erUtfoertTilsyn")
          , reportOn            = []
          }
      ] ++
      [ Constraint
          { constraintId        = "t4_c10_" ++ kategori ++ "_behandlet"
          , constraintLeft      = Field ("t4_c10_" ++ kategori ++ "Behandlet")
          , comparison          = CmpLte
          , constraintRight     = Field ("t4_c10_" ++ kategori ++ "Mottatt")
          , message             = "Flere " ++ navn ++ " behandlet enn mottatt. Kontroller tallene, eller forklar avviket i kommentarfeltet."
          , severity            = SevWarning
          , constraintCondition = Nothing
          , reportOn            = ["t4_c10_" ++ kategori ++ "Behandlet"]
          }
      | (kategori, navn) <-
          [ ("rammesoknader", "rammesøknader")
          , ("ettTrinnMedAnsvar", "ett-trinnssøknader med ansvarsrett")
          , ("ettTrinnUtenAnsvar", "ett-trinnssøknader uten ansvarsrett")
          , ("dispensasjon", "dispensasjonssøknader")
          , ("deling", "delingssøknader")
          ]
      ]
  , steps      =
      -- Seksjon A: Kontaktinformasjon
      [ BolkStep Bolk
          { bolkId          = "bolk_a"
          , bolkTitle       = "A. Opplysninger om skjema og kontaktinformasjon"
          , bolkDescription = Just "Kontaktperson og opplysninger om kommunen for rapporteringsåret 2026."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t4_kommunenummer"
                  , prompt       = Prompt "Kommunenummer" (Just "4-sifret kommunenummer for kommunen som rapporterer.")
                  , questionType = QText
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("placeholder", String "F.eks. 0301"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t4_kommunenavn"
                  , prompt       = Prompt "Kommunens navn" Nothing
                  , questionType = QText
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("placeholder", String "Navn på kommune"), ("gridXs", Number 8)])
                  }
              , Question
                  { fieldId      = "t4_kontaktNavn"
                  , prompt       = Prompt "Kontaktperson for utfyllingen" Nothing
                  , questionType = QText
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("placeholder", String "Fornavn og etternavn"), ("gridXs", Number 12)])
                  }
              , Question
                  { fieldId      = "t4_kontaktTelefon"
                  , prompt       = Prompt "Telefonnummer" Nothing
                  , questionType = QText
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("placeholder", String "8 siffer"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t4_kontaktEpost"
                  , prompt       = Prompt "E-postadresse" Nothing
                  , questionType = QText
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("placeholder", String "navn@kommune.no"), ("gridXs", Number 6)])
                  }
              ]
          }

      -- Seksjon B: Gebyrer
      , BolkStep Bolk
          { bolkId          = "bolk_b"
          , bolkTitle       = "B. Gebyrer og finansiering av byggesaksbehandling"
          , bolkDescription = Just "Gebyrsatser og selvkostandel for byggesak og oppmåling i henhold til selvkostforskriften."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t4_gebyrEnebolig"
                  , prompt       = Prompt "B1. Gebyr for standard enebolig m/1 boenhet" (Just "Fastsatt gebyr etter gjeldende regulativ (kr eks mva).")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Kroner"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t4_gebyrOppmaaling"
                  , prompt       = Prompt "B2. Gebyr for standard oppmålingsforretning (inntil 2000 m²)" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Kroner"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t4_selvkostgradByggesak"
                  , prompt       = Prompt "B3. Beregnet selvkostgrad for byggesaksbehandling" (Just "Prosentandel av kommunens faktiske kostnader som dekkes av gebyr.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "%"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t4_selvkostgradOppmaaling"
                  , prompt       = Prompt "B4. Beregnet selvkostgrad for oppmåling og matrikkelarbeid" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "%"), ("gridXs", Number 6)])
                  }
              ]
          }

      -- Seksjon C: Saksmengde
      , BolkStep Bolk
          { bolkId          = "bolk_c_saksmengde"
          , bolkTitle       = "C10. Mottatte og behandlede byggesøknader"
          , bolkDescription = Just "Mottatt i rapporteringsåret vs. behandlet/vedtatt fordelt på søknadstyper."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t4_c10_rammesoknaderMottatt"
                  , prompt       = Prompt "C10.1b Rammesøknader: Mottatt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t4_c10_rammesoknaderBehandlet"
                  , prompt       = Prompt "C10.2b Rammesøknader: Behandlet/vedtatt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t4_c10_ettTrinnMedAnsvarMottatt"
                  , prompt       = Prompt "C10.1c Ett-trinns m/ansvarsrett: Mottatt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t4_c10_ettTrinnMedAnsvarBehandlet"
                  , prompt       = Prompt "C10.2c Ett-trinns m/ansvarsrett: Behandlet" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t4_c10_ettTrinnUtenAnsvarMottatt"
                  , prompt       = Prompt "C10.1d Ett-trinns u/ansvarsrett: Mottatt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t4_c10_ettTrinnUtenAnsvarBehandlet"
                  , prompt       = Prompt "C10.2d Ett-trinns u/ansvarsrett: Behandlet" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t4_c10_dispensasjonMottatt"
                  , prompt       = Prompt "C10.1e Dispensasjonssøknader: Mottatt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t4_c10_dispensasjonBehandlet"
                  , prompt       = Prompt "C10.2e Dispensasjonssøknader: Behandlet" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t4_c10_delingMottatt"
                  , prompt       = Prompt "C10.1f Opprettelse/endring av eiendom (deling): Mottatt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t4_c10_delingBehandlet"
                  , prompt       = Prompt "C10.2f Opprettelse/endring av eiendom (deling): Behandlet" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              ]
          }

      -- Seksjon C11-C16: Saksbehandlingstider og eKOSTRA
      , BolkStep Bolk
          { bolkId          = "bolk_c11_c16"
          , bolkTitle       = "C11-C16. Saksbehandlingstid og tillatelser"
          , bolkDescription = Just "Gjennomsnittlig saksbehandlingstid og tillatelser (IG, MB, FA)."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t4_c11_rammeTidDager"
                  , prompt       = Prompt "C11.2.2 Rammesøknader gjennomsnittlig saksbehandlingstid" (Just "Kalenderdager.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Dager"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t4_c12_ettTrinnMedAnsvarTidDager"
                  , prompt       = Prompt "C12.2.2 Ett-trinns m/ansvar snitt tid" (Just "Kalenderdager.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Dager"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t4_c13_ettTrinnUtenAnsvarTidDager"
                  , prompt       = Prompt "C13.2.2 Ett-trinns u/ansvar snitt tid" (Just "Kalenderdager.")
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Dager"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t4_c16_igBehandlet"
                  , prompt       = Prompt "C16.1a Igangsettingstillatelser (IG)" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t4_c16_mbBehandlet"
                  , prompt       = Prompt "C16.1b Midlertidige brukstillatelser (MB)" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t4_c16_faBehandlet"
                  , prompt       = Prompt "C16.1c Ferdigattester (FA)" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t4_eKostraTattIBruk"
                  , prompt       = Prompt "Har kommunen tatt i bruk eByggesak for rapportering av omfang og saksbehandlingstid (eKOSTRA)?" Nothing
                  , questionType = QBoolean
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("gridXs", Number 12)])
                  }
              ]
          }

      -- Seksjon D: Matrikkelføring og eiendom (Ny i Trial 4)
      , BolkStep Bolk
          { bolkId          = "bolk_d_matrikkel"
          , bolkTitle       = "D. Matrikkelføring og oppmåling"
          , bolkDescription = Just "Fullførte oppmålingsforretninger og tidsfrister etter matrikkelloven."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t4_d1_oppmaalingGjennomfort"
                  , prompt       = Prompt "D1. Antall oppmålingsforretninger gjennomført i marken" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t4_d2_matrikkelForingTid"
                  , prompt       = Prompt "D2. Gjennomsnittlig tidsbruk fra rekvisisjon til matrikkelføring" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Uker"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t4_d3_vinterforskriftBrukt"
                  , prompt       = Prompt "D3. Er lokal vinterforskrift for oppmåling benyttet i rapporteringsåret?" Nothing
                  , questionType = QBoolean
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("gridXs", Number 12)])
                  }
              ]
          }

      -- Seksjon E: Klagesaker
      , BolkStep Bolk
          { bolkId          = "bolk_e"
          , bolkTitle       = "E. Klagesaker etter plan- og bygningsloven"
          , bolkDescription = Just "Behandling av klager i kommunen og oversendelse til Statsforvalteren."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t4_e0a_harKlager"
                  , prompt       = Prompt "E0a. Har kommunen behandlet klagesaker etter pbl i rapporteringsåret?" Nothing
                  , questionType = QBoolean
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("gridXs", Number 12)])
                  }
              , Question
                  { fieldId      = "t4_e1_klagerKommuneAlt"
                  , prompt       = Prompt "E1.1 Klagesaker behandlet i kommunen i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t4_e0a_harKlager")
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t4_e1_klagerTattTilFoelge"
                  , prompt       = Prompt "E1.1b1 Herav klager tatt til følge" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t4_e0a_harKlager")
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t4_e1_klagerOversendtStatsforvalter"
                  , prompt       = Prompt "E1.1b2 Herav oversendt Statsforvalteren" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t4_e0a_harKlager")
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 4)])
                  }
              ]
          }

      -- Seksjon F: Tilsyn
      , BolkStep Bolk
          { bolkId          = "bolk_f"
          , bolkTitle       = "F. Tilsyn og ulovlighetsoppfølging"
          , bolkDescription = Just "Gjennomførte tilsyn (byggesaker og ikke-omsøkte tiltak) og tilsynskonklusjon."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t4_f0a_erUtfoertTilsyn"
                  , prompt       = Prompt "F0a. Er det utført tilsyn med tiltak i rapporteringsåret?" Nothing
                  , questionType = QBoolean
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("gridXs", Number 12)])
                  }
              , Question
                  { fieldId      = "t4_f2_tilsynAlt"
                  , prompt       = Prompt "F2.a Antall gjennomførte tilsyn i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t4_f0a_erUtfoertTilsyn")
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t4_f3_tilsynAvsluttetUtenAvvik"
                  , prompt       = Prompt "F3.2 Antall tilsyn avsluttet uten avvik/ulovlighet" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t4_f0a_erUtfoertTilsyn")
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t4_f4_tilsynAvdekketUlovlighet"
                  , prompt       = Prompt "F4.2 Antall tilsyn som avdekket ulovlighet som krever oppfølging" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t4_f0a_erUtfoertTilsyn")
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 4)])
                  }
              ]
          }

      -- Seksjon G: Pålegg og sanksjoner
      , BolkStep Bolk
          { bolkId          = "bolk_g"
          , bolkTitle       = "G. Pålegg, sanksjoner og andre virkemidler"
          , bolkDescription = Just "Gitte pålegg (retting, opphør, stans), tvangsmulkt, overtredelsesgebyr og anmeldelser."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t4_g0_erGittPaaleggEllerSanksjoner"
                  , prompt       = Prompt "G0. Er det gitt pålegg, brukt sanksjoner eller andre virkemidler i rapporteringsåret?" Nothing
                  , questionType = QBoolean
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("gridXs", Number 12)])
                  }
              , Question
                  { fieldId      = "t4_g1_paaleggAlt"
                  , prompt       = Prompt "G1.a Gitte pålegg i alt" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t4_g0_erGittPaaleggEllerSanksjoner")
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t4_g3_overtredelsesgebyr"
                  , prompt       = Prompt "G3.a1 Overtredelsesgebyr (pbl § 32-8)" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t4_g0_erGittPaaleggEllerSanksjoner")
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t4_g1_paaleggRetting"
                  , prompt       = Prompt "G1.b1 Pålegg om retting (pbl § 32-3)" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t4_g0_erGittPaaleggEllerSanksjoner")
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t4_g1_paaleggOpphoer"
                  , prompt       = Prompt "G1.b2 Pålegg om opphør av bruk" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t4_g0_erGittPaaleggEllerSanksjoner")
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t4_g1_paaleggStans"
                  , prompt       = Prompt "G1.b3 Pålegg om stans av arbeid" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Just (IsTrue "t4_g0_erGittPaaleggEllerSanksjoner")
                  , annotations  = Just (KM.fromList [("unit", String "Antall"), ("gridXs", Number 4)])
                  }
              ]
          }

      -- Seksjon H: Merknader
      , BolkStep Bolk
          { bolkId          = "bolk_h"
          , bolkTitle       = "H. Kommentarer og merknader til skjemaet"
          , bolkDescription = Just "Åpent merknadsfelt for tilbakemelding om uklarheter eller forbedringsforslag."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t4_merknader"
                  , prompt       = Prompt "Kommentarer og merknader til utfyllingen (maks 999 tegn)" Nothing
                  , questionType = QTextArea
                  , required     = False
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("placeholder", String "Skriv eventuelle merknader her..."), ("gridXs", Number 12)])
                  }
              ]
          }

      -- Seksjon I: Grunnlag for rapportering og beregnet tidsbruk
      , BolkStep Bolk
          { bolkId          = "bolk_i"
          , bolkTitle       = "I. Grunnlag for rapportering og tidsbruk"
          , bolkDescription = Just "Elektronisk sakssystem og tidsbruk for framskaffing og utfylling."
          , bolkCondition   = Nothing
          , bolkQuestions   =
              [ Question
                  { fieldId      = "t4_elektroniskSakssystemBrukt"
                  , prompt       = Prompt "I.1 Er elektronisk sakssystem brukt som grunnlag for store deler av rapporteringen?" Nothing
                  , questionType = QBoolean
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t4_maskinelleOpptellinger"
                  , prompt       = Prompt "I.1a Hvis ja: Er tallene resultat av maskinelle opptellinger?" Nothing
                  , questionType = QBoolean
                  , required     = True
                  , condition    = Just (IsTrue "t4_elektroniskSakssystemBrukt")
                  , annotations  = Just (KM.fromList [("gridXs", Number 6)])
                  }
              , Question
                  { fieldId      = "t4_timerUtfylling"
                  , prompt       = Prompt "I.2a Timer brukt til å fylle ut skjemaet" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Timer"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t4_timerFremskaffe"
                  , prompt       = Prompt "I.2b Timer brukt til å framskaffe informasjonen" Nothing
                  , questionType = QInteger
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Timer"), ("gridXs", Number 4)])
                  }
              , Question
                  { fieldId      = "t4_timerTotalt"
                  , prompt       = Prompt "I.2 Beregnet total tidsbruk (Sum 2a + 2b)" (Just "Automatisk beregnet total tidsbruk.")
                  , questionType = QInteger
                  , required     = False
                  , condition    = Nothing
                  , annotations  = Just (KM.fromList [("unit", String "Timer"), ("readOnly", Bool True), ("gridXs", Number 4)])
                  }
              ]
          }
      ]
  }





