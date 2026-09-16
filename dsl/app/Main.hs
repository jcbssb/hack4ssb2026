{-# LANGUAGE OverloadedStrings #-}

module Main where

import System.Environment (getArgs)
import System.Exit (exitFailure)
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString.Lazy.Char8 as BLC
import Data.Aeson.Encode.Pretty (encodePretty)
import SchemaDSL

main :: IO ()
main = do
  args <- getArgs
  case args of
    ["--update-baseline"] -> do
      let outPath = "baseline-schema.json"
      BL.writeFile outPath (encodePretty helloWorldDialogue)
      putStrLn $ "Successfully wrote baseline schema to: " ++ outPath

    ["--emit-meta"] -> do
      let outPath = "baseline-schema-meta.json"
      BL.writeFile outPath encodeMetaSchemaPretty
      putStrLn $ "Successfully emitted schema metaschema to: " ++ outPath

    ["--update-all"] -> do
      BL.writeFile "baseline-schema-meta.json" encodeMetaSchemaPretty
      BL.writeFile "baseline-schema.json" (encodePretty helloWorldDialogue)
      putStrLn "Successfully updated both baseline-schema-meta.json and baseline-schema.json!"

    ["--print-baseline"] ->
      BLC.putStrLn (encodePretty helloWorldDialogue)

    ["--print-meta"] ->
      BLC.putStrLn encodeMetaSchemaPretty

    _ -> do
      putStrLn "Dialogue Schema DSL CLI"
      putStrLn "Usage:"
      putStrLn "  cabal run schema-dsl-cli -- --update-baseline   # Write dsl/baseline-schema.json"
      putStrLn "  cabal run schema-dsl-cli -- --emit-meta         # Write dsl/baseline-schema-meta.json"
      putStrLn "  cabal run schema-dsl-cli -- --update-all        # Write both meta and baseline schemas"
      putStrLn "  cabal run schema-dsl-cli -- --print-baseline    # Print baseline JSON to stdout"
      putStrLn "  cabal run schema-dsl-cli -- --print-meta        # Print meta schema JSON to stdout"
      exitFailure
