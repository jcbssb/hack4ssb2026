{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module SchemaDSL.Types
  ( FieldId
  , Prompt(..)
  , QuestionType(..)
  , Question(..)
  , SurveyContext(..)
  , Dialogue(..)
  , helloWorldDialogue
  ) where

import GHC.Generics (Generic)
import Data.Aeson
  ( ToJSON(..)
  , FromJSON(..)
  , Value(..)
  , object
  , (.=)
  , (.:)
  , (.:?)
  , withObject
  )
import qualified Data.Aeson.KeyMap as KM

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
  , annotations  :: Maybe (KM.KeyMap Value)
  } deriving (Show, Eq, Generic)

instance ToJSON Question where
  toJSON (Question fid prmpt qtype req anns) =
    object $
      [ "fieldId"      .= fid
      , "prompt"       .= prmpt
      , "questionType" .= qtype
      , "required"     .= req
      ] ++ maybe [] (\a -> ["annotations" .= Object a]) anns

instance FromJSON Question where
  parseJSON = withObject "Question" $ \o ->
    Question <$> o .: "fieldId"
             <*> o .: "prompt"
             <*> o .: "questionType"
             <*> o .: "required"
             <*> (fmap unObject <$> (o .:? "annotations"))
    where
      unObject (Object km) = km
      unObject _           = KM.empty

-- | Context metadata (survey code, organization, legal notice)
data SurveyContext = SurveyContext
  { surveyCode   :: Maybe String
  , organization :: Maybe String
  , legalNotice  :: Maybe String
  } deriving (Show, Eq, Generic)

instance ToJSON SurveyContext where
  toJSON (SurveyContext sc org ln) =
    object
      [ "surveyCode"   .= sc
      , "organization" .= org
      , "legalNotice"  .= ln
      ]

instance FromJSON SurveyContext where
  parseJSON = withObject "SurveyContext" $ \o ->
    SurveyContext <$> o .:? "surveyCode"
                  <*> o .:? "organization"
                  <*> o .:? "legalNotice"

-- | Top-level semantic dialogue specification
data Dialogue = Dialogue
  { dialogueId :: String
  , title      :: String
  , context    :: Maybe SurveyContext
  , steps      :: [Question]
  } deriving (Show, Eq, Generic)

instance ToJSON Dialogue where
  toJSON (Dialogue did ttl ctx stps) =
    object $
      [ "$schema"    .= ("./baseline-schema-meta.json" :: String)
      , "dialogueId" .= did
      , "title"      .= ttl
      ]
      ++ maybe [] (\c -> ["context" .= c]) ctx
      ++ [ "steps" .= stps ]

instance FromJSON Dialogue where
  parseJSON = withObject "Dialogue" $ \o ->
    Dialogue <$> o .: "dialogueId"
             <*> o .: "title"
             <*> o .:? "context"
             <*> o .: "steps"

-- | Hello World baseline dialogue matching baseline-schema.json
helloWorldDialogue :: Dialogue
helloWorldDialogue = Dialogue
  { dialogueId = "hack4ssb-hello"
  , title      = "SSB Hackday 2026 - Registrering"
  , context    = Just SurveyContext
      { surveyCode   = Just "HACK-2026"
      , organization = Just "Statistisk sentralbyrå"
      , legalNotice  = Just "Dette skjemaet samler inn teamregistreringer for Hackday 2026."
      }
  , steps      =
      [ Question
          { fieldId      = "teamName"
          , prompt       = Prompt
              { label    = "Hva er navnet på ditt Hackday Team?"
              , helpText = Just "Oppgi et unikt lagnavn, f.eks. 'Foran Skjema'."
              }
          , questionType = QText
          , required     = True
          , annotations  = Just (KM.fromList [("placeholder", String "F.eks. Foran Skjema"), ("componentHint", String "Input")])
          }
      , Question
          { fieldId      = "trackChoice"
          , prompt       = Prompt
              { label    = "Hvilket hovedspor jobber teamet med?"
              , helpText = Just "Velg det primære fokusområdet for hack-prosjektet."
              }
          , questionType = QChoice
              [ "AI & Skjemaer"
              , "Figma Prototyping"
              , "Altinn 3 Integrasjon"
              , "Kombinasjon / Helhetlig flyt"
              ]
          , required     = False
          , annotations  = Just (KM.fromList [("componentHint", String "RadioButtons")])
          }
      ]
  }
