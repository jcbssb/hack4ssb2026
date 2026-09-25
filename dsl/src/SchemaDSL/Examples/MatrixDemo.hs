{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}

-- | Small demo of the matrix builder (SchemaDSL.Builders), one bolk per main use:
--
-- 1. Column and row sums, including the grand total
-- 2. Remainder column (c = a - b) with a "not negative" rule
-- 3. Calculated averages (division) and a sum row that skips them
-- 4. A page opened by a Ja/Nei question, row subsets, cells that open when
--    another cell is > 0, and "herav" rules
-- 5. Cells copied from another matrix, and a warning rule with multiplication
module SchemaDSL.Examples.MatrixDemo
  ( matrixDemoDialogue
  ) where

import SchemaDSL.Types
import SchemaDSL.Builders

matrixDemoDialogue :: Dialogue
matrixDemoDialogue = Dialogue
  { dialogueId   = "hack4ssb-matrix"
  , title        = "Matrise-demo: Bibliotekstatistikk"
  , context      = Just SurveyContext
      { surveyCode   = Just "HACK-2026-MATRISE"
      , organization = Just "Statistisk sentralbyrå"
      , legalNotice  = Just "Viser hovedbruken av matrise-hjelperen: summer, rest, snitt, betingede celler, herav-kontroller og celler hentet fra andre tabeller."
      }
  , calculations = concat calcs
  , constraints  = concat cons
  , steps        = stepList
  }
  where
    (stepList, calcs, cons) = unzip3
      [ bolk "1_summer" "1. Utlån per kvartal (summer i rader og kolonner)"
          "Fyll inn utlån per medietype og kvartal. «I alt»-kolonnen og «Sum»-raden beregnes, også hjørnecellen."
          Nothing [ matrix utlaan ]
      , bolk "2_rest" "2. Besøk (restkolonne)"
          "«Herav voksne» beregnes som besøk i alt minus barn. Blir den negativ, stopper «Neste side» med en feil."
          Nothing [ matrix besoek ]
      , bolk "3_snitt" "3. Arrangementer (snitt og sum som hopper over snitt)"
          "Snitt deltakere beregnes med divisjon. Sum-raden summerer antall og deltakere, men snittet i sum-raden er deltakere i alt delt på arrangementer i alt."
          Nothing [ matrix arrangementer ]
      , bolk "4_innkjop" "4. Innkjøp (inngangsspørsmål)"
          "Svarer du Ja, åpnes en ny side med innkjøpstabellen."
          Nothing
          [ questionsOnly
              [ Question
                  { fieldId      = "demo_harKjoptInn"
                  , prompt       = Prompt "Har biblioteket kjøpt inn medier i år?" Nothing
                  , questionType = QBoolean
                  , required     = True
                  , condition    = Nothing
                  , annotations  = Nothing
                  }
              ]
          ]
      , bolk "4_betinget" "4b. Innkjøp (betingede celler og herav-kontroller)"
          "«Herav»-cellene åpnes først når det er bestilt noe i samme kolonne, og kan ikke overstige det som er bestilt."
          (Just (IsTrue "demo_harKjoptInn")) [ matrix innkjoep ]
      , bolk "5_hentet" "5. Sammenligning med i fjor (celler hentet fra tabell 1)"
          "«I år» hentes fra sum-raden i tabell 1. Endringen beregnes, og et fall på mer enn 50 % gir en advarsel du kan gå videre fra."
          Nothing [ matrix sammenligning ]
      ]

bolk :: String -> String -> String -> Maybe Predicate -> [FormParts] -> (Step, [Calculation], [Constraint])
bolk bid ttl desc cond parts =
  let (qs, calcs, cons) = mconcat parts
  in (BolkStep (Bolk bid ttl (Just desc) cond qs), calcs, cons)

quarters :: [String]
quarters = ["k1", "k2", "k3", "k4"]

-- | 1. Column formula ("I alt" per row) and row formula ("Sum" per column).
-- In the corner cell both apply; the column formula wins, and both give the same total.
utlaan :: Matrix
utlaan = Matrix
  { matrixPrefix = "demo_utlaan"
  , matrixRows =
      [ matrixRow "boker" "Bøker"
      , matrixRow "lydboker" "Lydbøker"
      , matrixRow "eboker" "E-bøker"
      , (matrixRow "sum" "Sum alle medier") { rowFormula = Just (sumOfKeys ["boker", "lydboker", "eboker"]) }
      ]
  , matrixCols =
      [ matrixCol q ("Kvartal " ++ drop 1 q) | q <- quarters ]
      ++ [ (matrixCol "alt" "I alt") { colFormula = Just (sumOfKeys quarters) } ]
  , matrixRules = []
  , matrixCellFormulas = []
  }

