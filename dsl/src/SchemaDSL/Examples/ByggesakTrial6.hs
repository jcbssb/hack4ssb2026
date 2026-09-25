{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}

-- | Trial 6: starts as a copy of Trial 5 (20Byggesak rebuilt from the filled-in PDF,
-- research/20byggesak-pdf-tekst.txt, see plans/byggesak-trial5-plan.md) and is
-- injected onto the untouched SSB base app (Altinn repo commit b0481ec) instead of
-- on top of earlier trials.
--
-- Evolves Trials 1-4 by covering every table in the form with the matrix builder,
-- and by modelling the form's own rules: dark grey cells are calculations,
-- light grey cells open on "Ja" or on numbers above 0, and "herav" cells never
-- exceed their totals. Calculations marked "verified" reproduce the values printed
-- in the filled-in PDF.
module SchemaDSL.Examples.ByggesakTrial6
  ( trial6ByggesakDialogue
  , trial6Matrices
  ) where

import Data.Aeson (Value(..))
import Data.Char (toUpper)
import Data.Aeson.Key (Key)
import qualified Data.Aeson.KeyMap as KM
import SchemaDSL.Types
import SchemaDSL.Builders

trial6ByggesakDialogue :: Dialogue
trial6ByggesakDialogue = Dialogue
  { dialogueId   = "trial6-byggesak"
  , title        = "20. Byggesak 2026 (Trial 6: Byggesak på uberørt SSB-app)"
  , context      = Just SurveyContext
      { formName     = Just "20Byggesak. Byggesaksbehandling, opprettelse og endring av eiendom, oppmåling og seksjonering 2026"
      , surveyCode   = Just "KOSTRA-20-2026"
      , organization = Just "Statistisk sentralbyrå"
      , legalNotice  = Just "Byggesaksbehandling, opprettelse og endring av eiendom, oppmåling og seksjonering 2026. Celler med beregninger fylles ikke ut. Celler åpnes når det er svart Ja på et inngangsspørsmål eller fylt inn et tall større enn 0."
      }
  , calculations = concat calcs
  , constraints  = concat cons
  , steps        = stepList
  }
  where
    (stepList, calcs, cons) = unzip3 bolker

-- | All matrices, exposed for tests that check calculations against the PDF
trial6Matrices :: [Matrix]
trial6Matrices =
  [ bGebyr, c10, c11, c12, c13, c14, c15, c16, c2, c3, c4, d1, d2
  , e1, e2, f1, f2, f3, g1, g2, g3, g4 ]

type BolkParts = (Step, [Calculation], [Constraint])

