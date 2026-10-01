{-# LANGUAGE OverloadedStrings #-}
-- | Triaged findings (F-NNN) and the rules that attach audit items to them.
module Audit.Findings (Rule (..), Finding (..), Item (..), loadFindings, matches) where

import Data.Aeson (Value (..), eitherDecodeFileStrict)
import qualified Data.Aeson.Key as K
import qualified Data.Aeson.KeyMap as KM
import qualified Data.Foldable as F
import Data.Text (Text)
import qualified Data.Text as T

-- | An audit item: a per-cell diff, a DSL constraint without XML counterpart, or an XML check without DSL counterpart.
data Item = Item { iKind :: Text, iWhere :: Text, iBolk :: Text, iText :: Text, iXmlKind :: Text } deriving Show

data Rule = Rule
  { rlKind :: Maybe Text, rlPrefix :: Maybe Text, rlXmlKind :: Maybe Text, rlBolks :: [Text], rlContains :: Maybe Text } deriving Show

data Finding = Finding
  { fId, fTitle, fFixKind, fSeverity, fStatus, fDescription, fProposed :: Text, fRules :: [Rule] } deriving Show

matches :: Rule -> Item -> Bool
matches r i = and
  [ maybe True (== iKind i) (rlKind r)
  , maybe True (`T.isPrefixOf` iText i) (rlPrefix r)
  , maybe True (== iXmlKind i) (rlXmlKind r)
  , null (rlBolks r) || iBolk i `elem` rlBolks r
  , maybe True (`T.isInfixOf` (iWhere i <> " " <> iText i)) (rlContains r) ]

loadFindings :: FilePath -> IO [Finding]
loadFindings p = do
  r <- eitherDecodeFileStrict p
  case r of
    Left e -> fail ("findings: " <> e)
    Right v -> pure [ finding f | f <- arr "findings" v ]
  where
    lk k (Object o) = KM.lookup (K.fromText k) o
    lk _ _ = Nothing
    arr k v = case lk k v of Just (Array a) -> F.toList a; _ -> []
    s k v = case lk k v of Just (String t) -> t; _ -> ""
    ms k v = case lk k v of Just (String t) -> Just t; _ -> Nothing
    finding f = Finding (s "id" f) (s "title" f) (s "fixKind" f) (s "severity" f) (s "status" f) (s "description" f) (s "proposedFix" f)
      [ Rule (ms "kind" r) (ms "prefix" r) (ms "xmlKind" r) [ t | String t <- arrL "bolks" r ] (ms "contains" r) | r <- arr "rules" f ]
    arrL k v = case lk k v of Just (Array a) -> F.toList a; _ -> []
