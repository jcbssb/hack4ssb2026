{-# LANGUAGE OverloadedStrings #-}
-- | Facts about a compiled DSL schema (the generated JSON, never the Haskell source).
module Audit.Dsl (DField (..), DConstraint (..), loadDsl, loadConstraints) where

import Data.Aeson (Value (..), eitherDecodeFileStrict)
import qualified Data.Aeson.Key as K
import qualified Data.Aeson.KeyMap as KM
import qualified Data.Foldable as F
import Data.Maybe (fromMaybe, listToMaybe, mapMaybe)
import qualified Data.Set as S
import Data.Text (Text)
import qualified Data.Text as T

data DField = DField
  { dId :: Text, dBolk :: Text, dLabel :: Text, dType :: Text
  , dRequired :: Text, dPrefilled :: Bool, dReadOnly :: Bool, dConditional :: Bool
  , dRow :: Maybe Text, dCol :: Maybe Text, dRowLabel :: Maybe Text, dColLabel :: Maybe Text
  , dCalc :: Bool, dChecks :: Int, dCalcRefs :: [Text], dCopyOf :: Maybe Text, dPartners :: [Text]
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
      , dRequired = case key "required" q of
          Just (Bool True)        -> "error"
          Just (String "error")   -> "error"
          Just (String "warn")    -> "warn"
          Just (String "warning") -> "warn"
          _                       -> "none"
      , dPrefilled = ann "prefilled", dReadOnly = ann "readOnly"
      , dConditional = maybe False (/= Null) (key "condition" q)
      , dRow = mx "row", dCol = mx "col", dRowLabel = mx "rowLabel", dColLabel = mx "colLabel"
      , dCalc = fid `elem` calcIds
      , dChecks = length (filter (fid `elem`) constraintRefs)
      , dCopyOf = listToMaybe [ r | c <- arr "calculations" top, str "fieldId" c == Just fid, Just e <- [key "expr" c], str "op" e == Just "field", Just r <- [str "fieldId" e] ]
      , dCalcRefs = S.toList (S.delete fid (S.fromList [ r | c <- arr "calculations" top, str "fieldId" c == Just fid, Just e <- [key "expr" c], r <- fieldIds e ]))
      , dPartners = S.toList (S.delete fid (S.fromList [ r | cr <- constraintRefs, fid `elem` cr, r <- cr ]))
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

data DConstraint = DConstraint { kId :: Text, kSeverity :: Text, kComparison :: Text, kFields :: [Text], kMessage :: Text } deriving Show

loadConstraints :: FilePath -> IO [DConstraint]
loadConstraints p = do
  r <- eitherDecodeFileStrict p
  case r of
    Left e -> fail ("cannot parse DSL json: " <> e)
    Right v ->
      pure [ DConstraint cid (fromMaybe "" (str "severity" c)) (fromMaybe "" (str "comparison" c)) (S.toList (S.fromList (fieldIds c))) (fromMaybe "" (str "message" c))
           | c <- arr "constraints" v, Just cid <- [str "constraintId" c] ]