bolker :: [BolkParts]
bolker =
  [ bolk "bolk_a" "A. Opplysninger om skjema og kontaktinformasjon"
      (Just "Utfylling av kontaktinformasjon om kommunen og ansvarlig for rapporteringen. Spørsmålene er nærmere forklart i veiledningen.")
      Nothing
      [ questionsOnly
          [ field "t6_kommunenummer" "Kommunenummer" (Just "4-sifret kommunenummer.") QText True Nothing [("placeholder", String "F.eks. 0301"), ("gridXs", Number 6)]
          , field "t6_kommunensNavn" "Kommunens navn" Nothing QText True Nothing [("placeholder", String "F.eks. Oslo"), ("gridXs", Number 6)]
          , field "t6_navnSkjemaansvarlig" "Navn skjemaansvarlig" (Just "Fullt navn på kontaktperson for rapporteringen.") QText True Nothing [("gridXs", Number 12)]
          , field "t6_telefonnummer" "Telefonnummer" Nothing QText True Nothing [("placeholder", String "8 siffer"), ("gridXs", Number 6)]
          , field "t6_epostSkjemaansvarlig" "E-post skjemaansvarlig" (Just "Offisiell e-postadresse i kommunen.") QText True Nothing [("placeholder", String "navn@kommune.no"), ("gridXs", Number 6)]
          ]
      ]
  , bolk "bolk_b" "B. Gebyrer" (Just "Gebyrer i kroner eksklusive mva.") Nothing [ matrix bGebyr ]
  , bolk "bolk_c10" "C10. Antall byggesøknader, dispensasjonssøknader og søknader om opprettelse og endring av grunneiendom. Hovedtall"
      (Just "Du må fylle ut ALLE cellene i denne bolken for å kunne sende inn skjema. Tallene overføres til kolonne a i C11-C13, C15 og C2.")
      Nothing [ matrix c10 ]
  , bolk "bolk_c11" "C11. Rammesøknader. Antall og saksbehandlingstid" Nothing Nothing [ matrix c11 ]
  , bolk "bolk_c12" "C12. Ett-trinnssøknader MED ansvarsrett. Antall og saksbehandlingstid" Nothing Nothing [ matrix c12 ]
  , bolk "bolk_c13" "C13. Ett-trinnssøknader UTEN ansvarsrett. Antall og saksbehandlingstid" Nothing Nothing [ matrix c13 ]
  , bolk "bolk_c14" "C14. Til summeringskontroll: Byggesøknader i alt og fordelt på 3- og 12-ukers frister"
      (Just "Feltene oppdateres kontinuerlig fra C11, C12 og C13 og er sperret for skriving. Feil i summene rettes i C11-C13.")
      Nothing [ matrix c14 ]
  , bolk "bolk_c15" "C15. Dispensasjonssøknader. Antall og saksbehandlingstid" Nothing Nothing [ matrix c15 ]
  , bolk "bolk_c16" "C16. Igangsettingstillatelser, midlertidige brukstillatelser og ferdigattester. Antall og saksbehandlingstid" Nothing Nothing [ matrix c16 ]
  , bolk "bolk_c2" "C2. Oppretting og endring av eiendom (deling)" Nothing Nothing [ matrix c2 ]
  , bolk "bolk_c_ekostra" "C11-C2. Om eKOSTRA"
      (Just "Digitalisering av kommunale fagsystemer gjennom eByggesak danner grunnlaget for eKOSTRA, en tidsbesparende automatisering av kommunens rapportering til SSB.")
      Nothing
      [ questionsOnly (eKostra "t6_c_eByggesak" "Har kommunen tatt i bruk eByggesak for rapportering av omfang og saksbehandlingstid for byggesøknader, dispensasjonssøknader og søknader om opprettelse/endring av grunneiendom fra 1.1.2024?") ]
  , bolk "bolk_c3" "C3. Oppmålingsforretninger. Antall og saksbehandlingstid" Nothing Nothing [ matrix c3 ]
  , bolk "bolk_c4" "C4. Eierseksjoneringssaker. Antall og saksbehandlingstid" Nothing Nothing [ matrix c4 ]
  , bolk "bolk_d1" "D1. Resultat av byggesaksbehandling i alt og i særskilt område" (Just "Antall vedtak.") Nothing [ matrix d1 ]
  , bolk "bolk_d2" "D2. Resultat av behandling av søknader om opprettelse og endring av eiendom, matrikuleringer uten fullført oppmålingsforretning (MUF) og seksjoneringer"
      (Just "Antall vedtak i rapporteringsåret.") Nothing [ matrix d2 ]
  , bolk "bolk_d_ekostra" "D1-D2. Om eKOSTRA" Nothing Nothing
      [ questionsOnly (eKostra "t6_d_eByggesak" "Har kommunen tatt i bruk eByggesak for rapportering om resultat av saksbehandling for byggesøknader og andre søknader fra 1.1.2024?") ]
  , bolk "bolk_e0" "E. Klagesaksbehandling: Omfang, resultat og saksbehandlingstid" Nothing Nothing
      [ questionsOnly
          [ field "t6_e0a_klagerMottattEllerBehandlet" "E0a. Har kommunen mottatt eller behandlet klager i rapporteringsåret?" Nothing QBoolean True Nothing []
          , field "t6_e0b_statsforvalterBehandlet" "E0b. Har Statsforvalteren behandlet kommunale vedtak angående klager fra kommunen i rapporteringsåret?" Nothing QBoolean True Nothing []
          ]
      ]
  , bolk "bolk_e1" "E1. Antall klagesaker behandlet i kommunen" Nothing (Just (IsTrue "t6_e0a_klagerMottattEllerBehandlet")) [ matrix e1 ]
  , bolk "bolk_e2" "E2. Klagesaker oversendt fra kommunen og behandlet av Statsforvalteren" Nothing (Just (IsTrue "t6_e0b_statsforvalterBehandlet")) [ matrix e2 ]
  , bolk "bolk_f0" "F. Utøvelse av tilsyn ved tiltak (i byggesaker)" Nothing Nothing
      [ questionsOnly [ field "t6_f0a_erUtfoertTilsyn" "F0a. Er det utført tilsyn med tiltak i rapporteringsåret?" Nothing QBoolean True Nothing [] ] ]
  , bolk "bolk_f1" "F1. Antall tiltak som det er ført tilsyn med" Nothing tilsyn [ matrix f1 ]
  , bolk "bolk_f2" "F2. Antall tilsyn og ulovlighetsoppfølginger" Nothing tilsyn [ matrix f2 ]
  , bolk "bolk_f3" "F3. Antall utførte tilsyn fordelt på tema" Nothing tilsyn [ matrix f3 ]
  , bolk "bolk_f4" "F4. Konklusjon av tilsynet" Nothing tilsyn [ f4 ]
  , bolk "bolk_g0" "G. Pålegg, sanksjoner og andre virkemidler etter tilsyn og ulovlighetsoppfølging" Nothing Nothing
      [ questionsOnly [ field "t6_g0_erGittPaaleggEllerSanksjoner" "G0. Er det gitt pålegg, brukt sanksjoner eller andre virkemidler i rapporteringsåret?" Nothing QBoolean True Nothing [] ] ]
  , bolk "bolk_g1" "G1. Antall pålegg gitt i rapporteringsåret" Nothing paalegg [ matrix g1 ]
  , bolk "bolk_g2" "G2. Antall oppfølginger av gitte pålegg" Nothing paalegg [ matrix g2 ]
  , bolk "bolk_g3" "G3. Antall sanksjoner brukt" Nothing paalegg [ matrix g3 ]
  , bolk "bolk_g4" "G4. Antall andre virkemidler nyttet ved manglende overholdelse av plan- og bygningslovgivningen" Nothing paalegg [ matrix g4 ]
  , bolk "bolk_h" "H. Kommentarer og merknader til skjemaet"
      (Just "Åpent felt til kommentarer om ting som er uklare, type opplysninger som innhentes, omfang, utforming av skjemaet o.l.")
      Nothing
      [ questionsOnly [ field "t6_merknader" "Kommentarer og merknader (maks. 999 tegn)" Nothing QTextArea False Nothing [("maxLength", Number 999), ("gridXs", Number 12)] ] ]
  , bolk "bolk_i" "I. Grunnlag for rapportering og tid for utfylling av skjemaet" Nothing Nothing [ bolkI ]
  ]
  where
    tilsyn  = Just (IsTrue "t6_f0a_erUtfoertTilsyn")
    paalegg = Just (IsTrue "t6_g0_erGittPaaleggEllerSanksjoner")

