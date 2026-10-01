module Main (main) where

import qualified Data.Text as T
import Text.XML (def, readFile, documentRoot, elementName, nameLocalName)
import Prelude hiding (readFile)
import System.Environment (getArgs)

main :: IO ()
main = do
  [path] <- getArgs
  doc <- readFile def path
  putStrLn (T.unpack (nameLocalName (elementName (documentRoot doc))))
