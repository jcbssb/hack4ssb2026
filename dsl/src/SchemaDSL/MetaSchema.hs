{-# LANGUAGE OverloadedStrings #-}

module SchemaDSL.MetaSchema
  ( baselineMetaSchema
  , encodeMetaSchema
  , encodeMetaSchemaPretty
  ) where

import qualified Data.ByteString.Lazy as BL
import Data.Aeson
  ( Value
  , encode
  , object
  , (.=)
  )
import Data.Aeson.Encode.Pretty (encodePretty)

-- | Formal JSON Schema metaschema definition derived from SchemaDSL Haskell types
baselineMetaSchema :: Value
baselineMetaSchema = object
  [ "$schema" .= ("https://json-schema.org/draft/2020-12/schema" :: String)
  , "$id" .= ("https://ssb.no/schemas/dialogue-schema-v1.json" :: String)
  , "title" .= ("SSB Dialogue Schema Baseline Specification" :: String)
  , "description" .= ("Single Source of Truth (SSOT) capturing semantic dialogue flow, field bindings, and design annotations decoupled from execution targets." :: String)
  , "type" .= ("object" :: String)
  , "properties" .= object
      [ "dialogueId" .= object
          [ "type" .= ("string" :: String)
          , "pattern" .= ("^[a-z0-9][a-z0-9-]*$" :: String)
          , "description" .= ("Unique identifier for the dialogue/form (e.g., ssb-hackday-2026)" :: String)
          ]
      , "title" .= object
          [ "type" .= ("string" :: String)
          , "description" .= ("Title of the survey or form" :: String)
          ]
      , "context" .= object
          [ "type" .= ("object" :: String)
          , "properties" .= object
              [ "surveyCode" .= object [ "type" .= ("string" :: String) ]
              , "organization" .= object [ "type" .= ("string" :: String) ]
              , "legalNotice" .= object [ "type" .= ("string" :: String) ]
              ]
          ]
      , "steps" .= object
          [ "type" .= ("array" :: String)
          , "items" .= object [ "$ref" .= ("#/$defs/QuestionStep" :: String) ]
          ]
      ]
  , "required" .= (["dialogueId", "title", "steps"] :: [String])
  , "$defs" .= object
      [ "QuestionStep" .= object
          [ "type" .= ("object" :: String)
          , "properties" .= object
              [ "fieldId" .= object
                  [ "type" .= ("string" :: String)
                  , "pattern" .= ("^[a-zA-Z][a-zA-Z0-9_]*$" :: String)
                  , "description" .= ("Identifier used for data model bindings (Altinn simpleBinding and JSON payload key)" :: String)
                  ]
              , "prompt" .= object
                  [ "type" .= ("object" :: String)
                  , "properties" .= object
                      [ "label" .= object [ "type" .= ("string" :: String), "description" .= ("Primary label / question text" :: String) ]
                      , "helpText" .= object [ "type" .= ("string" :: String), "description" .= ("Optional guidance or instruction text" :: String) ]
                      ]
                  , "required" .= (["label"] :: [String])
                  ]
              , "questionType" .= object
                  [ "type" .= ("object" :: String)
                  , "properties" .= object
                      [ "type" .= object
                          [ "type" .= ("string" :: String)
                          , "enum" .= (["text", "integer", "choice"] :: [String])
                          ]
                      , "options" .= object
                          [ "type" .= ("array" :: String)
                          , "items" .= object [ "type" .= ("string" :: String) ]
                          ]
                      ]
                  , "required" .= (["type"] :: [String])
                  ]
              , "required" .= object
                  [ "type" .= ("boolean" :: String)
                  , "default" .= False
                  ]
              , "annotations" .= object
                  [ "type" .= ("object" :: String)
                  , "description" .= ("Optional UI/UX hints for Figma or Altinn interpreters" :: String)
                  , "properties" .= object
                      [ "placeholder" .= object [ "type" .= ("string" :: String) ]
                      , "componentHint" .= object
                          [ "type" .= ("string" :: String)
                          , "enum" .= (["Input", "RadioButtons", "Dropdown"] :: [String])
                          ]
                      ]
                  ]
              ]
          , "required" .= (["fieldId", "prompt", "questionType", "required"] :: [String])
          ]
      ]
  ]

encodeMetaSchema :: BL.ByteString
encodeMetaSchema = encode baselineMetaSchema

encodeMetaSchemaPretty :: BL.ByteString
encodeMetaSchemaPretty = encodePretty baselineMetaSchema