bolk :: String -> String -> Maybe String -> Maybe Predicate -> [FormParts] -> BolkParts
bolk bid ttl desc cond parts =
  let (qs, calcs, cons) = mconcat parts
  in (BolkStep (Bolk bid ttl desc cond qs), calcs, cons)

field :: FieldId -> String -> Maybe String -> QuestionType -> Bool -> Maybe Predicate -> [(Key, Value)] -> Question
field fid lbl help qt req cond anns = Question
  { fieldId      = fid
  , prompt       = Prompt lbl help
  , questionType = qt
  , required     = req
  , condition    = cond
  , annotations  = if null anns then Nothing else Just (KM.fromList anns)
  }

eKostra :: FieldId -> String -> [Question]
eKostra fid lbl =
  [ field fid lbl Nothing QBoolean False Nothing []
  , field (fid ++ "Kommentar") "Eventuelle kommentarer" Nothing QTextArea False Nothing [("gridXs", Number 12)]
  ]

-- ---------------------------------------------------------------------------
-- Shared shapes

gtZero :: Expr -> Predicate
gtZero e = Compare e CmpGt (Const 0)

-- | Averages and other non-summable rows
avgRow :: String -> String -> [String] -> MatrixRow
avgRow key lbl cols = (matrixRow key lbl) { rowCols = Just cols, rowSummable = False }

-- | Rows 1, 1.1, 2, 2.1, 2.2 shared by C11-C13, C15, C2 and C3. Row 1.1 opens when
-- row 1 has cases; rows 2.1 and 2.2 open when row 2 has cases in the same column.
caseRows :: String -> [String] -> [MatrixRow]
caseRows noun avgCols =
  [ matrixRow "1" ("1. Antall " ++ noun ++ " mottatt i rapporteringsåret")
  , (matrixRow "1.1" ("1.1 Herav antall mangelfulle " ++ noun ++ " mottatt hvor det ble bedt om tilleggsinformasjon"))
      { rowCols = Just ["a"], rowCondition = Just (\cell _ -> gtZero (cell "1" "a")) }
  , matrixRow "2" ("2. Antall " ++ noun ++ " behandlet i rapporteringsåret")
  , (matrixRow "2.1" ("2.1 Herav antall " ++ noun ++ " med saksbehandlingstid over lovpålagt frist"))
      { rowCondition = Just (\cell col -> gtZero (cell "2" col)) }
  , (avgRow "2.2" "2.2 Gjennomsnittlig saksbehandlingstid, kalenderdager" avgCols)
      { rowCondition = Just (\cell col -> gtZero (cell "2" col)) }
  ]

caseRules :: String -> [MatrixRule]
caseRules noun =
  [ partsAtMost "mangelfulle" EachColumn ["1.1"] "1" ("Mangelfulle " ++ noun ++ " kan ikke overstige mottatte")
  , partsAtMost "overFrist" EachColumn ["2.1"] "2" (capitalize noun ++ " over frist kan ikke overstige behandlede")
  ]
  where
    capitalize (x:xs) = toUpper x : xs
    capitalize []     = []

-- | Column a copied from C10 for rows 1 (mottatt) and 2 (behandlet)
fromC10 :: String -> [((String, String), Expr)]
fromC10 c10col =
  [ (("1", "a"), Field (cellId "t6_c10" "1" c10col))
  , (("2", "a"), Field (cellId "t6_c10" "2" c10col))
  ]

-- | Columns of C12, C13, C2 and C14: plan / not plan split with 3- and 12-week deadlines.
-- Verified: b2 = b - b1, c = a - b, d = c + b2 reproduce every printed row of C12.
deadlineCols :: String -> [MatrixCol]
deadlineCols what =
  [ matrixCol "a" ("a. " ++ what ++ " i alt")
  , matrixCol "b" "b. I samsvar med plan, i alt"
  , matrixCol "b1" "b1. I samsvar med plan, herav med 3 ukers frist"
  , (matrixCol "b2" "b2. I samsvar med plan, herav med 12 ukers frist") { colFormula = Just (\c -> Sub (c "b") (c "b1")) }
  , (matrixCol "c" "c. Søknader som ikke er i samsvar med plan") { colFormula = Just (\c -> Sub (c "a") (c "b")) }
  , (matrixCol "d" "d. Søknader med 12 ukers frist i alt") { colFormula = Just (\c -> Add [c "c", c "b2"]) }
  ]

deadlineMatrix :: String -> String -> String -> Matrix
deadlineMatrix prefix what c10col = Matrix
  { matrixPrefix = prefix
  , matrixRows = caseRows "søknader" ["b1", "b2", "c"]
  , matrixCols = deadlineCols what
  , matrixRules =
      [ partsAtMost "samsvar" EachRow ["b"] "a" "Søknader i samsvar med plan kan ikke overstige søknader i alt"
      , partsAtMost "treUker" EachRow ["b1"] "b" "Søknader med 3 ukers frist kan ikke overstige søknader i samsvar med plan"
      ] ++ caseRules "søknader"
  , matrixCellFormulas = fromC10 c10col
  }

