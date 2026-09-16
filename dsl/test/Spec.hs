{-# LANGUAGE OverloadedStrings #-}

module Main where

import System.Exit (exitFailure, exitSuccess)
import SchemaDSL

main :: IO ()
main = do
  putStrLn "Running SchemaDSL test suite..."
  testRoundTripHelloWorld
  testRoundTripWithChoice
  testInvalidJSONHandling
  putStrLn "All SchemaDSL tests passed successfully!"
  exitSuccess

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
