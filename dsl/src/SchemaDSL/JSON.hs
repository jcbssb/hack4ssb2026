{-# LANGUAGE OverloadedStrings #-}

module SchemaDSL.JSON
  ( encodeDialogue
  , decodeDialogue
  , encodeDialoguePretty
  ) where

import qualified Data.ByteString.Lazy as BL
import Data.Aeson
  ( ToJSON(..)
  , FromJSON(..)
  , Value(..)
  , object
  , (.=)
  , (.:)
  , (.:?)
  , withObject
  , encode
  , eitherDecode
  )
import qualified Data.Aeson.KeyMap as KM
import SchemaDSL.Types

-- Prompt JSON instances
instance ToJSON Prompt where
  toJSON (Prompt lbl hlp) =
    object
      [ "label" .= lbl
      , "helpText" .= hlp
      ]

instance FromJSON Prompt where
  parseJSON = withObject "Prompt" $ \o ->
    Prompt <$> o .: "label"
           <*> o .:? "helpText"

-- QuestionType JSON instances
instance ToJSON QuestionType where
  toJSON QText = object [ "type" .= ("text" :: String) ]
  toJSON QInteger = object [ "type" .= ("integer" :: String) ]
  toJSON (QChoice opts) =
    object
      [ "type" .= ("choice" :: String)
      , "options" .= opts
      ]

instance FromJSON QuestionType where
  parseJSON = withObject "QuestionType" $ \o -> do
    t <- o .: "type"
    case (t :: String) of
      "text"    -> pure QText
      "integer" -> pure QInteger
      "choice"  -> QChoice <$> o .: "options"
      other     -> fail $ "Unknown question type: " ++ other

-- Question JSON instances
instance ToJSON Question where
  toJSON (Question fid prmpt qtype req) =
    object
      [ "fieldId"      .= fid
      , "prompt"       .= prmpt
      , "questionType" .= qtype
      , "required"     .= req
      ]

instance FromJSON Question where
  parseJSON = withObject "Question" $ \o ->
    Question <$> o .: "fieldId"
             <*> o .: "prompt"
             <*> o .: "questionType"
             <*> o .: "required"

-- Dialogue JSON instances
instance ToJSON Dialogue where
  toJSON (Dialogue did ttl stps) =
    object
      [ "dialogueId" .= did
      , "title"      .= ttl
      , "steps"      .= stps
      ]

instance FromJSON Dialogue where
  parseJSON = withObject "Dialogue" $ \o ->
    Dialogue <$> o .: "dialogueId"
             <*> o .: "title"
             <*> o .: "steps"

-- | Encode dialogue to Lazy ByteString
encodeDialogue :: Dialogue -> BL.ByteString
encodeDialogue = encode

-- | Decode dialogue from Lazy ByteString
decodeDialogue :: BL.ByteString -> Either String Dialogue
decodeDialogue = eitherDecode

-- | Simple pretty print without requiring aeson-pretty
encodeDialoguePretty :: Dialogue -> BL.ByteString
encodeDialoguePretty = encodeDialogue