-- | "Herav" columns b (existing) and c (new) of an "i alt" column a, used in F and G
existingNewCols :: String -> [MatrixCol]
existingNewCols what =
  [ matrixCol "a" ("a. " ++ what ++ " i alt")
  , matrixCol "b" ("b. Herav " ++ what ++ " med eksisterende tiltak")
  , matrixCol "c" ("c. Herav " ++ what ++ " med nye tiltak")
  ]

existingNewRule :: String -> MatrixRule
existingNewRule what = partsAtMost "herav" EachRow ["b", "c"] "a" (what ++ " med eksisterende og nye tiltak kan ikke overstige i alt")

-- ---------------------------------------------------------------------------
-- B, C

bGebyr :: Matrix
bGebyr = Matrix
  { matrixPrefix = "t6_b"
  , matrixRows =
      [ (matrixRow "1" "1. Byggesaksgebyr (ekskl. mva.) for oppføring av enebolig (ny boligbygning med en boenhet), jf. PBL § 20-1 a") { rowRequired = ["a", "b"] }
      , (matrixRow "2" "2. Gebyr for opprettelse av grunneiendom på 750 m2, jf. matrikkellova §§ 5 og 32") { rowRequired = ["a", "b"] }
      ]
  , matrixCols =
      [ matrixCol "a" "a. Gebyr vedtatt for inneværende år (kroner)"
      , matrixCol "b" "b. Gebyr i rapporteringsåret (kroner)"
      ]
  , matrixRules = []
  , matrixCellFormulas = []
  }

-- | Verified: C10 b-f equal column a of C11, C12, C13, C15 and C2 in the PDF
c10 :: Matrix
c10 = Matrix
  { matrixPrefix = "t6_c10"
  , matrixRows =
      [ (matrixRow "1" "1. Antall søknader mottatt i rapporteringsåret") { rowRequired = entered }
      , (matrixRow "2" "2. Antall søknader behandlet/vedtatt i rapporteringsåret") { rowRequired = entered }
      ]
  , matrixCols =
      [ (matrixCol "a" "a. I alt (sum b+c+d)") { colFormula = Just (sumOfKeys ["b", "c", "d"]) }
      , matrixCol "b" "b. Herav rammesøknader"
      , matrixCol "c" "c. Herav ett-trinnssøknader med ansvarsrett"
      , matrixCol "d" "d. Herav ett-trinnssøknader uten ansvarsrett"
      , matrixCol "e" "e. Dispensasjonssøknader"
      , matrixCol "f" "f. Opprettelse/endring av eiendom (deling)"
      ]
  , matrixRules =
      [ MatrixRule "behandlet" EachColumn ($ "2") CmpLte ($ "1") SevWarning
          "Flere søknader behandlet enn mottatt. Kontroller tallene, eller forklar avviket i kommentarfeltet"
      ]
  , matrixCellFormulas = []
  }
  where
    entered = ["b", "c", "d", "e", "f"]

-- | Verified: c = a - b (100 - 44 = 56, 2000 - 444 = 1556)
c11 :: Matrix
c11 = Matrix
  { matrixPrefix = "t6_c11"
  , matrixRows = caseRows "søknader" ["a"]
  , matrixCols =
      [ matrixCol "a" "a. Rammesøknader i alt"
      , matrixCol "b" "b. Herav søknader i samsvar med plan"
      , (matrixCol "c" "c. Herav søknader som ikke er i samsvar med plan") { colFormula = Just (\c -> Sub (c "a") (c "b")) }
      ]
  , matrixRules =
      atLeastZero "ikkeNegativ" EachRow "c" "Søknader i samsvar med plan kan ikke overstige søknader i alt"
      : caseRules "søknader"
  , matrixCellFormulas = fromC10 "b"
  }

c12, c13, c2 :: Matrix
c12 = deadlineMatrix "t6_c12" "Ett-trinnssøknader med ansvarsrett" "c"
c13 = deadlineMatrix "t6_c13" "Ett-trinnssøknader uten ansvarsrett" "d"
c2  = deadlineMatrix "t6_c2" "Søknader om opprettelse/endring av eiendommer" "f"

-- | Sum of C11-C13. Verified for b, b1, c and row 2.1 a (the PDF prints 12 in
-- rows 1-2 of column a, which matches no sum and is treated as a sample error).
-- The weighted average row 2.2 is left out.
c14 :: Matrix
c14 = Matrix
  { matrixPrefix = "t6_c14"
  , matrixRows = take 4 (caseRows "søknader" [])
  , matrixCols = deadlineCols "Byggesøknader"
  , matrixRules = []
  , matrixCellFormulas =
      [ ((r, c), Add [ Field (cellId (matrixPrefix m) r c) | m <- [c11, c12, c13], (r, c) `elem` matrixCells m ])
      | (r, c) <- matrixCells c14Shape
      , c `elem` ["a", "b", "b1", "c"]
      ]
  }
  where
    c14Shape = Matrix "t6_c14" (take 4 (caseRows "søknader" [])) (deadlineCols "Byggesøknader") [] []

-- | Verified: c = a - b (23 - 233 = -210)
c15 :: Matrix
c15 = Matrix
  { matrixPrefix = "t6_c15"
  , matrixRows = caseRows "søknader" ["a"]
  , matrixCols =
      [ matrixCol "a" "a. Dispensasjonssøknader i alt"
      , matrixCol "b" "b. Herav dispensasjon fra plan"
      , (matrixCol "c" "c. Herav dispensasjon fra byggesaksbestemmelser") { colFormula = Just (\c -> Sub (c "a") (c "b")) }
      ]
  , matrixRules =
      atLeastZero "ikkeNegativ" EachRow "c" "Dispensasjon fra plan kan ikke overstige dispensasjonssøknader i alt"
      : caseRules "søknader"
  , matrixCellFormulas = fromC10 "e"
  }

