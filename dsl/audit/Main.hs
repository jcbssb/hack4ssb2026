{-# LANGUAGE OverloadedStrings #-}
module Main (main) where

import Audit.Export (encodeFacts)
import qualified Data.ByteString.Lazy as BL
import Audit.Index
import Audit.Xml4dr
import qualified Data.Map.Strict as M
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import System.Environment (getArgs)
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)

main :: IO ()
main = do
  args <- getArgs
  case args of
    ["outline", p]            -> loadForm p >>= outline
    ["cell", p, q]            -> loadForm p >>= \f -> mapM_ (cellView f) (take 5 (lookupCells f (T.toLower (T.pack q))))
    ["extract", p, o]         -> loadForm p >>= \f -> BL.writeFile o (encodeFacts f) >> out ("wrote " <> T.pack o)
    ["around", p, q]          -> loadForm p >>= \f -> mapM_ (around f) (take 1 (lookupCells f (T.toLower (T.pack q))))
    _ -> hPutStrLn stderr "usage: schema-audit (outline|cell|around|extract) <xml4dr.xml> [cell-key|text]" >> exitFailure

out :: T.Text -> IO ()
out = TIO.putStrLn

outline :: Form -> IO ()
outline f = do
  out (formId f <> ": " <> formTitle f)
  out "section (path)                          rows cells  input calc  prefl radio | gated checks req"
  mapM_ row (sections f)
  where
    row s = do
      let cs = [ c | c <- cells f, cSet c == secId s ]
          n k = length [ c | c <- cs, kindOf f c == k ]
          gated = length [ c | c <- cs, not (null (controllersOf f c)) ]
          checks = sum [ length (ownChecks f c) | c <- cs ]
          req = length [ c | c <- cs, isRequired f c ]
          pad k t = T.take k (t <> T.replicate k " ")
          ttl = short 38 (T.intercalate " | " (secTitle s))
      out (T.pack (replicate (2 * (length (secPath s) - 1)) ' ') <> pad 12 (secId s) <> " "
           <> pad 40 ttl <> " " <> T.pack (unwords (map show [secRows s, length cs, n KInput, n KCalculated, n KPrefilled, n KRadio]))
           <> " | " <> T.pack (unwords (map show [gated, checks, req])))

cellView :: Form -> Cell -> IO ()
cellView f c = do
  out ("== " <> cellKey c <> "  [" <> T.pack (show (kindOf f c)) <> "]  row " <> T.pack (show (cRow c)) <> " col " <> T.pack (show (cCol c))
       <> "  section: " <> short 60 (T.intercalate " | " (concat [ secTitle s | s <- sections f, secId s == cSet c ])))
  out ("  row text : " <> short 120 (T.intercalate " | " (rowLabelOf f c)))
  out ("  header   : " <> short 100 (T.intercalate " | " (headerOf f c)))
  out ("  text nb  : " <> short 140 (T.intercalate " | " (cText c)))
  out ("  text nn  : " <> short 140 (T.intercalate " | " (cNn c)))
  out ("  control  : " <> T.pack (show (cControl c)) <> " size " <> T.pack (show (cSize c)) <> " value " <> T.pack (show (cValue c))
       <> " styles " <> T.pack (show (cStyles c)))
  mapM_ (\h -> out ("  calc     : " <> short 220 (hEval h))) (ownCalc f c)
  mapM_ (\h -> out ("  check    : " <> short 140 (hEval h) <> "  => " <> short 100 (T.intercalate "; " [ describe e | a <- hActions h, e <- aEffects a ]))) (ownChecks f c)
  mapM_ (\h -> out ("  controls : " <> short 100 (hEval h) <> "  -> " <> T.pack (show (length (concat [ ps | a <- hActions h, SetState _ ps <- aEffects a ]))) <> " cells")) (ownGuidance f c)
  mapM_ (\(src, h, ws) -> out ("  gated by : " <> cellKey src <> "  when " <> short 100 (hEval h) <> "  " <> T.pack (show ws))) (controllersOf f c)
  out ("  reads    : " <> T.intercalate ", " [ a <> "/" <> b | (a, b) <- refsOut f c ])
  out ("  read by  : " <> T.intercalate ", " (map cellKey (refsIn f c)))
  where
    describe (MsgBox ts) = "msg: " <> T.unwords ts
    describe (SetError e) = e
    describe _ = ""

around :: Form -> Cell -> IO ()
around f c = do
  cellView f c
  out "-- same row:"
  mapM_ line [ o | o <- cells f, cSet o == cSet c, cRow o == cRow c, cellKey o /= cellKey c ]
  out "-- same column (nearest rows):"
  mapM_ line (take 6 [ o | o <- cells f, cSet o == cSet c, cCol o == cCol c, abs (cRow o - cRow c) <= 3, cellKey o /= cellKey c ])
  out "-- reads from:"
  mapM_ line [ o | (a, b) <- refsOut f c, o <- cells f, cSet o == a, cData o == b ]
  out "-- read by:"
  mapM_ line (refsIn f c)
  where
    line o = out ("  " <> T.justifyLeft 22 ' ' (cellKey o) <> T.justifyLeft 11 ' ' (kindName (kindOf f o))
                  <> "r" <> T.pack (show (cRow o)) <> "c" <> T.pack (show (cCol o)) <> "  "
                  <> short 60 (T.intercalate " | " (cText o ++ (if null (cText o) then rowLabelOf f o else []))))

_u :: M.Map Int Int
_u = M.empty
