module Main where

import qualified Data.ByteString.Lazy.Char8 as BLC
import SchemaDSL

main :: IO ()
main = do
  putStrLn "Dialogue Schema DSL - Hello World"
  BLC.putStrLn (encodeDialogue helloWorldDialogue)
