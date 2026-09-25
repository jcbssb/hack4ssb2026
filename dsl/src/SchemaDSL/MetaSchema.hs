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
      , "calculations" .= object
          [ "type" .= ("array" :: String)
          , "description" .= ("Derived fields whose value is always given by an expression (totals, remainders)" :: String)
          , "items" .= object [ "$ref" .= ("#/$defs/Calculation" :: String) ]
          ]
      , "constraints" .= object
          [ "type" .= ("array" :: String)
          , "description" .= ("Cross-field rules that must hold, e.g. parts adding up to a total" :: String)
          , "items" .= object [ "$ref" .= ("#/$defs/Constraint" :: String) ]
          ]
      , "steps" .= object
          [ "type" .= ("array" :: String)
          , "items" .= object
              [ "anyOf" .=
                  [ object [ "$ref" .= ("#/$defs/QuestionStep" :: String) ]
                  , object [ "$ref" .= ("#/$defs/BolkStep" :: String) ]
                  ]
              ]
          ]
      ]
  , "required" .= (["dialogueId", "title", "steps"] :: [String])
  , "$defs" .= object
      [ "BolkStep" .= object
          [ "type" .= ("object" :: String)
          , "properties" .= object
              [ "type" .= object [ "type" .= ("string" :: String), "const" .= ("bolk" :: String) ]
              , "bolkId" .= object [ "type" .= ("string" :: String) ]
              , "title" .= object [ "type" .= ("string" :: String) ]
              , "description" .= object [ "type" .= ("string" :: String) ]
              , "condition" .= object [ "$ref" .= ("#/$defs/Predicate" :: String) ]
              , "questions" .= object
                  [ "type" .= ("array" :: String)
                  , "items" .= object [ "$ref" .= ("#/$defs/QuestionStep" :: String) ]
                  ]
              ]
          , "required" .= (["bolkId", "title", "questions"] :: [String])
          ]
      , "QuestionStep" .= object
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
                          , "enum" .= (["text", "textarea", "integer", "decimal", "date", "boolean", "choice", "multichoice"] :: [String])
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
              , "condition" .= object
                  [ "$ref" .= ("#/$defs/Predicate" :: String)
                  ]
              , "annotations" .= object
                  [ "type" .= ("object" :: String)
                  , "description" .= ("Optional UI/UX hints for Figma or Altinn interpreters" :: String)
                  , "properties" .= object
                      [ "placeholder" .= object [ "type" .= ("string" :: String) ]
                      , "maxLength" .= object [ "type" .= ("integer" :: String) ]
                      , "componentHint" .= object
                          [ "type" .= ("string" :: String)
                          , "enum" .= (["Input", "TextArea", "RadioButtons", "Checkboxes", "Dropdown", "Datepicker"] :: [String])
                          ]
                      ]
                  ]
              ]
          , "required" .= (["fieldId", "prompt", "questionType", "required"] :: [String])
          ]
      , "Expr" .= object
          [ "type" .= ("object" :: String)
          , "description" .= ("Numeric expression over field values. Empty fields count as 0; division by zero has no value." :: String)
          , "properties" .= object
              [ "op" .= object
                  [ "type" .= ("string" :: String)
                  , "enum" .= (["field", "const", "add", "sub", "mul", "div"] :: [String])
                  ]
              , "fieldId" .= object [ "type" .= ("string" :: String) ]
              , "value" .= object [ "type" .= ("number" :: String) ]
              , "terms" .= object
                  [ "type" .= ("array" :: String)
                  , "items" .= object [ "$ref" .= ("#/$defs/Expr" :: String) ]
                  ]
              , "left" .= object [ "$ref" .= ("#/$defs/Expr" :: String) ]
              , "right" .= object [ "$ref" .= ("#/$defs/Expr" :: String) ]
              ]
          , "required" .= (["op"] :: [String])
          ]
      , "Calculation" .= object
          [ "type" .= ("object" :: String)
          , "properties" .= object
              [ "fieldId" .= object [ "type" .= ("string" :: String), "description" .= ("Numeric question receiving the computed value" :: String) ]
              , "expr" .= object [ "$ref" .= ("#/$defs/Expr" :: String) ]
              ]
          , "required" .= (["fieldId", "expr"] :: [String])
          ]
      , "Constraint" .= object
          [ "type" .= ("object" :: String)
          , "properties" .= object
              [ "constraintId" .= object [ "type" .= ("string" :: String) ]
              , "left" .= object [ "$ref" .= ("#/$defs/Expr" :: String) ]
              , "comparison" .= object
                  [ "type" .= ("string" :: String)
                  , "enum" .= (["eq", "notEq", "lt", "lte", "gt", "gte"] :: [String])
                  ]
              , "right" .= object [ "$ref" .= ("#/$defs/Expr" :: String) ]
              , "message" .= object [ "type" .= ("string" :: String), "description" .= ("Shown to the respondent when the rule does not hold" :: String) ]
              , "severity" .= object
                  [ "type" .= ("string" :: String)
                  , "enum" .= (["error", "warning"] :: [String])
                  , "default" .= ("error" :: String)
                  ]
              , "condition" .= object
                  [ "$ref" .= ("#/$defs/Predicate" :: String)
                  , "description" .= ("Only check the rule when this predicate holds" :: String)
                  ]
              , "reportOn" .= object
                  [ "type" .= ("array" :: String)
                  , "description" .= ("Fields that show the message; defaults to the entered (non-calculated) fields referenced" :: String)
                  , "items" .= object [ "type" .= ("string" :: String) ]
                  ]
              ]
          , "required" .= (["constraintId", "left", "comparison", "right", "message"] :: [String])
          ]
      , "Predicate" .= object
          [ "type" .= ("object" :: String)
          , "properties" .= object
              [ "op" .= object
                  [ "type" .= ("string" :: String)
                  , "enum" .= (["equals", "notEquals", "isTrue", "compare", "and", "or"] :: [String])
                  ]
              , "fieldId" .= object [ "type" .= ("string" :: String) ]
              , "value" .= object [ "type" .= ("string" :: String) ]
              , "left" .= object [ "$ref" .= ("#/$defs/Expr" :: String) ]
              , "comparison" .= object
                  [ "type" .= ("string" :: String)
                  , "enum" .= (["eq", "notEq", "lt", "lte", "gt", "gte"] :: [String])
                  ]
              , "right" .= object [ "$ref" .= ("#/$defs/Expr" :: String) ]
              , "conditions" .= object
                  [ "type" .= ("array" :: String)
                  , "items" .= object [ "$ref" .= ("#/$defs/Predicate" :: String) ]
                  ]
              ]
          , "required" .= (["op"] :: [String])
          ]
      ]
  ]

encodeMetaSchema :: BL.ByteString
encodeMetaSchema = encode baselineMetaSchema

encodeMetaSchemaPretty :: BL.ByteString
encodeMetaSchemaPretty = encodePretty baselineMetaSchema