c16 :: Matrix
c16 = Matrix
  { matrixPrefix = "t6_c16"
  , matrixRows =
      [ matrixRow "1" "1. Antall søknader behandlet i rapporteringsåret"
      , (avgRow "2" "2. Gjennomsnittlig saksbehandlingstid, kalenderdager" ["a", "b", "c"])
          { rowCondition = Just (\cell col -> gtZero (cell "1" col)) }
      ]
  , matrixCols =
      [ matrixCol "a" "a. Igangsettingstillatelser"
      , matrixCol "b" "b. Midlertidige brukstillatelser"
      , matrixCol "c" "c. Ferdigattester"
      ]
  , matrixRules = []
  , matrixCellFormulas = []
  }

-- | Verified: c = a - b (897 - 89 = 808, 98 - 89 = 9)
c3 :: Matrix
c3 = Matrix
  { matrixPrefix = "t6_c3"
  , matrixRows = caseRows "rekvisisjoner" ["a"]
  , matrixCols =
      [ matrixCol "a" "a. Rekvisisjoner i alt"
      , matrixCol "b" "b. Herav rekvisisjoner for søknadspliktige tiltak etter plan- og bygningsloven"
      , (matrixCol "c" "c. Herav rekvisisjoner for saker etter matrikkelloven som ikke krever tillatelse etter plan- og bygningsloven")
          { colFormula = Just (\c -> Sub (c "a") (c "b")) }
      ]
  , matrixRules =
      atLeastZero "ikkeNegativ" EachRow "c" "Rekvisisjoner for søknadspliktige tiltak kan ikke overstige rekvisisjoner i alt"
      : caseRules "rekvisisjoner"
  , matrixCellFormulas = []
  }

-- | Verified: a = b + c + d (435 + 564 + 65 = 1064, and 7767 in row 1.1).
-- Unlike C11-C13, row 1.1 has all columns.
c4 :: Matrix
c4 = Matrix
  { matrixPrefix = "t6_c4"
  , matrixRows = [ if rowKey r == "1.1" then r { rowCols = Nothing } else r | r <- caseRows "søknader" ["a", "b", "c", "d"] ]
  , matrixCols =
      [ (matrixCol "a" "a. Seksjoneringsvirksomhet i alt") { colFormula = Just (sumOfKeys ["b", "c", "d"]) }
      , matrixCol "b" "b. Seksjoneringer"
      , matrixCol "c" "c. Reseksjoneringer"
      , matrixCol "d" "d. Opphevelse av seksjoneringer"
      ]
  , matrixRules = caseRules "søknader"
  , matrixCellFormulas = []
  }

-- ---------------------------------------------------------------------------
-- D

decisionCols :: [MatrixCol]
decisionCols =
  [ matrixCol "a" "a. Vedtak i alt"
  , matrixCol "b" "b. Herav innvilget i alt"
  , matrixCol "b1" "b1. Herav innvilget gjennom vedtak i samsvar med plan"
  , matrixCol "b2" "b2. Herav innvilget gjennom vedtak om dispensasjon fra plan"
  , matrixCol "c" "c. Herav vedtak om avslag"
  ]

decisionRules :: [MatrixRule]
decisionRules =
  [ partsAtMost "innvilgetAvslag" EachRow ["b", "c"] "a" "Innvilget og avslag kan til sammen ikke overstige vedtak i alt"
  , partsAtMost "innvilget" EachRow ["b1", "b2"] "b" "Innvilget i samsvar med plan og ved dispensasjon kan ikke overstige innvilget i alt"
  ]

-- | Verified for columns a and b: 1b = 2 + 2a + 3 + 5 + 6 + 7 (the area restriction rows)
d1 :: Matrix
d1 = Matrix
  { matrixPrefix = "t6_d1"
  , matrixRows =
      [ matrixRow "1a" "1a. Antall byggesøknader i alt vedtatt i rapporteringsåret"
      , (matrixRow "1b" "1b. Antall vedtak i alt for søknader i områder med restriksjoner (sum av spørsmålene nedenfor)")
          { rowFormula = Just (sumOfKeys ["2", "2a", "3", "5", "6", "7"]) }
      , matrixRow "2" "2. Antall vedtak som gjaldt nye byggverk i LNF/LNFR-områder utenfor 100-metersbeltet langs saltvann"
      , matrixRow "2a" "2a. Herav antall vedtak i LNF/LNFR-områder med byggeforbud langs ferskvann i kommuneplanen, jf. PBL-08 § 1-8"
      , matrixRow "3" "3. Antall vedtak som gjaldt nye byggverk i 100-metersbeltet langs saltvann"
      , matrixRow "4" "4. Antall dispensasjonsvedtak i alt angående universell utforming og tilgjengelighet"
      , matrixRow "4a" "4a. Herav antall vedtak med hjemmel i pbl § 19-1 (generelle dispensasjonsbestemmelse)"
      , matrixRow "4b" "4b. Herav antall vedtak med hjemmel i pbl § 31-2, siste ledd (unntak vedrørende eksisterende byggverk)"
      , matrixRow "5" "5. Antall vedtak om tiltak i områder med bevaringsstatus i reguleringsplan"
      , matrixRow "6" "6. Antall vedtak som gjaldt tiltak i ikke-fredete byggverk oppført før 1850"
      , matrixRow "7" "7. Antall vedtak som gjaldt tiltak i fredete byggverk uansett oppføringsår"
      ]
  , matrixCols = decisionCols
  , matrixRules = decisionRules ++
      [ partsAtMost "lnfFerskvann" EachColumn ["2a"] "2" "Vedtak langs ferskvann kan ikke overstige vedtak i LNF/LNFR-områder"
      , partsAtMost "universell" EachColumn ["4a", "4b"] "4" "Vedtak etter § 19-1 og § 31-2 kan ikke overstige dispensasjonsvedtak i alt"
      ]
  , matrixCellFormulas = []
  }

