{-# LANGUAGE OverloadedStrings #-}

module Main where

import System.Exit (exitFailure, exitSuccess)
import Data.Aeson (Value(..), encode)
import qualified Data.ByteString.Lazy.Char8 as BLC
import qualified Data.Aeson.KeyMap as KM
import qualified Data.Vector as V
import qualified Data.Text as T
import qualified Data.Map.Strict as M
import Data.List (nub, isInfixOf)
import SchemaDSL
import SchemaDSL.Altinn.DataModel (injectCSharpClass, removeCSharpClass)

main :: IO ()
main = do
  putStrLn "Running SchemaDSL test suite..."
  testRoundTripHelloWorld
  testRoundTripWithChoice
  testRoundTripSyntheticComprehensive
  testInvalidJSONHandling
  testCompileToAltinn
  testCompileSyntheticToAltinn
  testCompileKostra51ToAltinn
  testCompileKostra51Side1ToAltinn
  testCompileKostra51AllSidesToAltinn
  testBolkRoundTripAndCompilation
  testEvolutionPageOrdering
  testRulesRoundTrip
  testRulesBackwardCompatibleJSON
  testEvalCalculationsAndConstraints
  testValidateRules
  testCompileRulesToAltinn
  testNumericConditions
  testMatrixColumnsFromPdf
  testMatrixRowsFromPdf
  testTrialAgainstPdf "Trial 5" "t5" trial5ByggesakDialogue
  testTrialAgainstPdf "Trial 6" "t6" trial6ByggesakDialogue
  testTrialAgainstPdf "Trial 7" "t7" trial7ByggesakDialogue
  testTrialAgainstPdf "Trial 8" "t7" trial8ByggesakDialogue
  testTrialAgainstPdf "Trial 9" "t7" trial9ByggesakDialogue
  testMatrixDemo
  testPagedAltinn
  testCSharpClassRemoval
  testAppTitle
  testTrial7AuditFixes
  testTrial8SliceA
  testTrial8SliceB
  testTrial8SliceC
  testTrial8SliceD
  testTrial8SliceE
  testTrial9
  putStrLn "All SchemaDSL tests passed successfully!"
  exitSuccess

-- | Budget split into parts: total is entered, remainder is derived, parts must not exceed total
budgetDialogue :: Dialogue
budgetDialogue = Dialogue
  { dialogueId   = "budget-test"
  , title        = "Budget split"
  , context      = Nothing
  , calculations =
      [ Calculation "rest" (Sub (Field "total") (Field "delSum"))
      , Calculation "delSum" (sumOf ["delA", "delB"])
      ]
  , constraints  =
      [ Constraint
          { constraintId        = "deler-innenfor-total"
          , constraintLeft      = Field "delSum"
          , comparison          = CmpLte
          , constraintRight     = Field "total"
          , message             = "Delene kan ikke overstige totalen."
          , severity            = SevError
          , constraintCondition = Nothing
          , reportOn            = []
          }
      , Constraint
          { constraintId        = "ingen-rest"
          , constraintLeft      = Field "rest"
          , comparison          = CmpEq
          , constraintRight     = Const 0
          , message             = "Delene skal summere til totalen."
          , severity            = SevWarning
          , constraintCondition = Just (IsTrue "fordelt")
          , reportOn            = ["rest"]
          }
      ]
  , steps        = map QuestionStep
      [ numQ "total" QDecimal, numQ "delA" QDecimal, numQ "delB" QDecimal
      , numQ "delSum" QDecimal, numQ "rest" QDecimal
      , (numQ "fordelt" QBoolean)
      ]
  }
  where
    numQ fid qt = Question fid (Prompt fid Nothing) qt False Nothing Nothing

expect :: Bool -> String -> IO ()
expect ok msg
  | ok        = putStrLn ("[PASS] " ++ msg)
  | otherwise = putStrLn ("[FAIL] " ++ msg) >> exitFailure

-- | Test 11: Calculations and constraints survive JSON round-trip
testRulesRoundTrip :: IO ()
testRulesRoundTrip =
  expect (decodeDialogue (encodeDialogue budgetDialogue) == Right budgetDialogue
          && decodeDialogue (encodeDialogue trial4ByggesakDialogue) == Right trial4ByggesakDialogue)
         "Calculations and constraints JSON round-trip verified."

-- | Test 12: Dialogues without rules still decode, and encode without rule keys
testRulesBackwardCompatibleJSON :: IO ()
testRulesBackwardCompatibleJSON = do
  let legacy = "{\"dialogueId\": \"x\", \"title\": \"X\", \"steps\": []}"
      encoded = encodeDialogue helloWorldDialogue
  expect (fmap calculations (decodeDialogue legacy) == Right []
          && not ("calculations" `T.isInfixOf` T.pack (BLC.unpack encoded)))
         "Dialogues without rules decode and encode unchanged."

-- | Test 13: Reference evaluator derives remainders and detects violations
testEvalCalculationsAndConstraints :: IO ()
testEvalCalculationsAndConstraints = do
  let answers = M.fromList [("total", "100"), ("delA", "60,5"), ("delB", "30")]
      derived = applyCalculations budgetDialogue answers
      violatedIds as = map (constraintId . violatedConstraint) (checkConstraints budgetDialogue as)
  expect (M.lookup "delSum" derived == Just "90.5" && M.lookup "rest" derived == Just "9.5")
         "Calculations evaluate in dependency order (sum, then remainder)."
  expect (violatedIds answers == []
          && violatedIds (M.insert "fordelt" "true" answers) == ["ingen-rest"]
          && violatedIds (M.insert "delB" "50" answers) == ["deler-innenfor-total"])
         "Constraints respect comparisons, conditions and tolerance."
  expect (violatedIds (M.fromList [("fordelt", "true"), ("total", "0.3"), ("delA", "0.1"), ("delB", "0.2")]) == [])
         "Equality constraints tolerate floating point rounding."
  expect (map violationFields (checkConstraints budgetDialogue (M.insert "delB" "50" answers)) == [["delA", "delB", "total"]])
         "Violations report on entered fields by default."

-- | Test 14: Static rule checks pass for all examples and catch broken rules
testValidateRules :: IO ()
testValidateRules = do
  let examples = [ helloWorldDialogue, syntheticHackDialogue, kostra51KulturminneDialogue
                 , kostra51FullDialogue, trial1ByggesakDialogue, trial2ByggesakDialogue
                 , trial3ByggesakDialogue, trial4ByggesakDialogue, trial5ByggesakDialogue, trial6ByggesakDialogue, trial7ByggesakDialogue, trial8ByggesakDialogue, trial9ByggesakDialogue, budgetDialogue, rulesDemoDialogue, matrixDemoDialogue ]
      problems = concatMap validateRules examples
      broken = budgetDialogue
        { calculations = calculations budgetDialogue ++ [Calculation "delA" (Field "rest"), Calculation "nope" (Const 1)] }
  expect (null problems) ("All example rules are well-formed. " ++ show problems)
  expect (length (validateRules broken) >= 4) "Rule checks catch unknown fields and calculation cycles."

-- | Test 15: Rules compile to Altinn Number components and expression validations
testCompileRulesToAltinn :: IO ()
testCompileRulesToAltinn = do
  let artifacts = compileToAltinn trial4ByggesakDialogue
      layoutTxt = BLC.unpack (encode (pageLayout artifacts))
      paths = map fst (validations artifacts)
      paths5 = map fst (validations (compileToAltinn trial5ByggesakDialogue))
  expect ("t4-timerTotalt-number" `T.isInfixOf` T.pack layoutTxt
          && not ("t4-timerTotalt-input" `T.isInfixOf` T.pack layoutTxt))
         "Calculated fields compile to display-only Number components."
  expect ("SkjemaData.trial4_byggesak.t4_e1_klagerKommuneAlt" `elem` paths
          && "SkjemaData.trial4_byggesak.t4_c10_delingBehandlet" `elem` paths
          && any ((== "lang.trial4_byggesak.constraint.t4_e1_herav") . fst) (textResources artifacts)
          && "SkjemaData.trial5_byggesak.t5_e1_2_b1" `elem` paths5
          && "SkjemaData.trial5_byggesak.t5_e1_1_b" `notElem` paths5)
         "Constraints compile to expression validations with text resources."
  let budget = compileToAltinn budgetDialogue
      budgetPaths = map fst (validations budget)
  expect (lookup "SkjemaData.budget_test.delA" (validations budget) /= Nothing
          && "SkjemaData.budget_test.rest" `notElem` budgetPaths
          && fmap length (lookup "SkjemaData.budget_test.total" (validations budget)) == Just 2)
         "Messages on calculated fields move to their entered inputs in Altinn."

-- | Test 16: Numeric conditions (cells that open when another field is > 0)
testNumericConditions :: IO ()
testNumericConditions = do
  let opened = Compare (Field "mottatt") CmpGt (Const 0)
      numQ fid cond = Question fid (Prompt fid Nothing) QInteger False cond Nothing
      d = Dialogue
        { dialogueId = "numeric-cond", title = "Numeric", context = Nothing
        , calculations = [], constraints = []
        , steps = map QuestionStep [ numQ "mottatt" Nothing, numQ "mangelfulle" (Just opened) ]
        }
      layoutTxt = T.pack (BLC.unpack (encode (pageLayout (compileToAltinn d))))
  expect (decodeDialogue (encodeDialogue d) == Right d) "Numeric condition JSON round-trip verified."
  expect (not (evalPredicate M.empty opened)
          && evalPredicate (M.fromList [("mottatt", "3")]) opened
          && not (evalPredicate (M.fromList [("mottatt", "0")]) opened)
          && evalPredicate (M.fromList [("a", "0.30000001")]) (Compare (Field "a") CmpEq (Const 0.3)))
         "Numeric conditions evaluate with empty-as-zero and tolerance."
  expect ("\"hidden\":[\"not\",[\"greaterThan\"" `T.isInfixOf` layoutTxt)
         "Numeric conditions compile to Altinn hidden expressions."
  expect (validateRules d { steps = [ QuestionStep (numQ "x" (Just (Compare (Field "nope") CmpGt (Const 0)))) ] }
            == ["Condition on x references unknown field: nope"])
         "Rule checks catch unknown fields in conditions."

-- | Wrap form parts in a single-bolk dialogue
partsDialogue :: String -> FormParts -> Dialogue
partsDialogue did (qs, calcs, cons) = Dialogue
  { dialogueId = did, title = did, context = Nothing
  , calculations = calcs, constraints = cons
  , steps = [ BolkStep (Bolk "b" did Nothing Nothing qs) ]
  }

-- | Byggesak C12 (ett-trinnssøknader med ansvarsrett): calculated columns and row subsets
c12Matrix :: Matrix
c12Matrix = Matrix
  { matrixPrefix = "t4_c12"
  , matrixRows =
      [ matrixRow "1" "1. Antall søknader mottatt"
      , (matrixRow "1.1" "1.1 Herav mangelfulle søknader")
          { rowCols = Just ["a"]
          , rowCondition = Just (\cell _ -> Compare (cell "1" "a") CmpGt (Const 0)) }
      , matrixRow "2" "2. Antall søknader behandlet"
      , matrixRow "2.1" "2.1 Herav over lovpålagt frist"
      ]
  , matrixCols =
      [ matrixCol "a" "a. I alt"
      , matrixCol "b" "b. I samsvar med plan, i alt"
      , matrixCol "b1" "b1. Herav 3 ukers frist"
      , (matrixCol "b2" "b2. Herav 12 ukers frist") { colFormula = Just (\c -> Sub (c "b") (c "b1")) }
      , (matrixCol "c" "c. Ikke i samsvar med plan") { colFormula = Just (\c -> Sub (c "a") (c "b")) }
      , (matrixCol "d" "d. 12 ukers frist i alt") { colFormula = Just (\c -> Add [c "c", c "b2"]) }
      ]
  , matrixRules =
      [ atLeastZero "ikkeNegativ" EachRow "c" "Søknader i samsvar med plan kan ikke overstige søknader i alt"
      , partsAtMost "mangelfulle" EachColumn ["1.1"] "1" "Mangelfulle søknader kan ikke overstige mottatte"
      , partsAtMost "overFrist" EachColumn ["2.1"] "2" "Søknader over frist kan ikke overstige behandlede"
      ]
  , matrixCellFormulas = []
  }

-- | Test 17: Column formulas reproduce the printed C12 values in the filled-in PDF
testMatrixColumnsFromPdf :: IO ()
testMatrixColumnsFromPdf = do
  let parts@(qs, calcs, _) = matrix c12Matrix
      d = partsDialogue "c12" parts
      entered = M.fromList
        [ (cellId "t4_c12" r c, v)
        | (r, vals) <- [ ("1", ["234", "34", "23"]), ("2", ["10", "546", "343"]), ("2.1", ["5646", "43", "35465"]) ]
        , (c, v) <- zip ["a", "b", "b1"] vals ]
        `M.union` M.fromList [ (cellId "t4_c12" "1.1" "a", "34") ]
      derived = applyCalculations d entered
      row r = [ M.lookup (cellId "t4_c12" r c) derived | c <- ["b2", "c", "d"] ]
      violated = map (constraintId . violatedConstraint) (checkConstraints d entered)
  expect (length qs == 19 && length calcs == 9 && null (validateRules d))
         "Matrix expands to cells for present columns only, with column calculations."
  expect (row "1" == map Just ["11", "200", "211"]
          && row "2" == map Just ["203", "-536", "-333"]
          && row "2.1" == map Just ["-35422", "5603", "-29819"])
         "Column formulas reproduce the C12 values printed in the PDF."
  expect ("t4_c12_ikkeNegativ_2" `elem` violated
          && "t4_c12_overFrist_a" `elem` violated
          && "t4_c12_mangelfulle_a" `notElem` violated
          && "t4_c12_ikkeNegativ_1" `notElem` violated)
         "Matrix rules are instantiated per row and column."
  expect (fmap (evalPredicate entered) (condition =<< lookup (cellId "t4_c12" "1.1" "a") [ (fieldId q, q) | q <- qs ]) == Just True)
         "Row conditions refer to other cells."

-- | Test 18: Row formulas reproduce the printed E1 sums, skipping the average column
testMatrixRowsFromPdf :: IO ()
testMatrixRowsFromPdf = do
  let e1 = Matrix
        { matrixPrefix = "t4_e1"
        , matrixRows =
            [ (matrixRow "1" "1. Klagesaker i alt") { rowFormula = Just (sumOfKeys ["2", "3", "4"]) }
            , matrixRow "2" "2. Klagesaker på gebyrer"
            , (matrixRow "3" "3. Klagesaker på utfall av søknadsbehandling") { rowFormula = Just (sumOfKeys ["3a", "3b", "3c", "3d"]) }
            , matrixRow "3a" "3a. Byggesøknader"
            , matrixRow "3b" "3b. Opprettelse og endring av eiendom"
            , matrixRow "3c" "3c. Oppmålingssaker"
            , matrixRow "3d" "3d. Seksjoneringssaker"
            , matrixRow "4" "4. Tilsyn og ulovlighetsoppfølging"
            ]
        , matrixCols =
            [ matrixCol "b" "b. Vedtak i alt"
            , matrixCol "b1" "b1. Tatt til følge"
            , matrixCol "b2" "b2. Oversendt Statsforvalteren"
            , (matrixCol "c" "c. Gjennomsnittlig saksbehandlingstid") { colSummable = False }
            , matrixCol "d" "d. Over lovpålagt frist"
            ]
        , matrixRules = [ partsAtMost "herav" EachRow ["b1", "b2"] "b" "Tatt til følge og oversendt kan ikke overstige vedtak i alt" ]
        , matrixCellFormulas = []
        }
      d = partsDialogue "e1" (matrix e1)
      entered = M.fromList
        [ (cellId "t4_e1" r c, v)
        | (r, vals) <- [ ("2", ["345", "345", "67", "3124", "656"]), ("3a", ["46", "34", "562", "5622", "4678"])
                       , ("3b", ["875", "275", "725", "752", "45"]), ("3c", ["26", "45", "656", "654", "54"])
                       , ("3d", ["25", "54", "674", "7467", "573"]), ("4", ["36", "364", "563", "765", "6345"]) ]
        , (c, v) <- zip ["b", "b1", "b2", "c", "d"] vals ]
      derived = applyCalculations d entered
      row r = [ M.lookup (cellId "t4_e1" r c) derived | c <- ["b", "b1", "b2", "d"] ]
  expect (row "3" == map Just ["972", "408", "2617", "5350"]
          && row "1" == map Just ["1353", "1117", "3247", "12351"])
         "Row formulas reproduce the E1 sums printed in the PDF (nested rows)."
  expect (cellId "t4_e1" "1" "c" `notElem` map calcTarget (calculations d)
          && null (validateRules d))
         "Row formulas skip non-summable columns such as averages."

-- | Test 19: Trials 5 and 6 reproduce the calculated cells printed in the filled-in 20Byggesak PDF
-- (research/20byggesak-pdf-tekst.txt). Entered values are the sample values from the PDF.
testTrialAgainstPdf :: String -> String -> Dialogue -> IO ()
testTrialAgainstPdf name p d = do
  let cells prefix rows = [ (cellId (p ++ drop 2 prefix) r c, v) | (r, cvs) <- rows, (c, v) <- cvs ]
      entered = M.fromList $ concat
        [ cells "t5_c10" [ ("1", zip ["b", "c", "d", "e", "f"] ["100", "234", "12", "23", "12"])
                         , ("2", zip ["b", "c", "d", "e", "f"] ["100", "10", "12", "3", "45"]) ]
        , cells "t5_c11" [ ("1", [("b", "44")]), ("1.1", [("a", "444")]), ("2", [("b", "124")])
                         , ("2.1", [("a", "2000"), ("b", "444")]) ]
        , cells "t5_c12" [ ("1", [("b", "34"), ("b1", "23")]), ("1.1", [("a", "34")]), ("2", [("b", "546"), ("b1", "343")])
                         , ("2.1", [("a", "5646"), ("b", "43"), ("b1", "35465")]) ]
        , cells "t5_c13" [ ("1", [("b", "345"), ("b1", "30")]), ("1.1", [("a", "13")]), ("2", [("b", "345"), ("b1", "435")])
                         , ("2.1", [("a", "24"), ("b", "54"), ("b1", "45")]) ]
        , cells "t5_c3" [ ("1", [("a", "897"), ("b", "89")]) ]
        , cells "t5_c4" [ ("1", zip ["b", "c", "d"] ["435", "564", "65"]), ("1.1", zip ["b", "c", "d"] ["45", "65", "7657"]) ]
        , cells "t5_e1" [ (r, zip ["b", "b1", "b2", "c", "d"] vs)
                        | (r, vs) <- [ ("2", ["345", "345", "67", "3124", "656"]), ("3a", ["46", "34", "562", "5622", "4678"])
                                     , ("3b", ["875", "275", "725", "752", "45"]), ("3c", ["26", "45", "656", "654", "54"])
                                     , ("3d", ["25", "54", "674", "7467", "573"]), ("4", ["36", "364", "563", "765", "6345"]) ] ]
        , cells "t5_f3" [ ('a' : show i, [("antall", v)])
                        | (i, v) <- zip [1 :: Int ..] (words "3 2 5 6 7 8 9 1 22 11 33 65 99 88 76 56 75 72 123 73 111") ]
        , [ (p ++ "_timerUtfylling", "21"), (p ++ "_timerFremskaffe", "11") ]
        ]
      printed = concat
        [ cells "t5_c11" [ ("1", [("a", "100"), ("c", "56")]), ("2", [("a", "100"), ("c", "-24")]), ("2.1", [("c", "1556")]) ]
        , cells "t5_c12" [ ("1", zip ["a", "b2", "c", "d"] ["234", "11", "200", "211"])
                         , ("2", zip ["a", "b2", "c", "d"] ["10", "203", "-536", "-333"])
                         , ("2.1", zip ["b2", "c", "d"] ["-35422", "5603", "-29819"]) ]
        , cells "t5_c13" [ ("1", zip ["a", "b2", "c", "d"] ["12", "315", "-333", "-18"])
                         , ("2", zip ["a", "b2", "c", "d"] ["12", "-90", "-333", "-423"])
                         , ("2.1", zip ["b2", "c", "d"] ["9", "-30", "-21"]) ]
        , cells "t5_c14" [ ("1", zip ["b", "b1", "b2", "c", "d"] ["423", "53", "370", "-77", "293"])
                         , ("1.1", [("a", "491")])
                         , ("2", zip ["b", "b1", "b2", "c", "d"] ["1015", "778", "237", "-893", "-656"])
                         , ("2.1", zip ["a", "b", "b1", "b2", "c", "d"] ["7670", "541", "35510", "-34969", "7129", "-27840"]) ]
        , cells "t5_c15" [ ("1", [("a", "23")]), ("2", [("a", "3")]) ]
        , cells "t5_c2" [ ("1", [("a", "12")]), ("2", [("a", "45")]) ]
        , cells "t5_c3" [ ("1", [("c", "808")]) ]
        , cells "t5_c4" [ ("1", [("a", "1064")]), ("1.1", [("a", "7767")]) ]
        , cells "t5_e1" [ ("1", zip ["b", "b1", "b2", "d"] ["1353", "1117", "3247", "12351"])
                        , ("3", zip ["b", "b1", "b2", "d"] ["972", "408", "2617", "5350"]) ]
        , cells "t5_f3" [ ("a", [("antall", "945")]) ]
        , [ (p ++ "_timerTotalt", "32") ]
        ]
      derived = applyCalculations d entered
      mismatches = [ (fid, v, M.lookup fid derived) | (fid, v) <- printed, M.lookup fid derived /= Just v ]
  expect (null (validateRules d)) (name ++ " rules are well-formed. " ++ show (validateRules d))
  expect (null mismatches) (name ++ " reproduces " ++ show (length printed) ++ " calculated cells printed in the PDF. " ++ show mismatches)

-- | Test 20: The matrix demo computes totals, averages, copied cells and rules
testMatrixDemo :: IO ()
testMatrixDemo = do
  let d = matrixDemoDialogue
      entered = M.fromList $
        [ (cellId "demo_utlaan" r q, v) | (r, vs) <- [("boker", ["10", "20", "30", "40"]), ("lydboker", ["1", "2", "3", "4"]), ("eboker", ["5", "5", "5", "5"])]
                                        , (q, v) <- zip ["k1", "k2", "k3", "k4"] vs ]
        ++ [ (cellId "demo_arr" r c, v) | (r, vs) <- [("forfatter", ["2", "50"]), ("teater", ["3", "90"]), ("kurs", ["0", "0"])]
                                        , (c, v) <- zip ["antall", "deltakere"] vs ]
        ++ [ (cellId "demo_sml" "utlaan" "ifjor", "300"), ("demo_harKjoptInn", "true")
           , (cellId "demo_innkjop" "1" "boker", "5"), (cellId "demo_innkjop" "1.1" "boker", "4"), (cellId "demo_innkjop" "1.2" "boker", "3") ]
      derived = applyCalculations d entered
      val r c p = M.lookup (cellId p r c) derived
      violated = map (constraintId . violatedConstraint) (checkConstraints d entered)
  expect (val "sum" "alt" "demo_utlaan" == Just "130" && val "boker" "alt" "demo_utlaan" == Just "100"
          && val "sum" "k1" "demo_utlaan" == Just "16")
         "Matrix demo: row and column sums meet in the corner cell."
  expect (val "forfatter" "snitt" "demo_arr" == Just "25" && val "sum" "snitt" "demo_arr" == Just "28"
          && val "kurs" "snitt" "demo_arr" == Nothing)
         "Matrix demo: averages use division, the sum row averages the totals, 0/0 has no value."
  expect (val "utlaan" "iaar" "demo_sml" == Just "130" && val "utlaan" "endring" "demo_sml" == Just "-170"
          && violated == ["demo_innkjop_herav_boker", "demo_sml_fall_utlaan"])
         ("Matrix demo: copied cells, difference and rules. " ++ show violated)

-- | Test 21: Paged Altinn compilation: one page per bolk, page-level hidden, Grid for matrices
testPagedAltinn :: IO ()
testPagedAltinn = do
  let a = compileToAltinnPaged trial5ByggesakDialogue
      layoutOf v = case v of
        Object o | Just (Object dat) <- KM.lookup "data" o, Just (Array cs) <- KM.lookup "layout" dat -> V.toList cs
        _ -> []
      hiddenOf v = case v of
        Object o | Just (Object dat) <- KM.lookup "data" o -> KM.lookup "hidden" dat
        _ -> Nothing
      field k (Object o) = KM.lookup k o
      field _ _ = Nothing
      ids comps = [ t | c <- comps, Just (String t) <- [field "id" c] ]
      gridRefs comps =
        [ t | c <- comps, field "type" c == Just (String "Grid")
            , Just (Array rows) <- [field "rows" c], Object r <- V.toList rows
            , Just (Array cells) <- [KM.lookup "cells" r], Object cell <- V.toList cells
            , Just (String t) <- [KM.lookup "component" cell] ]
      pageNames = map fst (pages a)
      allIds = concatMap (ids . layoutOf . snd) (pages a)
      danglingRefs = [ r | (_, l) <- pages a, let cs = layoutOf l, r <- gridRefs cs, r `notElem` ids cs ]
      hiddenPages = [ n | (n, l) <- pages a, hiddenOf l /= Nothing ]
      grids = length [ () | (_, l) <- pages a, c <- layoutOf l, field "type" c == Just (String "Grid") ]
  expect (length (pages a) == length (steps trial5ByggesakDialogue)
          && take 2 pageNames == ["S05_trial5_byggesak_01", "S05_trial5_byggesak_02"]
          && pageName (compileToAltinn trial5ByggesakDialogue) == "S05_trial5_byggesak")
         "Paged Altinn compilation gives one numbered page per bolk."
  expect (length hiddenPages == 10 && "S05_trial5_byggesak_18" `elem` hiddenPages)
         ("Bolk conditions hide whole pages. " ++ show hiddenPages)
  expect (grids == 22 && null danglingRefs && length allIds == length (nub allIds))
         ("Matrices compile to Grid components referring to components on the same page. " ++ show (take 3 danglingRefs))
  let settings = KM.fromList
        [ ("pages", Object $ KM.fromList
            [ ("groups", Array $ V.fromList
                [ Object $ KM.fromList [ ("order", Array $ V.fromList
                    (map String ["S01_Forside", "S05_trial5_byggesak", "S05_trial5_byggesak_07", "S05_hack4ssb_matrix_01", "S05_trial4_byggesak", "S20_Summary"])) ] ]) ]) ]
      reordered = enforceEvolutionPageOrder settings
      orderOf km = case KM.lookup "pages" km of
        Just (Object p) | Just (Array g) <- KM.lookup "groups" p, Object g0 <- V.head g, Just (Array o) <- KM.lookup "order" g0 -> [ T.unpack t | String t <- V.toList o ]
        _ -> []
  expect (orderOf reordered == ["S01_Forside", "S05_trial4_byggesak", "S05_trial5_byggesak", "S05_trial5_byggesak_07", "S05_hack4ssb_matrix_01", "S20_Summary"]
          && isOwnPage "S05_trial5_byggesak" "S05_trial5_byggesak_12"
          && not (isOwnPage "S05_trial5_byggesak" "S05_trial5_byggesak_x1"))
         ("Numbered pages rank with their dialogue in the evolution order. " ++ show (orderOf reordered))

-- | Test 22: Removing an injected C# class restores the file, also between other classes
testCSharpClassRemoval :: IO ()
testCSharpClassRemoval = do
  let base = unlines
        [ "namespace Altinn.App.Models", "{", "  public class SkjemaData", "  {"
        , "    public string skjemafelt1 { get; set; }", "  }", "" , "}" ]
      qs = allDialogueQuestions helloWorldDialogue
      withA = injectCSharpClass "a_dialog" "A_dialog" qs base
      withAB = injectCSharpClass "b_dialog" "B_dialog" qs withA
      withoutA = removeCSharpClass "a_dialog" "A_dialog" withAB
  expect (removeCSharpClass "a_dialog" "A_dialog" withA == base
          && removeCSharpClass "b_dialog" "B_dialog" withoutA == base
          && removeCSharpClass "b_dialog" "B_dialog" withAB == withA
          && not ("}  public class" `T.isInfixOf` T.pack withoutA))
         "Removing injected C# classes restores the model, wherever the class sits."

-- | Test 23: The app title comes from formName (or title) and replaces only the title object
testAppTitle :: IO ()
testAppTitle = do
  let meta = T.unlines
        [ "{", "  \"id\": \"ssb/app\",", "  \"title\": {", "    \"nb\": \"old\"", "  },", "  \"org\": \"ssb\"", "}" ]
      name = dialogueFormName trial6ByggesakDialogue
      replaced = replaceAppTitle name meta
  expect (name == "20Byggesak. Byggesaksbehandling, opprettelse og endring av eiendom, oppmåling og seksjonering 2026"
          && dialogueFormName trial5ByggesakDialogue == title trial5ByggesakDialogue
          && decodeDialogue (encodeDialogue trial6ByggesakDialogue) == Right trial6ByggesakDialogue)
         "Form name comes from formName, falling back to title, and survives JSON round-trip."
  expect (fmap (T.isInfixOf "\"en\": \"20Byggesak.") replaced == Just True
          && fmap (T.isPrefixOf "{\n  \"id\": \"ssb/app\",") replaced == Just True
          && fmap (T.isSuffixOf "  },\n  \"org\": \"ssb\"\n}\n") replaced == Just True
          && replaceAppTitle name "{}" == Nothing)
         "App title replacement keeps the rest of applicationmetadata.json untouched."

-- | Test 24: Trial 7 corrections from research/byggesak-trial6-audit.md reproduce the PDF
testTrial7AuditFixes :: IO ()
testTrial7AuditFixes = do
  let d = trial7ByggesakDialogue
      cells prefix rows = [ (cellId prefix r c, v) | (r, cvs) <- rows, (c, v) <- cvs ]
      entered = M.fromList $ concat
        [ cells "t7_c10" [ ("1", zip ["a", "b", "c", "d", "e", "f"] ["12", "100", "234", "12", "23", "12"])
                         , ("2", zip ["a", "b", "c", "d", "e", "f"] ["12", "100", "10", "12", "3", "45"]) ]
        , cells "t7_c12" [ ("2", [("b", "546"), ("b1", "343")]), ("2.2", [("b1", "334"), ("b2", "545")]) ]
        , cells "t7_c13" [ ("2", [("b", "345"), ("b1", "435")]), ("2.2", [("b1", "45")]) ]
        , cells "t7_c4" [ ("2", zip ["b", "c", "d"] ["56", "67", "456"]), ("2.2", zip ["b", "c", "d"] ["78", "89", "768"]) ]
        , cells "t7_d1" [ ("2a", [("b", "45")]), ("4", [("b", "45")]) ]
        , cells "t7_e1" [ (r, zip ["b", "c"] vs) | (r, vs) <- [ ("2", ["345", "3124"]), ("3a", ["46", "5622"]), ("3b", ["875", "752"])
                                                            , ("3c", ["26", "654"]), ("3d", ["25", "7467"]), ("4", ["36", "765"]) ] ]
        , cells "t7_e2" [ (r, zip ["e2a", "e2b"] vs) | (r, vs) <- [ ("2", ["543", "365"]), ("3a", ["56", "22"]), ("3b", ["230", "203"])
                                                                , ("3c", ["2930", "093"]), ("3d", ["938", "930"]), ("4", ["855", "444"]) ] ]
        , cells "t7_f2" [ ("a1", zip ["b", "c", "d"] ["345", "83", "923"]), ("a2a", zip ["b", "c", "d"] ["234", "23", "22"])
                        , ("a2b", zip ["b", "c", "d"] ["22", "21", "13"]) ]
        , cells "t7_g2" [ ("a1", [("b", "31"), ("c", "76")]), ("a2", [("b", "63"), ("c", "73")]), ("a3", [("b", "26"), ("c", "72")]) ]
        , cells "t7_g3" [ ("a1", [("b", "87"), ("c", "76")]) ]
        , cells "t7_g4" [ (r, [("b", b), ("c", c)]) | (r, b, c) <- [ ("a1", "34", "35"), ("a2", "36", "37"), ("a3", "38", "39")
                                                                   , ("a4", "21", "22"), ("a5", "23", "24") ] ]
        ]
      printed = concat
        [ cells "t7_c14" [ ("1", [("a", "12")]), ("2", [("a", "12")]), ("2.2", [("b1", "172")]) ]
        , cells "t7_d1" [ ("1a", [("a", "12")]), ("2a", [("b2", "45")]), ("4", [("b2", "45")]) ]
        , cells "t7_d2" [ ("1", [("a", "45")]), ("3", [("a", "579")]) ]
        , cells "t7_c12" [ ("2.2", [("b", "412")]) ]
        , cells "t7_c4" [ ("2.2", [("a", "622")]) ]
        , cells "t7_e1" [ ("1", [("c", "1644")]), ("3", [("c", "1152")]) ]
        , cells "t7_e2" [ (r, [("e2", v)]) | (r, v) <- zip ["2", "3a", "3b", "3c", "3d", "4"] ["908", "78", "433", "3023", "1868", "1299"] ]
        , cells "t7_f2" [ ("a", zip ["b", "c", "d"] ["601", "127", "958"]), ("a2", zip ["b", "c", "d"] ["256", "44", "35"]) ]
        , cells "t7_g2" [ ("a", [("b", "120"), ("c", "221")]) ]
        , cells "t7_g3" [ ("a", [("b", "87"), ("c", "76")]) ]
        , cells "t7_g4" [ ("a", [("b", "152"), ("c", "157")]) ]
        ]
      derived = applyCalculations d entered
      -- Averages are rounded down to whole days, as printed in the PDF (622.69 as 622)
      sameNumber v got = got == Just v
      mismatches = [ (fid, v, M.lookup fid derived) | (fid, v) <- printed, not (sameNumber v (M.lookup fid derived)) ]
      violated = map (constraintId . violatedConstraint) (checkConstraints d entered)
      bCell = [ q | q <- allDialogueQuestions d, fieldId q == cellId "t7_b" "1" "b" ]
      prefilled q = fmap (KM.lookup "prefilled") (annotations q) == Just (Just (Bool True))
  expect (null (validateRules d)) ("Trial 7 rules are well-formed. " ++ show (validateRules d))
  expect (null mismatches) ("Trial 7 corrections reproduce " ++ show (length printed) ++ " more cells printed in the PDF. " ++ show mismatches)
  expect ("t7_c10_iAlt_1" `elem` violated && cellId "t7_c10" "1" "a" `notElem` map calcTarget (calculations d))
         "C10 a is entered and checked against b + c + d (the sample violates it)."
  expect (map prefilled bCell == [True] && map required bCell == [False])
         "B column b is prefilled and not required."

-- | Test 10: Verify enforceEvolutionPageOrder orders pages chronologically by schema evolution
testEvolutionPageOrdering :: IO ()
testEvolutionPageOrdering = do
  let initialPages = Array $ V.fromList
        [ String "S01_Forside"
        , String "S05_kostra51_side6"
        , String "S05_kostra51_side1"
        , String "S05_hack4ssb_hello"
        , String "S05_kostra51_kulturminner"
        , String "S05_hack4ssb_comprehensive"
        , String "S20_Summary"
        ]
      initialSettings = KM.fromList
        [ ("pages", Object $ KM.fromList
            [ ("groups", Array $ V.fromList
                [ Object $ KM.fromList [ ("order", initialPages) ]
                ])
            ])
        ]
      reordered = enforceEvolutionPageOrder initialSettings
      expectedOrder =
        [ "S01_Forside"
        , "S05_hack4ssb_hello"
        , "S05_hack4ssb_comprehensive"
        , "S05_kostra51_kulturminner"
        , "S05_kostra51_side1"
        , "S05_kostra51_side6"
        , "S20_Summary"
        ]
  case KM.lookup "pages" reordered of
    Just (Object pObj) ->
      case KM.lookup "groups" pObj of
        Just (Array grps) | not (V.null grps) ->
          case grps V.! 0 of
            Object gObj ->
              case KM.lookup "order" gObj of
                Just (Array ord) ->
                  let actual = [T.unpack s | String s <- V.toList ord]
                  in if actual == expectedOrder
                       then putStrLn "[PASS] Schema evolution page ordering verified."
                       else do
                         putStrLn $ "[FAIL] Unexpected page order: " ++ show actual
                         exitFailure
                _ -> exitFailure
            _ -> exitFailure
        _ -> exitFailure
    _ -> exitFailure

-- | Test 9: Verify Bolk round-trip JSON serialization and Altinn Header/Paragraph compilation
testBolkRoundTripAndCompilation :: IO ()
testBolkRoundTripAndCompilation = do
  let original = kostra51Side1Dialogue
      encoded = encodeDialogue original
  case decodeDialogue encoded of
    Left err -> do
      putStrLn $ "[FAIL] Bolk round-trip decode failed: " ++ err
      exitFailure
    Right decoded ->
      if decoded == original
        then do
          let artifacts = compileToAltinn decoded
          -- Check that Bolk title text keys are emitted
          if any (\(k, _) -> k == "lang.kostra51_side1.bolk.bolk_a.title") (textResources artifacts)
             && any (\(k, _) -> k == "lang.kostra51_side1.bolk.bolk_b1.title") (textResources artifacts)
            then putStrLn "[PASS] Bolk JSON round-trip and Altinn text resource generation verified."
            else do
              putStrLn "[FAIL] Bolk text resources missing from Altinn compilation."
              exitFailure
        else do
          putStrLn "[FAIL] Decoded Bolk dialogue does not match original."
          exitFailure

-- | Test 8: Verify compileToAltinn on KOSTRA 51 Sides 2-6 produces expected artifacts
testCompileKostra51AllSidesToAltinn :: IO ()
testCompileKostra51AllSidesToAltinn = do
  let a2 = compileToAltinn kostra51Side2Dialogue
      a3 = compileToAltinn kostra51Side3Dialogue
      a4 = compileToAltinn kostra51Side4Dialogue
      a5 = compileToAltinn kostra51Side5Dialogue
      a6 = compileToAltinn kostra51Side6Dialogue
  if pageName a2 == "S05_kostra51_side2"
     && pageName a3 == "S05_kostra51_side3"
     && pageName a4 == "S05_kostra51_side4"
     && pageName a5 == "S05_kostra51_side5"
     && pageName a6 == "S05_kostra51_side6"
    then putStrLn "[PASS] KOSTRA 51 Sides 2-6 Altinn artifact compilation verified."
    else do
      putStrLn "[FAIL] KOSTRA 51 Sides 2-6 Altinn compilation failed expectations."
      exitFailure

-- | Test 7: Verify compileToAltinn on KOSTRA 51 Side 1 dialogue produces full page 1
testCompileKostra51Side1ToAltinn :: IO ()
testCompileKostra51Side1ToAltinn = do
  let artifacts = compileToAltinn kostra51Side1Dialogue
  if pageName artifacts == "S05_kostra51_side1"
     && length (textResources artifacts) >= 30
    then putStrLn "[PASS] KOSTRA 51 Side 1 Altinn artifact compilation verified."
    else do
      putStrLn "[FAIL] KOSTRA 51 Side 1 Altinn compilation failed expectations."
      exitFailure

-- | Test 6: Verify compileToAltinn on KOSTRA 51 dialogue produces readOnly total sum and decimal questions
testCompileKostra51ToAltinn :: IO ()
testCompileKostra51ToAltinn = do
  let artifacts = compileToAltinn kostra51KulturminneDialogue
  if pageName artifacts == "S05_kostra51_kulturminner"
     && length (textResources artifacts) >= 14
    then putStrLn "[PASS] KOSTRA 51 Altinn artifact compilation verified."
    else do
      putStrLn "[FAIL] KOSTRA 51 Altinn compilation failed expectations."
      exitFailure

-- | Test 2b: Round-trip encode -> decode on comprehensive synthetic dialogue
testRoundTripSyntheticComprehensive :: IO ()
testRoundTripSyntheticComprehensive = do
  let original = syntheticHackDialogue
      encoded = encodeDialogue original
  case decodeDialogue encoded of
    Left err -> do
      putStrLn $ "[FAIL] Synthetic dialogue round-trip decode failed: " ++ err
      exitFailure
    Right decoded ->
      if decoded == original
        then putStrLn "[PASS] Comprehensive synthetic dialogue round-trip verified."
        else do
          putStrLn "[FAIL] Decoded synthetic dialogue does not match original."
          exitFailure

-- | Test 5: Verify compileToAltinn on synthetic dialogue produces all component types & conditional rules
testCompileSyntheticToAltinn :: IO ()
testCompileSyntheticToAltinn = do
  let artifacts = compileToAltinn syntheticHackDialogue
  if pageName artifacts == "S05_hack4ssb_comprehensive"
     && length (optionsLists artifacts) >= 3 -- PrimærTeknologi, OnskerVeiledning, StotteTemaer
     && length (textResources artifacts) >= 18
    then putStrLn "[PASS] Comprehensive synthetic Altinn artifact compilation verified."
    else do
      putStrLn "[FAIL] Comprehensive synthetic Altinn compilation failed expectations."
      exitFailure

-- | Test 4: Verify compileToAltinn produces valid page and components
testCompileToAltinn :: IO ()
testCompileToAltinn = do
  let artifacts = compileToAltinn helloWorldDialogue
  if pageName artifacts == "S05_hack4ssb_hello"
     && length (optionsLists artifacts) == 1
     && length (textResources artifacts) >= 4
    then putStrLn "[PASS] Altinn artifact compilation verified."
    else do
      putStrLn "[FAIL] Altinn artifact compilation failed expectations."
      exitFailure

-- | Test 1: Round-trip encode -> decode on helloWorldDialogue
testRoundTripHelloWorld :: IO ()
testRoundTripHelloWorld = do
  let original = helloWorldDialogue
      encoded = encodeDialogue original
  case decodeDialogue encoded of
    Left err -> do
      putStrLn $ "[FAIL] HelloWorld round-trip decode failed: " ++ err
      exitFailure
    Right decoded ->
      if decoded == original
        then putStrLn "[PASS] HelloWorld round-trip encode/decode verified."
        else do
          putStrLn "[FAIL] Decoded dialogue does not match original."
          exitFailure

-- | Test 2: Round-trip encode -> decode on dialogue with Choice question
testRoundTripWithChoice :: IO ()
testRoundTripWithChoice = do
  let dialogueWithChoice = Dialogue
        { dialogueId = "choice-test"
        , title      = "Choice Dialogue Test"
        , context    = Nothing
        , calculations = []
        , constraints  = []
        , steps      =
            [ QuestionStep Question
                { fieldId      = "category"
                , prompt       = Prompt "Select category" (Just "Choose one")
                , questionType = QChoice ["AI", "Figma", "Altinn"]
                , required     = False
                , condition    = Nothing
                , annotations  = Nothing
                }
            ]
        }
      encoded = encodeDialogue dialogueWithChoice
  case decodeDialogue encoded of
    Left err -> do
      putStrLn $ "[FAIL] Choice round-trip decode failed: " ++ err
      exitFailure
    Right decoded ->
      if decoded == dialogueWithChoice
        then putStrLn "[PASS] Choice question round-trip verified."
        else do
          putStrLn "[FAIL] Decoded choice dialogue does not match original."
          exitFailure

-- | Test 3: Decode failure on invalid JSON
testInvalidJSONHandling :: IO ()
testInvalidJSONHandling = do
  let invalidJson = "{\"dialogueId\": 12345}"
  case decodeDialogue invalidJson of
    Left _ -> putStrLn "[PASS] Invalid JSON rejected with error message as expected."
    Right _ -> do
      putStrLn "[FAIL] Invalid JSON unexpectedly decoded successfully."
      exitFailure

-- | Test 25: Trial 8 slice T8a relaxes bolk A (F-003) and leaves frozen Trial 7 untouched
testTrial8SliceA :: IO ()
testTrial8SliceA = do
  let reqIn d = [ (fieldId q, required q) | BolkStep b <- steps d, bolkId b == "bolk_a", q <- bolkQuestions b ]
  expect (all snd (reqIn trial7ByggesakDialogue)) "Trial 7 keeps all bolk A fields required (frozen baseline)."
  expect (reqIn trial8ByggesakDialogue == [ ("t7_kommunenummer", False), ("t7_kommunensNavn", False), ("t7_navnSkjemaansvarlig", False)
                                          , ("t7_telefonnummer", True), ("t7_epostSkjemaansvarlig", False) ])
         "Trial 8 T8a: only telefonnummer stays required in bolk A."

-- | Test 26: Trial 8 slice T8b (F-004) shows calculated cells unconditionally
testTrial8SliceB :: IO ()
testTrial8SliceB = do
  let gatedCalc d = [ fieldId q | BolkStep b <- steps d, q <- bolkQuestions b, fieldId q `elem` map calcTarget (calculations d), condition q /= Nothing ]
      afterB = t8bCalculatedAlwaysVisible (t8aBolkA trial7ByggesakDialogue)
  expect (not (null (gatedCalc trial7ByggesakDialogue))) "Trial 7 has conditional calculated cells (frozen baseline)."
  expect (gatedCalc afterB == ["t7_c3_2_1_c"]) "Trial 8 T8b: only the source-gated t7_c3_2_1_c stays conditional."

-- | Test 27: Trial 8 slice T8c resolves F-005 and remaining F-004
testTrial8SliceC :: IO ()
testTrial8SliceC = do
  let condOf d fid = case [ condition q | BolkStep b <- steps d, q <- bolkQuestions b, fieldId q == fid ] of
        (c:_) -> c
        []    -> Nothing
      gtZeroF fid = Just (Compare (Field fid) CmpGt (Const 0))
  -- F-004 rest: G1/G2/G3 cells are unconditional
  expect (all (\fid -> condOf trial8ByggesakDialogue fid == Nothing)
              [ "t7_g1_b1_b", "t7_g1_b1_c", "t7_g1_b2_b", "t7_g1_b2_c", "t7_g1_b3_b", "t7_g1_b3_c"
              , "t7_g2_b1_a", "t7_g2_b2_a", "t7_g2_b3_a", "t7_g3_a_a" ])
         "Trial 8 T8c: G1, G2, G3 cells are unconditional."
  -- F-005: missing gating added
  expect (condOf trial8ByggesakDialogue "t7_c12_1_b" == gtZeroF "t7_c12_1_a")
         "Trial 8 T8c: C12 row 1 col b gated on row 1 col a."
  expect (condOf trial8ByggesakDialogue "t7_c12_2_b" == gtZeroF "t7_c12_2_a")
         "Trial 8 T8c: C12 row 2 col b gated on row 2 col a."
  expect (condOf trial8ByggesakDialogue "t7_c3_1_c" == gtZeroF "t7_c3_1_a")
         "Trial 8 T8c: C3 row 1 col c gated on row 1 col a."
  expect (condOf trial8ByggesakDialogue "t7_c3_2_c" == gtZeroF "t7_c3_2_a")
         "Trial 8 T8c: C3 row 2 col c gated on row 2 col a."
  expect (condOf trial8ByggesakDialogue "t7_d2_1_a" == gtZeroF "t7_c10_2_f")
         "Trial 8 T8c: D2 row 1 gated on C10 row 2 col f."
  expect (condOf trial8ByggesakDialogue "t7_d2_3_a" == gtZeroF "t7_c4_2_a")
         "Trial 8 T8c: D2 row 3 gated on C4 row 2 col a."
  expect (all (\fid -> condOf trial8ByggesakDialogue fid == gtZeroF "t7_f2_a_a")
              [ "t7_f2_a_b", "t7_f2_a_c", "t7_f2_a_d" ])
         "Trial 8 T8c: F2 row a cols b, c, d gated on row a col a."

-- | Test 28: Trial 8 slice T8d (F-008) aligns calculation inputs with XML4DR
testTrial8SliceD :: IO ()
testTrial8SliceD = do
  let exprOf d fid = case [ calcExpr c | c <- calculations d, calcTarget c == fid ] of
        (e:_) -> e
        []    -> error ("calculation not found: " ++ fid)
  -- D1 row 1b: area restriction rows 2, 3, 4, 5, 6, 7 (not 2a)
  expect (exprOf trial8ByggesakDialogue "t7_d1_1b_a" == Add [ Field ("t7_d1_" ++ r ++ "_a") | r <- ["2", "3", "4", "5", "6", "7"] ])
         "Trial 8 T8d: D1 1b col a sums main rows 2-7."
  expect (exprOf trial8ByggesakDialogue "t7_d1_1b_b1" == Add [ Field ("t7_d1_" ++ r ++ "_b1") | r <- ["2", "3", "5"] ])
         "Trial 8 T8d: D1 1b col b1 sums rows 2, 3, 5."
  -- C14 columns b2 and d read C10, C11, C12, C13 directly
  expect (exprOf trial8ByggesakDialogue "t7_c14_1_b2" == Add [ Field "t7_c11_1_b", Field "t7_c12_1_b2", Field "t7_c13_1_b2" ])
         "Trial 8 T8d: C14 row 1 col b2 sums C11, C12, C13."
  expect (exprOf trial8ByggesakDialogue "t7_c14_1_d" == Add [ Field "t7_c10_1_b", Field "t7_c12_1_d", Field "t7_c13_1_d" ])
         "Trial 8 T8d: C14 row 1 col d sums C10, C12, C13."

-- | Test 29: Trial 8 slice T8e (F-002, F-003) introduces RequiredLevel:
-- 1. 106 F-002 soft-required fields have questionRequiredLevel == ReqWarn and required == False.
-- 2. 24 F-003 fields have questionRequiredLevel == ReqNone and required == False.
-- 3. In Trial 7, those 24 F-003 fields had required == True and no soft warnings.
-- 4. In Trial 8, remaining required fields have questionRequiredLevel == ReqError.
-- 5. JSON serialization round-trips correctly with levels.
testTrial8SliceE :: IO ()
testTrial8SliceE = do
  let qOf d fid = case [ q | q <- allDialogueQuestions d, fieldId q == fid ] of
        (q:_) -> q
        []    -> error ("question not found: " ++ fid)
  -- F-003: C10, Bolk I, radios relaxed to ReqNone
  let f003Sample = ["t7_c10_1_a", "t7_e0a_klagerMottattEllerBehandlet", "t7_f0a_erUtfoertTilsyn", "t7_elektroniskSakssystemBrukt", "t7_timerUtfylling"]
  expect (all (\fid -> required (qOf trial7ByggesakDialogue fid)) f003Sample)
         "Trial 7 baseline: F-003 fields were required."
  expect (all (\fid -> questionRequiredLevel (qOf trial8ByggesakDialogue fid) == ReqNone && not (required (qOf trial8ByggesakDialogue fid))) f003Sample)
         "Trial 8 T8e: F-003 fields are ReqNone and not required."

  -- F-002: soft required fields have ReqWarn
  let f002Sample = ["t7_b_1_a", "t7_c11_2_b", "t7_c12_1_b", "t7_d1_2_a", "t7_d2_1_b", "t7_e1_2_d", "t7_e2_2_e", "t7_f2_a_a"]
  expect (all (\fid -> questionRequiredLevel (qOf trial7ByggesakDialogue fid) == ReqNone) (filter (/= "t7_f2_a_a") f002Sample))
         "Trial 7 baseline: F-002 fields had no soft warning level."
  expect (all (\fid -> questionRequiredLevel (qOf trial8ByggesakDialogue fid) == ReqWarn && not (required (qOf trial8ByggesakDialogue fid))) f002Sample)
         "Trial 8 T8e: F-002 fields have ReqWarn and required == False."

  -- Regular required fields have ReqError
  let reqSample = ["t7_telefonnummer"]
  expect (all (\fid -> questionRequiredLevel (qOf trial8ByggesakDialogue fid) == ReqError && required (qOf trial8ByggesakDialogue fid)) reqSample)
         "Trial 8 T8e: hard required fields have ReqError and required == True."

  -- JSON round-trip preserves required level
  let encoded = encodeDialogue trial8ByggesakDialogue
  case decodeDialogue encoded of
    Left err -> error ("decode failed: " ++ err)
    Right d8 -> do
      expect (all (\fid -> questionRequiredLevel (qOf d8 fid) == ReqWarn) f002Sample)
             "Trial 8 T8e: ReqWarn survives JSON round-trip."
      expect (all (\fid -> questionRequiredLevel (qOf d8 fid) == ReqNone) f003Sample)
             "Trial 8 T8e: ReqNone survives JSON round-trip."

testTrial9 :: IO ()
testTrial9 = do
  let qOf d fid = case [ q | BolkStep b <- steps d, q <- bolkQuestions b, fieldId q == fid ] of
        (q:_) -> q
        []    -> error ("question not found: " ++ fid)

  -- Trial 8 baseline: t7_d1_3_a was unconditional
  expect (condition (qOf trial8ByggesakDialogue "t7_d1_3_a") == Nothing)
         "Trial 8: D1 row 3 was unconditional."

  -- Trial 9 T9a: D1 row 3 is gated on coastal municipality context (F-009 resolved)
  expect (condition (qOf trial9ByggesakDialogue "t7_d1_3_a") /= Nothing)
         "Trial 9 T9a: D1 row 3 is conditional (F-009 resolved)."

  -- Trial 9 T9b: plausibility constraints softened to SeverityWarn
  let overFristConstraints = [ c | c <- constraints trial9ByggesakDialogue, "overFrist" `isInfixOf` constraintId c ]
  expect (not (null overFristConstraints) && all (\c -> severity c == SevWarning) overFristConstraints)
         "Trial 9 T9b: overFrist constraints have SevWarning."

  -- JSON round-trip of Trial 9
  let encoded = encodeDialogue trial9ByggesakDialogue
  case decodeDialogue encoded of
    Left err -> error ("decode failed: " ++ err)
    Right d9 -> do
      expect (dialogueId d9 == "trial9-byggesak")
             "Trial 9: dialogueId round-trip."

