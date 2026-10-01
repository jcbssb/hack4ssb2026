{-# LANGUAGE OverloadedStrings #-}
-- | Align DSL fields with XML4DR cells (P3). Layers: overrides, matrix (row,col) keys, label match,
--   fuzzy label match, singleton. Reports matched / dsl-only / xml-only plus attribute diffs.
module Audit.Align (Config (..), loadConfig, align, alignMany, Match (..), Report (..), cellLabel, renderReport, encodeAlign) where

import Audit.Dsl
import Audit.Eval (pretty, parseEval)
import Audit.Index
import Audit.Xml4dr
import Data.Aeson (Value (..), eitherDecodeFileStrict, object, (.=), encode)
import qualified Data.ByteString.Lazy as BL
import qualified Data.Aeson.Key as K
import qualified Data.Aeson.KeyMap as KM
import Data.Char (isAlphaNum, isDigit, isLower)
import qualified Data.Foldable as F
import Data.List (sortOn)
import qualified Data.Map.Strict as M
import Data.Maybe (fromMaybe, listToMaybe, mapMaybe)
import qualified Data.Set as S
import Data.Text (Text)
import qualified Data.Text as T

data Config = Config
  { cfgBolks :: M.Map Text [Text]          -- ^ DSL bolkId -> XML4DR section ids
  , cfgOverrides :: M.Map Text (Text, Text) -- ^ DSL fieldId -> (cell key, reason)
  , cfgExplained :: M.Map Text (Text, Text) -- ^ XML cell key -> (class, reason) for deliberate xml-only cells
  } deriving Show

loadConfig :: FilePath -> IO Config
loadConfig p = do
  r <- eitherDecodeFileStrict p
  case r of
    Left e -> fail ("config: " <> e)
    Right v -> pure Config
      { cfgBolks = M.fromList [ (K.toText k, [ t | String t <- F.toList a ]) | Just (Object o) <- [lk "bolks" v], (k, Array a) <- KM.toList o ]
      , cfgOverrides = M.fromList [ (f, (c, rs)) | e <- arr "overrides" v, Just f <- [s "field" e], Just c <- [s "cell" e], let rs = fromMaybe "" (s "reason" e) ]
      , cfgExplained = M.fromList [ (c, (cl, rs)) | e <- arr "explained" v, Just c <- [s "cell" e], let cl = fromMaybe "" (s "class" e), let rs = fromMaybe "" (s "reason" e) ]
      }
  where
    lk k (Object o) = KM.lookup (K.fromText k) o
    lk _ _ = Nothing
    arr k v = case lk k v of Just (Array a) -> F.toList a; _ -> []
    s k v = case lk k v of Just (String t) -> Just t; _ -> Nothing

data Match = Match { mField :: DField, mCell :: Cell, mHow :: Text, mDiffs :: [Text] }

data Report = Report
  { rBolk :: Text, rMatched :: [Match], rDslOnly :: [DField], rXmlOnly :: [Cell], rExplained :: [(Cell, Text, Text)] }

norm :: Text -> Text
norm = T.unwords . T.words . T.map (\c -> if isAlphaNum c then c else ' ') . T.toLower

-- | "2.1." / "1a." / "I.2a" style leading number of a text -> key such as "2.1" or "2a".
numKey :: Text -> Maybe Text
numKey t0 = do
  let t = case T.unpack (T.take 2 t0) of
            [c, '.'] | c `elem` ['A' .. 'Z'] -> T.drop 2 t0
            _ -> t0
  w <- listToMaybe (T.words t)
  let k = T.dropWhileEnd (== '.') w
  if validRow (T.unpack k) then Just k else Nothing
  where
    validRow s = case span isDigit s of
      ([], _) -> False
      (_, r) -> all (\c -> isLower c || isDigit c || c == '.') r && length (filter isLower r) <= 1

colKey :: Text -> Maybe Text
colKey t = do
  w <- listToMaybe (T.words t)
  let k = T.dropWhileEnd (== '.') w
  case T.unpack k of
    (c : ds) | isLower c, all isDigit ds, T.length w == T.length k + 1 -> Just k
    (c : d : ds) | isLower c, isDigit d, [l] <- dropWhile isDigit ds, isLower l, T.length w == T.length k + 1 -> Just k
    [c, d, l] | isLower c, isDigit d, isLower l, T.length w == T.length k + 1 -> Just k
    [c, '.', d] | isLower c, isDigit d -> Just (T.pack [c, d])
    _ -> Nothing

jaccard :: Text -> Text -> Double
jaccard a b =
  let sa = S.fromList (T.words (norm a)); sb = S.fromList (T.words (norm b))
      i = S.size (S.intersection sa sb); u = S.size (S.union sa sb)
  in if u == 0 then 0 else fromIntegral i / fromIntegral u

cellRowKey, cellColKey :: Form -> Cell -> Maybe Text
cellRowKey f c = listToMaybe (mapMaybe numKey (rowLabelOf f c ++ cText c))
cellColKey f c = listToMaybe (mapMaybe colKey (headerOf f c))

cellLabel :: Form -> Cell -> Text
cellLabel f c = fromMaybe "" (listToMaybe (cText c ++ rowLabelOf f c))

answerable :: Form -> Cell -> Bool
answerable f c = kindOf f c /= KLabel

-- | Align several bolks; cross-bolk cell/field links are resolved for calc and check comparison.
alignMany :: Form -> Config -> [DField] -> [Text] -> [Report]
alignMany f cfg dsl bs = rs
  where
    rs = [ alignWith gmap copies f cfg dsl b | b <- bs ]
    copies = M.fromList [ (dId x, r) | x <- dsl, Just r <- [dCopyOf x] ]
    gmap = M.fromList [ (cellKey (mCell m), dId (mField m)) | r <- rs, m <- rMatched r ]

align :: Form -> Config -> [DField] -> Text -> Report
align = alignWith M.empty M.empty

alignWith :: M.Map Text Text -> M.Map Text Text -> Form -> Config -> [DField] -> Text -> Report
alignWith gmap copies f cfg dsl bolk =
  let secs = fromMaybe [] (M.lookup bolk (cfgBolks cfg))
      fs = [ d | d <- dsl, dBolk d == bolk ]
      cs = [ c | c <- cells f, cSet c `elem` secs, answerable f c ]
      byKey = M.fromList [ (cellKey c, c) | c <- cs ]
      -- layer 0: overrides
      ov = [ (d, c, "override") | d <- fs, Just (ck, _) <- [M.lookup (dId d) (cfgOverrides cfg)], Just c <- [M.lookup ck byKey] ]
      step ms how pick remainingD remainingC =
        let new = [ (d, c, how) | d <- remainingD, Just c <- [pick d remainingC] ]
            -- keep only one DSL field per cell (first wins)
            uniq = M.elems (M.fromListWith (\_ old -> old) [ (cellKey c, (d, c, h)) | (d, c, h) <- reverse new ])
            usedD = S.fromList [ dId d | (d, _, _) <- uniq ]
        in (ms ++ uniq, [ d | d <- remainingD, dId d `S.notMember` usedD ], [ c | c <- remainingC, cellKey c `notElem` map (\(_, x, _) -> cellKey x) uniq ])
      free0 = ([ x | x@(d, _, _) <- ov ], [ d | d <- fs, dId d `notElem` [ dId x | (x, _, _) <- ov ] ], [ c | c <- cs, cellKey c `notElem` [ cellKey x | (_, x, _) <- ov ] ])
      uniqueBy keyD keyC d rc = case [ c | Just k <- [keyD d], c <- rc, keyC c == Just k ] of
        [c] -> Just c
        _ -> Nothing
      matrixPick d rc = case (dRow d, dCol d) of
        (Just r, Just cl) -> case [ c | c <- rc, cellRowKey f c == Just r, cellColKey f c == Just cl ] of
          [c] -> Just c
          _ -> Nothing
        _ -> Nothing
      numPick d rc = case (dRow d, numKey (dLabel d)) of
        (Nothing, Just k) -> uniqueBy (const (Just k)) (cellRowKey f) d (filter (\c -> cellColKey f c == Nothing) rc)
        _ -> Nothing
      exactPick d rc = case [ c | c <- rc, norm (cellLabel f c) == norm (stripLead (dLabel d)) ] of
        [c] -> Just c
        _ -> Nothing
      fuzzyPick d rc =
        let sc = sortOn (negate . fst) [ (jaccard (stripLead (dLabel d)) (cellLabel f c), c) | c <- rc ]
        in case sc of
          ((a, c) : rest) | a >= 0.6, all ((< a - 0.15) . fst) (take 1 rest) -> Just c
          _ -> Nothing
      single d rc = if length fs == 1 && length rc == 1 then listToMaybe rc else (const Nothing) d
      (m1, d1, c1) = let (a, b, c) = free0 in step a "matrix-key" matrixPick b c
      (m2, d2, c2) = step m1 "number" numPick d1 c1
      (m3, d3, c3) = step m2 "label" exactPick d2 c2
      (m4, d4, c4) = step m3 "fuzzy-label" fuzzyPick d3 c3
      (m5, d5, c5) = step m4 "singleton" single d4 c4
      explained = [ (c, cl, rs) | c <- c5, Just (cl, rs) <- [M.lookup (cellKey c) (cfgExplained cfg)] ]
      xmlOnly = [ c | c <- c5, cellKey c `M.notMember` cfgExplained cfg ]
  in Report bolk [ Match d c h (diffs gmap copies f d c) | (d, c, h) <- m5 ] d5 xmlOnly explained

stripLead :: Text -> Text
stripLead t = case T.words t of
  (w : rest) | isNum w -> T.unwords rest
  _ -> t
  where isNum w = let k = T.dropWhileEnd (== '.') w in not (T.null k) && T.any isDigit k && T.length k <= 6 && T.all (\c -> isAlphaNum c || c == '.') k && (T.head k `elem` ['A' .. 'Z'] || isDigit (T.head k))

diffs :: M.Map Text Text -> M.Map Text Text -> Form -> DField -> Cell -> [Text]
diffs gmap copies f d c =
  reqDiff
  ++ [ "prefilled/readonly: dsl=" <> yn dp <> " xml=" <> yn xp | dp /= xp ]
  ++ [ "calculated: dsl=" <> yn (dCalc d) <> " xml=" <> yn xc | dCalc d /= xc ]
  ++ [ "conditional: dsl=" <> yn (dConditional d) <> " xml=" <> yn xg | dConditional d /= xg ]
  ++ [ "type: dsl=" <> dType d <> " xml=" <> fromMaybe "?" (cControl c) | tmis ]
  ++ calcDiff
  ++ checkDiff
  where
    xp = kindOf f c == KPrefilled
    dp = dPrefilled d
    xc = kindOf f c == KCalculated
    xg = not (null (controllersOf f c))
    known = S.fromList (M.elems gmap)
    toF keys = S.fromList [ x | k <- keys, Just x <- [M.lookup k gmap] ]
    self = cellKey c
    refKeys h = [ s <> "/" <> dd | (s, dd) <- handlerRefs (hEval h) ]
    root x = go (10 :: Int) x where go n y = case M.lookup y copies of Just z | n > 0 -> go (n - 1) z; _ -> y
    calcX = S.map root (toF (filter (/= self) (concatMap refKeys (ownCalc f c))))
    calcD = S.map root (S.fromList (dCalcRefs d) `S.intersection` known)
    isCheck h = hType h == Nothing && T.strip (hEval h) /= "FieldFilled(obThis)"
    onC = [ h | h <- ownChecks f c, isCheck h ]
    others = [ (o, h) | o <- cells f, cellKey o /= self, h <- ownChecks f o, isCheck h, self `elem` refKeys h ]
    partnerKeys = concatMap (filter (/= self) . refKeys) onC ++ concat [ cellKey o : filter (/= self) (refKeys h) | (o, h) <- others ]
    partX = toF partnerKeys
    partD = S.fromList (dPartners d) `S.intersection` known
    setDiff nm a b = [ nm <> ": dsl-only {" <> T.intercalate ", " (S.toList (a S.\\ b)) <> "} xml-only {" <> T.intercalate ", " (S.toList (b S.\\ a)) <> "}" | a /= b ]
    calcDiff = if M.null gmap || not (dCalc d && xc) then [] else setDiff "calc inputs" calcD calcX
    checkDiff
      | M.null gmap = []
      | otherwise = setDiff "check partners" partD partX
    reqDiff = case (dRequired d, requiredSeverity f c) of
      (True, Nothing) -> [ "required: dsl=yes xml=no" ]
      (True, Just "warning") -> [ "required: dsl=yes (hard) xml=warning only (soft 'please fill')" ]
      (False, Just "critical") -> [ "required: dsl=no xml=critical" ]
      (False, Just s) | s /= "critical" -> [ "required: dsl=no xml=" <> s <> " (soft)" ]
      _ -> []
    tmis = (dType d == "boolean") /= (cControl c == Just "radioButton")
    yn b = if b then "yes" else "no"

renderReport :: Form -> Report -> [Text]
renderReport f r =
  [ "== " <> rBolk r <> ": matched " <> n (rMatched r) <> ", dsl-only " <> n (rDslOnly r) <> ", xml-only " <> n (rXmlOnly r)
      <> ", explained " <> n (rExplained r) ]
  ++ concat [ ("  " <> dId (mField m) <> "  <->  " <> cellKey (mCell m) <> "  [" <> mHow m <> "]") : [ "      diff " <> x | x <- mDiffs m ] | m <- rMatched r ]
  ++ [ "  dsl-only: " <> dId d <> "  " <> T.take 60 (dLabel d) | d <- rDslOnly r ]
  ++ [ "  xml-only: " <> cellKey c <> "  [" <> kindName (kindOf f c) <> "] " <> T.take 60 (cellLabel f c) | c <- rXmlOnly r ]
  ++ [ "  explained: " <> cellKey c <> "  " <> cl <> " – " <> rs | (c, cl, rs) <- rExplained r ]
  where n :: [a] -> Text
        n = T.pack . show . length

-- | Alignment facts for the Skjemakart canvas: per-cell status plus DSL-only fields.
encodeAlign :: Form -> [Report] -> BL.ByteString
encodeAlign f rs = encode $ object
  [ "cells" .= object ([ K.fromText (cellKey (mCell m)) .= object
        [ "status" .= (if null (mDiffs m) then "aligned" else "diff" :: Text), "bolk" .= rBolk r
        , "field" .= dId (mField m), "label" .= dLabel (mField m), "how" .= mHow m, "diffs" .= mDiffs m, "xmlKind" .= kindName (kindOf f (mCell m)) ]
      | r <- rs, m <- rMatched r ]
    ++ [ K.fromText (cellKey c) .= object [ "status" .= ("xml-only" :: Text), "bolk" .= rBolk r ] | r <- rs, c <- rXmlOnly r ]
    ++ [ K.fromText (cellKey c) .= object [ "status" .= ("explained" :: Text), "bolk" .= rBolk r, "class" .= cl, "reason" .= why ]
      | r <- rs, (c, cl, why) <- rExplained r ])
  , "dslOnly" .= [ object [ "bolk" .= rBolk r, "field" .= dId d, "label" .= dLabel d ] | r <- rs, d <- rDslOnly r ]
  ]