d2 :: Matrix
d2 = Matrix
  { matrixPrefix = "t6_d2"
  , matrixRows =
      [ matrixRow "1" "1. Søknader om opprettelse og endring av eiendom (pbl § 20-1 bokstav m)"
      , matrixRow "2" "2. Søknader om matrikulering uten fullført oppmålingsforretning (MUF) (matrikkelloven § 6 andre ledd)"
      , matrixRow "3" "3. Søknader om seksjonering, reseksjonering og opphevelse av seksjonering (eierseksjonsloven § 4 bokstavene j og k)"
      ]
  , matrixCols = decisionCols
  , matrixRules = decisionRules
  , matrixCellFormulas = []
  }

-- ---------------------------------------------------------------------------
-- E

-- | Row structure shared by E1 and E2. Verified: 1 = 2 + 3 + 4 and 3 = 3a + 3b + 3c + 3d.
appealRows :: [MatrixRow]
appealRows =
  [ (matrixRow "1" "1. Klagesaker i alt") { rowFormula = Just (sumOfKeys ["2", "3", "4"]) }
  , matrixRow "2" "2. Klagesaker på gebyrer"
  , (matrixRow "3" "3. Klagesaker på utfall av søknadsbehandling") { rowFormula = Just (sumOfKeys ["3a", "3b", "3c", "3d"]) }
  , matrixRow "3a" "3a. Klagesaker på byggesøknader"
  , matrixRow "3b" "3b. Klagesaker på søknader om opprettelse og endring av eiendom"
  , matrixRow "3c" "3c. Klagesaker på oppmålingssaker"
  , matrixRow "3d" "3d. Klagesaker på seksjoneringssaker"
  , matrixRow "4" "4. Klagesaker i forbindelse med tilsyn og ulovlighetsoppfølging"
  ]

e1 :: Matrix
e1 = Matrix
  { matrixPrefix = "t6_e1"
  , matrixRows = appealRows
  , matrixCols =
      [ matrixCol "b" "b. Antall vedtak i alt"
      , matrixCol "b1" "b1. Herav klagesaker tatt til følge av kommunen"
      , matrixCol "b2" "b2. Herav klagesaker oversendt Statsforvalteren"
      , (matrixCol "c" "c. Gjennomsnittlig saksbehandlingstid i kommunen, kalenderdager") { colSummable = False }
      , matrixCol "d" "d. Antall klagesaker med behandlingstid over lovpålagt frist"
      ]
  , matrixRules =
      [ partsAtMost "herav" EachRow ["b1", "b2"] "b" "Klager tatt til følge og oversendt Statsforvalteren kan ikke overstige vedtak i alt"
      , partsAtMost "overFrist" EachRow ["d"] "b" "Klagesaker over frist kan ikke overstige vedtak i alt"
      ]
  , matrixCellFormulas = []
  }

e2 :: Matrix
e2 = Matrix
  { matrixPrefix = "t6_e2"
  , matrixRows = appealRows
  , matrixCols =
      [ matrixCol "e" "e. Kommunale vedtak Statsforvalteren har fattet vedtak om, i alt"
      , matrixCol "e1" "e1. Kommunale vedtak som ble STADFESTET"
      , matrixCol "e2" "e2. Kommunale vedtak som IKKE BLE OPPRETTHOLDT"
      , matrixCol "e2a" "e2a. Herav vedtak som ble OMGJORT"
      , matrixCol "e2b" "e2b. Herav vedtak som ble OPPHEVET OG SENDT TILBAKE til kommunen for ny behandling"
      ]
  , matrixRules =
      [ partsAtMost "utfall" EachRow ["e1", "e2"] "e" "Stadfestede og ikke opprettholdte vedtak kan ikke overstige vedtak i alt"
      , partsAtMost "ikkeOpprettholdt" EachRow ["e2a", "e2b"] "e2" "Omgjorte og opphevede vedtak kan ikke overstige ikke opprettholdte vedtak"
      ]
  , matrixCellFormulas = []
  }

-- ---------------------------------------------------------------------------
-- F

inspectionCols :: [MatrixCol]
inspectionCols =
  [ matrixCol "a" "a. Antall tilsyn i alt"
  , matrixCol "b" "b. Herav tilsyn med eksisterende tiltak"
  , matrixCol "c" "c. Herav tilsyn med nye tiltak"
  , matrixCol "d" "d. Herav tilsyn på byggverket"
  ]

inspectionRules :: [MatrixRule]
inspectionRules =
  [ partsAtMost "eksisterendeNye" EachRow ["b", "c"] "a" "Tilsyn med eksisterende og nye tiltak kan ikke overstige tilsyn i alt"
  , partsAtMost "byggverket" EachRow ["d"] "a" "Tilsyn på byggverket kan ikke overstige tilsyn i alt"
  ]

