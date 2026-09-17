{-# LANGUAGE OverloadedStrings #-}

module Main where

import System.Exit (exitFailure, exitSuccess)
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
  putStrLn "All SchemaDSL tests passed successfully!"
  exitSuccess

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
        , steps      =
            [ Question
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
