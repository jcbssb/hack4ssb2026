{-# LANGUAGE OverloadedStrings #-}
-- | Derived relations over a Form: kinds, controllers, data-flow.
module Audit.Index
  ( Kind(..), kindOf, ownCalc, ownChecks, ownGuidance, controllersOf, refsOut, refsIn
  , isRequired, headerOf, rowLabelOf, kindName, lookupCells, short, T.Text
  ) where

import Audit.Xml4dr
import qualified Data.Map.Strict as M
import Data.List (nub)
import Data.Maybe (mapMaybe, listToMaybe)
import qualified Data.Text as T

data Kind = KLabel | KInput | KCalculated | KPrefilled | KRadio
  deriving (Eq, Ord, Show)

short :: Int -> T.Text -> T.Text
short n t = let s = T.unwords (T.words t) in if T.length s > n then T.take (n - 1) s <> "…" else s

hs :: Form -> Cell -> [Handler]
hs f c = mapMaybe (`M.lookup` handlers f) (cHandlers c)

ownCalc :: Form -> Cell -> [Handler]
ownCalc f = filter ((== Just "calculation") . hType) . hs f

ownGuidance :: Form -> Cell -> [Handler]
ownGuidance f = filter ((== Just "guidance") . hType) . hs f

ownChecks :: Form -> Cell -> [Handler]
ownChecks f = filter ((== Nothing) . hType) . hs f

isRequired :: Form -> Cell -> Bool
isRequired f c = any (\h -> "FieldFilled(obThis)" `T.isInfixOf` hEval h) (ownChecks f c)

kindOf :: Form -> Cell -> Kind
kindOf f c
  | not (null (ownCalc f c)) = KCalculated
  | cControl c == Just "radioButton" = KRadio
  | cControl c == Just "textBox" = if "background-color:rgb(120,120,120)" `elem` map (T.filter (/= ' ')) (cStyles c) then KPrefilled else KInput
  | otherwise = KLabel

-- | Guidance handlers elsewhere that set the state of this cell: (controller cell key, handler, state when true/false).
controllersOf :: Form -> Cell -> [(Cell, Handler, [(T.Text, T.Text)])]
controllersOf f c =
  [ (src, h, [ (aWhen a, st) | a <- hActions h, SetState st ps <- aEffects a, (cSet c, cData c) `elem` ps ])
  | src <- cells f, h <- ownGuidance f src
  , any (\a -> or [ (cSet c, cData c) `elem` ps | SetState _ ps <- aEffects a ]) (hActions h) ]

refsOut :: Form -> Cell -> [(T.Text, T.Text)]
refsOut f c = nub (concatMap (handlerRefs . hEval) (hs f c))

refsIn :: Form -> Cell -> [Cell]
refsIn f c = [ o | o <- cells f, (cSet c, cData c) `elem` refsOut f o, cellKey o /= cellKey c ]

rowLabelOf :: Form -> Cell -> [T.Text]
rowLabelOf f c = nub (cRowText c ++ concat
  [ cText o | o <- cells f, cSet o == cSet c, cRow o == cRow c, kindOf f o == KLabel ])

kindName :: Kind -> T.Text
kindName k = case k of
  KLabel -> "label"; KInput -> "input"; KCalculated -> "calculated"; KPrefilled -> "prefilled"; KRadio -> "radio"

headerOf :: Form -> Cell -> [T.Text]
headerOf f c = take 2 (nub (concat
  [ cText o | o <- cells f, cSet o == cSet c, cCol o == cCol c, cRow o < cRow c, kindOf f o == KLabel ]))

lookupCells :: Form -> T.Text -> [Cell]
lookupCells f q = case filter ((== q) . cellKey) (cells f) of
  [] -> [ c | c <- cells f, q `T.isInfixOf` T.toLower (T.unwords (cText c ++ rowLabelOf f c ++ [cellKey c])) ]
  xs -> xs

_unused :: [a] -> Maybe a
_unused = listToMaybe