f1 :: Matrix
f1 = Matrix
  { matrixPrefix = "t6_f1"
  , matrixRows =
      [ (matrixRow "a" "a. Antall byggesaker hvor det er utført tilsyn (ett eller flere), jf. pbl § 25-1") { rowRequired = ["a"] }
      , matrixRow "b" "b. Antall tiltak hvor det er utført ulovlighetsoppfølging, jf. pbl § 1-4"
      , (matrixRow "c" "c. Antall tilsyn med eksisterende byggverk og arealer, jf. pbl § 25-4") { rowCols = Just ["a"] }
      ]
  , matrixCols = inspectionCols
  , matrixRules = inspectionRules
  , matrixCellFormulas = []
  }

f2 :: Matrix
f2 = Matrix
  { matrixPrefix = "t6_f2"
  , matrixRows =
      [ (matrixRow "a" "a. Antall gjennomførte tilsyn i alt (tilsyn med tilsynsrapport og enkle tilsyn som kun er oppført i samlerapport)") { rowRequired = ["a"] }
      , matrixRow "a1" "a1. Antall tilsyn med omsøkte tiltak (byggesaker)"
      , matrixRow "a2" "a2. Antall tilsyn i alt med ikke omsøkte tiltak (unntak og ulovligheter)"
      , matrixRow "a2a" "a2a. Antall tilsyn med tiltak som er unntatt fra søknadsplikt"
      , matrixRow "a2b" "a2b. Ulovlighetsoppfølginger (ved ikke omsøkte tiltak)"
      ]
  , matrixCols = inspectionCols
  , matrixRules = inspectionRules ++
      [ partsAtMost "omsokt" EachColumn ["a1", "a2"] "a" "Tilsyn med omsøkte og ikke omsøkte tiltak kan ikke overstige tilsyn i alt"
      , partsAtMost "ikkeOmsokt" EachColumn ["a2a", "a2b"] "a2" "Tilsyn med unntatte tiltak og ulovlighetsoppfølginger kan ikke overstige tilsyn med ikke omsøkte tiltak"
      ]
  , matrixCellFormulas = []
  }

-- | Verified: a = a1 + ... + a21 (945)
f3 :: Matrix
f3 = Matrix
  { matrixPrefix = "t6_f3"
  , matrixRows =
      (matrixRow "a" "a. Antall tilsyn i alt, med fokus på følgende tema fra byggteknisk forskrift og byggesaksforskriften")
        { rowFormula = Just (sumOfKeys [ 'a' : show i | i <- [1 .. 21 :: Int] ]) }
      : [ matrixRow ('a' : show i) lbl | (i, lbl) <- zip [1 :: Int ..] themes ]
  , matrixCols = [ matrixCol "antall" "Antall tilsyn" ]
  , matrixRules = []
  , matrixCellFormulas = []
  }
  where
    themes =
      [ "a1. Produkter til byggverk (TEK17 kap. 3 og DOK)"
      , "a2. Sikkerhet ved brann (TEK17 kap. 11)"
      , "a3. Sikkerhet og bæreevne (TEK17 kap. 10)"
      , "a4. Plassering av tiltak (pbl. § 29-4, tillatelsen, TEK17 kap. 5 og 6)"
      , "a5. Energi (TEK17 kap. 14)"
      , "a6. Miljø og helse (TEK17 kap. 11)"
      , "a7. Ytre miljø (TEK17 kap. 9)"
      , "a8. Installasjoner og anlegg (TEK17 kap. 15)"
      , "a9. Utearealer / Universell utforming (TEK17 kap. 8)"
      , "a10. Planløsning / Universell utforming (TEK17 kap. 12)"
      , "a11. Dokumentasjon FDV (TEK17 kap. 4)"
      , "a12. Sluttdokumentasjon"
      , "a13. Avfallsplaner og miljøsanering (TEK17 § 9-6, 9-7, 9-8, 9-9)"
      , "a14. Kulturminner og kulturmiljøer"
      , "a15. Kvalifikasjoner i tiltak (SAK10 kap. 9, 10, 11)"
      , "a16. Sikkerhet mot naturpåkjenninger (TEK17 kap. 7)"
      , "a17. Inneklima og helse (TEK17 kap. 13)"
      , "a18. Klima og livsløp (TEK17 kap. 17)"
      , "a19. Prioritert fokusområde 2025 og 2026, jf. SAK10 § 15-3: Dokumentasjon for sikkerhet mot naturfarer"
      , "a20. Prioritert fokusområde 2025 og 2026, jf. SAK10 § 15-3: Etablering av hybler og boenheter"
      , "a21. Annet"
      ]

f4 :: FormParts
f4 =
  ( [ field "t6_f4_1" "F4.1 Antall tilsyn der alt var ok. Ingen feil/mangler påvist" Nothing QInteger False Nothing [("gridXs", Number 6)]
    , field "t6_f4_2" "F4.2 Antall tilsyn som avdekket ulovlighet/forhold som krever oppfølging" Nothing QInteger False Nothing [("gridXs", Number 6)]
    ]
  , []
  , [ Constraint
        { constraintId        = "t6_f4_konklusjon"
        , constraintLeft      = sumOf ["t6_f4_1", "t6_f4_2"]
        , comparison          = CmpLte
        , constraintRight     = Field (cellId "t6_f2" "a" "a")
        , message             = "Tilsyn uten feil og tilsyn med ulovlighet kan til sammen ikke overstige gjennomførte tilsyn i alt (F2.a)"
        , severity            = SevError
        , constraintCondition = Nothing
        , reportOn            = []
        }
    ]
  )

