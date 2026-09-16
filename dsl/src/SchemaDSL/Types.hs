{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module SchemaDSL.Types
  ( FieldId
  , Prompt(..)
  , QuestionType(..)
  , Question(..)
  , Dialogue(..)
  , helloWorldDialogue
  ) where

import GHC.Generics (Generic)
import Data.Aeson
  ( ToJSON(..)
  , FromJSON(..)
  , object
  , (.=)
  , (.:)
  , (.:?)
  , withObject
  )

-- | Unique field identifier (semantic data binding key)
type FieldId = String

-- | Question prompt and optional guidance text
data Prompt = Prompt
  { label    :: String
  , helpText :: Maybe String
  } deriving (Show, Eq, Generic)

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

-- | Semantic question data type
data QuestionType
  = QText
  | QInteger
  | QChoice [String]
  deriving (Show, Eq, Generic)

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

-- | Atomic question representing one dialogue step
data Question = Question
  { fieldId      :: FieldId
  , prompt       :: Prompt
  , questionType :: QuestionType
  , required     :: Bool
  } deriving (Show, Eq, Generic)

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

-- | Top-level semantic dialogue specification
data Dialogue = Dialogue
  { dialogueId :: String
  , title      :: String
  , steps      :: [Question]
  } deriving (Show, Eq, Generic)

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

-- | Hello World example dialogue capturing a hackday team name
helloWorldDialogue :: Dialogue
helloWorldDialogue = Dialogue
  { dialogueId = "hack4ssb-hello"
  , title      = "SSB Hackday 2026 - Registrering"
  , steps      =
      [ Question
          { fieldId      = "teamName"
          , prompt       = Prompt
              { label    = "Hva er navnet på ditt Hackday Team?"
              , helpText = Just "Oppgi et unikt lagnavn, f.eks. 'Foran Skjema'"
              }
          , questionType = QText
          , required     = True
          }
      ]
  }
