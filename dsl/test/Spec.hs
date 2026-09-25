{-# LANGUAGE OverloadedStrings #-}

module Main where

import System.Exit (exitFailure, exitSuccess)
import Data.Aeson (Value(..), encode)
import qualified Data.ByteString.Lazy.Char8 as BLC
import qualified Data.Aeson.KeyMap as KM
import qualified Data.Vector as V
import qualified Data.Text as T
import qualified Data.Map.Strict as M
import Data.List (nub)
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
  testMatrixDemo
  testPagedAltinn
  testCSharpClassRemoval
  testAppTitle
  testTrial7AuditFixes
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
                 , trial3ByggesakDialogue, trial4ByggesakDialogue, trial5ByggesakDialogue, trial6ByggesakDialogue, trial7ByggesakDialogue, budgetDialogue, rulesDemoDialogue, matrixDemoDialogue ]
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
      -- The PDF truncates averages to whole days (622.69 is printed as 622)
      sameNumber v got = case (reads v :: [(Double, String)], got >>= \g -> case reads g :: [(Double, String)] of { [(x, "")] -> Just x; _ -> Nothing }) of
        ([(x, "")], Just y) -> (truncate x :: Integer) == truncate y
        _ -> False
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
