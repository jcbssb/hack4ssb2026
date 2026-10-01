{-# LANGUAGE OverloadedStrings #-}
-- | JSON facts for downstream tools (alignment, audit, python/jq).
module Audit.Export (encodeFacts) where

import Audit.Index
import Audit.Xml4dr
import Data.Aeson
import Data.Aeson.Encode.Pretty (encodePretty)
import qualified Data.Aeson.Key as K
import qualified Data.ByteString.Lazy as BL
import qualified Data.Map.Strict as M
import Data.Text (Text)

encodeFacts :: Form -> BL.ByteString
encodeFacts f = encodePretty $ object
  [ "formId" .= formId f, "title" .= formTitle f
  , "sections" .= [ object [ "id" .= secId s, "path" .= secPath s, "title" .= secTitle s, "rows" .= secRows s ] | s <- sections f ]
  , "cells" .= map cellJson (cells f)
  , "handlers" .= M.map handlerJson (handlers f) ]
  where
    cellJson c = object
      [ "key" .= cellKey c, "set" .= cSet c, "data" .= cData c, "row" .= cRow c, "col" .= cCol c
      , "kind" .= kindName (kindOf f c), "required" .= isRequired f c
      , "rowLabel" .= rowLabelOf f c, "header" .= headerOf f c
      , "text" .= cText c, "textNn" .= cNn c, "value" .= cValue c
      , "control" .= cControl c, "size" .= cSize c, "styles" .= cStyles c, "handlers" .= cHandlers c
      , "gatedBy" .= [ object [ "controller" .= cellKey src, "handler" .= hId h, "when" .= hEval h ] | (src, h, _) <- controllersOf f c ]
      , "reads" .= [ a <> "/" <> b | (a, b) <- refsOut f c ] ]
    handlerJson h = object
      [ "type" .= hType h, "eval" .= hEval h
      , "actions" .= [ object [ "when" .= aWhen a, "effects" .= map effJson (aEffects a) ] | a <- hActions h ] ]
    effJson :: Effect -> Value
    effJson (SetState st ps) = object [ "setState" .= st, "targets" .= [ s <> "/" <> d | (s, d) <- ps ] ]
    effJson (MsgBox ts) = object [ "msgBox" .= ts ]
    effJson (SetError e) = object [ "setError" .= e ]

_k :: Text -> K.Key
_k = K.fromText
