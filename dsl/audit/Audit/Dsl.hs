{-# LANGUAGE OverloadedStrings #-}
-- | Facts about a compiled DSL schema (the generated JSON, never the Haskell source).
module Audit.Dsl (DField (..), loadDsl) where

import Data.Aeson (Value (..), eitherDecodeFileStrict)
import qualified Data.Aeson.Key as K
import qualified Data.Aeson.KeyMap as KM
import qualified Data.Foldable as F
import Data.Maybe (fromMaybe, mapMaybe)
import Data.Text (Text)
import qualified Data.Text as T

data DField = DField
  { dId :: Text, dBolk :: Text, dLabel :: Text, dType :: Text
  , dRequired :: Bool, dPrefilled :: Bool, dReadOnly :: Bool, dConditional :: Bool
  , dRow :: Maybe Text, dCol :: Maybe Text, dRowLabel :: Maybe Text, dColLabel :: Maybe Text
  , dCalc :: Bool, dChecks :: Int
  } deriving Show

loadDsl :: FilePath -> IO [DField]
loadDsl p = do
  r <- eitherDecodeFileStrict p
  case r of
    Left e -> fail ("cannot parse DSL json: " <> e)
    Right (Object o) -> pure (fields o)
    Right _ -> fail "DSL json is not an object"

key :: Text -> Value -> Maybe Value
key k (Object o) = KM.lookup (K.fromText k) o
key _ _ = Nothing

str :: Text -> Value -> Maybe Text
str k v = case key k v of Just (String t) -> Just t; _ -> Nothing

bool :: Text -> Value -> Bool
bool k v = case key k v of Just (Bool b) -> b; _ -> False

arr :: Text -> Value -> [Value]
arr k v = case key k v of Just (Array a) -> F.toList a; _ -> []

fieldIds :: Value -> [Text]
fieldIds (Object o) = [ t | Just (String t) <- [KM.lookup "fieldId" o] ] ++ concatMap fieldIds (KM.elems o)
fieldIds (Array a) = concatMap fieldIds (F.toList a)
fieldIds _ = []

fields :: KM.KeyMap Value -> [DField]
fields o =
  [ DField
      { dId = fid, dBolk = fromMaybe "" (str "bolkId" st)
      , dLabel = fromMaybe "" (key "prompt" q >>= str "label")
      , dType = fromMaybe "" (key "questionType" q >>= str "type")
      , dRequired = bool "required" q
      , dPrefilled = ann "prefilled", dReadOnly = ann "readOnly"
      , dConditional = maybe False (/= Null) (key "condition" q)
      , dRow = mx "row", dCol = mx "col", dRowLabel = mx "rowLabel", dColLabel = mx "colLabel"
      , dCalc = fid `elem` calcIds
      , dChecks = length (filter (fid `elem`) constraintRefs)
      }
  | st <- arr "steps" top, q <- arr "questions" st
  , Just fid <- [str "fieldId" q]
  , let ann k = maybe False (bool k) (key "annotations" q)
        mx k = key "annotations" q >>= key "matrix" >>= str k
  ]
  where
    top = Object o
    calcIds = mapMaybe (str "fieldId") (arr "calculations" top)
    constraintRefs = map (\c -> filter (const True) (fieldIds c)) (arr "constraints" top)