-- | 2. Remainder column with a rule that it is not negative
besoek :: Matrix
besoek = Matrix
  { matrixPrefix = "demo_besoek"
  , matrixRows =
      [ (matrixRow "sentrum" "Filial Sentrum") { rowRequired = ["a"] }
      , (matrixRow "nord" "Filial Nord") { rowRequired = ["a"] }
      ]
  , matrixCols =
      [ matrixCol "a" "a. Besøk i alt"
      , matrixCol "b" "b. Herav barn"
      , (matrixCol "c" "c. Herav voksne (beregnet)") { colFormula = Just (\c -> Sub (c "a") (c "b")) }
      ]
  , matrixRules = [ atLeastZero "voksne" EachRow "c" "Barn kan ikke være flere enn besøk i alt" ]
  , matrixCellFormulas = []
  }

-- | 3. Calculated average (division) in a non-summable column. The sum row adds
-- up the summable columns; its average comes from the column formula instead.
arrangementer :: Matrix
arrangementer = Matrix
  { matrixPrefix = "demo_arr"
  , matrixRows =
      [ (matrixRow "sum" "Arrangementer i alt") { rowFormula = Just (sumOfKeys ["forfatter", "teater", "kurs"]) }
      , matrixRow "forfatter" "Forfattermøter"
      , matrixRow "teater" "Barneteater"
      , matrixRow "kurs" "Datakurs for seniorer"
      ]
  , matrixCols =
      [ matrixCol "antall" "Antall arrangementer"
      , matrixCol "deltakere" "Deltakere"
      , (matrixCol "snitt" "Snitt deltakere per arrangement")
          { colFormula = Just (\c -> Div (c "deltakere") (c "antall")), colSummable = False }
      ]
  , matrixRules = []
  , matrixCellFormulas = []
  }

-- | 4. Row subsets, cells that open when the same column in row 1 is > 0,
-- and "herav" rules per column
innkjoep :: Matrix
innkjoep = Matrix
  { matrixPrefix = "demo_innkjop"
  , matrixRows =
      [ (matrixRow "1" "1. Titler bestilt") { rowRequired = ["boker", "lydboker"] }
      , (matrixRow "1.1" "1.1 Herav forsinket levering")
          { rowCondition = Just (\cell col -> Compare (cell "1" col) CmpGt (Const 0)) }
      , (matrixRow "1.2" "1.2 Herav avbestilt (kun bøker)")
          { rowCols = Just ["boker"]
          , rowCondition = Just (\cell col -> Compare (cell "1" col) CmpGt (Const 0)) }
      ]
  , matrixCols =
      [ matrixCol "boker" "Bøker"
      , matrixCol "lydboker" "Lydbøker"
      ]
  , matrixRules =
      [ partsAtMost "forsinket" EachColumn ["1.1"] "1" "Forsinket kan ikke overstige bestilt"
        -- Only generated for the Bøker column, since row 1.2 has no Lydbøker cell
      , partsAtMost "herav" EachColumn ["1.1", "1.2"] "1" "Forsinket og avbestilt kan til sammen ikke overstige bestilt"
      ]
  , matrixCellFormulas = []
  }

-- | 5. Cells copied from another matrix, a difference column, and a custom
-- warning rule: this year should be at least half of last year
sammenligning :: Matrix
sammenligning = Matrix
  { matrixPrefix = "demo_sml"
  , matrixRows = [ matrixRow "utlaan" "Utlån i alt" ]
  , matrixCols =
      [ matrixCol "iaar" "I år (fra tabell 1)"
      , matrixCol "ifjor" "I fjor"
      , (matrixCol "endring" "Endring") { colFormula = Just (\c -> Sub (c "iaar") (c "ifjor")) }
      ]
  , matrixRules =
      [ MatrixRule "fall" EachRow ($ "iaar") CmpGte (\c -> Mul [c "ifjor", Const 0.5]) SevWarning
          "Utlånet har falt med mer enn 50 % fra i fjor. Er tallene riktige?"
      ]
  , matrixCellFormulas =
      [ (("utlaan", "iaar"), Field (cellId "demo_utlaan" "sum" "alt")) ]
  }
