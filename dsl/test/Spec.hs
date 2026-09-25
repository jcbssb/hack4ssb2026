{-# LANGUAGE OverloadedStrings #-}

module Main where

import System.Exit (exitFailure, exitSuccess)
import Data.Aeson (Value(..), encode)
import qualified Data.ByteString.Lazy.Char8 as BLC
import qualified Data.Aeson.KeyMap as KM
import qualified Data.Vector as V
import qualified Data.Text as T
import qualified Data.Map.Strict as M
import SchemaDSL

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
                 , trial3ByggesakDialogue, trial4ByggesakDialogue, budgetDialogue, rulesDemoDialogue ]
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
  expect ("t4_timerTotalt-number" `T.isInfixOf` T.pack layoutTxt
          && not ("t4_timerTotalt-input" `T.isInfixOf` T.pack layoutTxt))
         "Calculated fields compile to display-only Number components."
  expect ("SkjemaData.trial4_byggesak.t4_e1_klagerKommuneAlt" `elem` paths
          && "SkjemaData.trial4_byggesak.t4_c10_delingBehandlet" `elem` paths
          && any ((== "lang.trial4_byggesak.constraint.t4_e1_herav") . fst) (textResources artifacts))
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
