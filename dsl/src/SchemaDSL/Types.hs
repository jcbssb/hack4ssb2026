{-# LANGUAGE DeriveGeneric #-}

module SchemaDSL.Types
  ( FieldId
  , Prompt(..)
  , QuestionType(..)
  , Question(..)
  , Dialogue(..)
  , helloWorldDialogue
  ) where

import GHC.Generics (Generic)

-- | Unique field identifier (semantic data binding key)
type FieldId = String

-- | Question prompt and optional guidance text
data Prompt = Prompt
  { label    :: String
  , helpText :: Maybe String
  } deriving (Show, Eq, Generic)

-- | Semantic question data type
data QuestionType
  = QText
  | QInteger
  | QChoice [String]
  deriving (Show, Eq, Generic)

-- | Atomic question representing one dialogue step
data Question = Question
  { fieldId      :: FieldId
  , prompt       :: Prompt
  , questionType :: QuestionType
  , required     :: Bool
  } deriving (Show, Eq, Generic)

-- | Top-level semantic dialogue specification
data Dialogue = Dialogue
  { dialogueId :: String
  , title      :: String
  , steps      :: [Question]
  } deriving (Show, Eq, Generic)

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
