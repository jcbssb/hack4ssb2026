{-# LANGUAGE OverloadedStrings #-}
module Main (main) where

import Audit.Export (encodeFacts)
import qualified Data.ByteString.Lazy as BL
import Audit.Eval
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
    ["evals", p]              -> loadForm p >>= evals
    ["trace", p, q]           -> loadForm p >>= \f -> mapM_ (trace f) (take 1 (lookupCells f (T.toLower (T.pack q))))
    ["grep-eval", p, q]       -> loadForm p >>= \f -> grepEval f (T.pack q)
    ["around", p, q]          -> loadForm p >>= \f -> mapM_ (around f) (take 1 (lookupCells f (T.toLower (T.pack q))))
    _ -> hPutStrLn stderr "usage: schema-audit (outline|cell|around|trace|grep-eval|extract|evals) <xml4dr.xml> [cell-key|text]" >> exitFailure

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
  mapM_ (\h -> out ("  calc     : " <> short 240 (parsed h))) (ownCalc f c)
  mapM_ (\h -> out ("  check    : " <> short 160 (parsed h) <> "  => " <> short 100 (T.intercalate "; " [ describe e | a <- hActions h, e <- aEffects a ]))) (ownChecks f c)
  mapM_ (\h -> out ("  controls : " <> short 100 (parsed h) <> "  -> " <> T.pack (show (length (concat [ ps | a <- hActions h, SetState _ ps <- aEffects a ]))) <> " cells")) (ownGuidance f c)
  mapM_ (\(src, h, ws) -> out ("  gated by : " <> cellKey src <> "  when " <> short 100 (hEval h) <> "  " <> T.pack (show ws))) (controllersOf f c)
  out ("  reads    : " <> T.intercalate ", " [ a <> "/" <> b | (a, b) <- refsOut f c ])
  out ("  read by  : " <> T.intercalate ", " (map cellKey (refsIn f c)))
  where
    parsed h = either (const (hEval h)) pretty (parseEval (hEval h))
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

-- | Parse every handler Eval; report coverage and the failures.
evals :: Form -> IO ()
evals f = do
  let rs = [ (h, parseEval (hEval h)) | h <- M.elems (handlers f) ]
      bad = [ (h, e) | (h, Left e) <- rs ]
  out ("handlers " <> T.pack (show (length rs)) <> ", parsed " <> T.pack (show (length rs - length bad))
       <> ", unparsed " <> T.pack (show (length bad)))
  mapM_ (\(h, e) -> out ("  " <> hId h <> ": " <> short 90 (hEval h) <> "\n      " <> T.pack (takeWhile (/= '\n') (drop 12 e)))) bad

-- | Upstream (what feeds the cell) and downstream (what it feeds or gates), transitively.
trace :: Form -> Cell -> IO ()
trace f c = do
  out ("== " <> cellKey c <> " " <> label c)
  out "-- upstream (calc/check inputs, transitive):"
  walk (\o -> [ x | (a, b) <- refsOut f o, x <- cells f, cSet x == a, cData x == b, cellKey x /= cellKey o ]) 1 [cellKey c] [c]
  out "-- downstream (read by, transitive):"
  walk (refsIn f) 1 [cellKey c] [c]
  out "-- gated by:"
  mapM_ (\(s, h, _) -> out ("  " <> cellKey s <> "  when " <> short 90 (either (const (hEval h)) pretty (parseEval (hEval h))))) (controllersOf f c)
  where
    label o = "[" <> kindName (kindOf f o) <> "] " <> short 50 (T.intercalate " | " (rowLabelOf f o ++ headerOf f o))
    walk _ _ _ [] = pure ()
    walk step d seen frontier = do
      let next = [ x | o <- frontier, x <- step o ]
          fresh = dedupe seen next
      mapM_ (\x -> out (T.replicate (2 * d) " " <> cellKey x <> " " <> label x)) fresh
      if d >= 4 then pure () else walk step (d + 1) (seen ++ map cellKey fresh) fresh
    dedupe seen xs = go' seen xs
      where go' _ [] = []
            go' s (y : ys) | cellKey y `elem` s = go' s ys
                           | otherwise = y : go' (cellKey y : s) ys

-- | Search rule expressions, texts and messages (case-insensitive substring).
grepEval :: Form -> T.Text -> IO ()
grepEval f q = do
  let ql = T.toLower q
      msgs h = concat [ ts | a <- hActions h, MsgBox ts <- aEffects a ]
      hit h = ql `T.isInfixOf` T.toLower (T.unwords (hEval h : msgs h))
      owners h = [ cellKey c | c <- cells f, hId h `elem` cHandlers c ]
  mapM_ (\h -> out (hId h <> " " <> T.pack (show (hType h)) <> " on " <> short 60 (T.unwords (owners h)) <> "\n    "
                    <> short 200 (either (const (hEval h)) pretty (parseEval (hEval h)))
                    <> (if null (msgs h) then "" else "\n    msg: " <> short 160 (T.unwords (msgs h)))))
        (take 20 (filter hit (M.elems (handlers f))))