-- ---------------------------------------------------------------------------
-- G

g1 :: Matrix
g1 = Matrix
  { matrixPrefix = "t6_g1"
  , matrixRows =
      [ (matrixRow "a" "a. Antall pålegg gitt i rapporteringsåret, i alt for alle tilsynstema og brudd på plan- og bygningslovgivningen") { rowRequired = ["a"] }
      , matrixRow "b1" "b1. Pålegg om retting (pbl § 32-3)"
      , matrixRow "b2" "b2. Pålegg om opphør av bruk (pbl § 32-3 og § 32-4)"
      , matrixRow "b3" "b3. Pålegg om stans (pbl § 32-3 og § 32-4)"
      ]
  , matrixCols = existingNewCols "pålegg"
  , matrixRules =
      [ existingNewRule "Pålegg"
      , partsAtMost "typer" EachColumn ["b1", "b2", "b3"] "a" "Pålegg om retting, opphør og stans kan ikke overstige pålegg i alt"
      ]
  , matrixCellFormulas = []
  }

g2 :: Matrix
g2 = Matrix
  { matrixPrefix = "t6_g2"
  , matrixRows =
      [ (matrixRow "a" "a. Utfallet av pålegg gitt i rapporteringsåret") { rowRequired = ["a"] }
      , matrixRow "a1" "a1. Antallet pålegg der forholdet ble rettet opp"
      , matrixRow "a2" "a2. Antallet pålegg der forholdet ikke ble rettet opp og ikke fulgt opp videre"
      , matrixRow "a3" "a3. Antallet pålegg med annet utfall"
      , matrixRow "b1" "b1. Oppfølging av pålegg: Forelegg"
      , matrixRow "b2" "b2. Oppfølging av pålegg: Tvangsmulkt"
      , matrixRow "b3" "b3. Oppfølging av pålegg: Tvangsfullbyrdelse"
      ]
  , matrixCols = existingNewCols "oppfølginger"
  , matrixRules =
      [ existingNewRule "Oppfølginger"
      , partsAtMost "utfall" EachColumn ["a1", "a2", "a3"] "a" "Utfallene kan til sammen ikke overstige pålegg i alt"
      ]
  , matrixCellFormulas = []
  }

g3 :: Matrix
g3 = Matrix
  { matrixPrefix = "t6_g3"
  , matrixRows =
      [ matrixRow "a" "a. Antall sanksjoner brukt i rapporteringsåret, i alt"
      , matrixRow "a1" "a1. Overtredelsesgebyr (pbl § 32-8 og SAK10 kap. 16, pbl. § 32-8a)"
      ]
  , matrixCols = existingNewCols "sanksjoner"
  , matrixRules =
      [ existingNewRule "Sanksjoner"
      , partsAtMost "overtredelsesgebyr" EachColumn ["a1"] "a" "Overtredelsesgebyr kan ikke overstige sanksjoner i alt"
      ]
  , matrixCellFormulas = []
  }

g4 :: Matrix
g4 = Matrix
  { matrixPrefix = "t6_g4"
  , matrixRows =
      (matrixRow "a" "a. Antall andre virkemidler brukt i rapporteringsåret, i alt") { rowRequired = ["a"] }
      : [ matrixRow k l
        | (k, l) <-
            [ ("a1", "a1. Herav advarsel")
            , ("a2", "a2. Herav tilbaketrekking av ansvarsrett")
            , ("a3", "a3. Herav rapport til den sentrale godkjenningsordningen")
            , ("a4", "a4. Herav anmeldelse til politiet")
            , ("a5", "a5. Herav pålegg/krav om uavhengig kontroll")
            ]
        ]
  , matrixCols = existingNewCols "andre virkemidler"
  , matrixRules =
      [ existingNewRule "Andre virkemidler"
      , partsAtMost "typer" EachColumn ["a1", "a2", "a3", "a4", "a5"] "a" "Virkemidlene kan til sammen ikke overstige andre virkemidler i alt"
      ]
  , matrixCellFormulas = []
  }

-- ---------------------------------------------------------------------------
-- I

-- | Verified: 2 = 2a + 2b (21 + 11 = 32)
bolkI :: FormParts
bolkI =
  ( [ field "t6_elektroniskSakssystemBrukt" "I.1 Er elektronisk sakssystem brukt som grunnlag for store deler av rapporteringen?" Nothing QBoolean True Nothing [("gridXs", Number 6)]
    , field "t6_maskinelleOpptellinger" "I.1a Er tallene i utfyllingen av skjema framkommet som resultat av maskinelle opptellinger/summeringer?" Nothing QBoolean True (Just (IsTrue "t6_elektroniskSakssystemBrukt")) [("gridXs", Number 6)]
    , field "t6_timerTotalt" "I.2 Antall timer det tok å rapportere - totalt (beregnet)" Nothing QInteger False Nothing [("unit", String "Timer"), ("readOnly", Bool True), ("gridXs", Number 4)]
    , field "t6_timerUtfylling" "I.2a Antall timer det tok å fylle ut skjemaet" Nothing QInteger True Nothing [("unit", String "Timer"), ("gridXs", Number 4)]
    , field "t6_timerFremskaffe" "I.2b Antall timer det tok å framskaffe informasjonen for utfylling" Nothing QInteger True Nothing [("unit", String "Timer"), ("gridXs", Number 4)]
    ]
  , [ Calculation "t6_timerTotalt" (sumOf ["t6_timerUtfylling", "t6_timerFremskaffe"]) ]
  , []
  )
