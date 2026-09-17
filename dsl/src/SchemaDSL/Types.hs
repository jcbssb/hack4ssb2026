{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module SchemaDSL.Types
  ( FieldId
  , Prompt(..)
  , QuestionType(..)
  , Predicate(..)
  , Question(..)
  , SurveyContext(..)
  , Dialogue(..)
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
  | QTextArea
  | QInteger
  | QDecimal
  | QDate
  | QBoolean
  | QChoice [String]
  | QMultiChoice [String]
  deriving (Show, Eq, Generic)

instance ToJSON QuestionType where
  toJSON QText = object [ "type" .= ("text" :: String) ]
  toJSON QTextArea = object [ "type" .= ("textarea" :: String) ]
  toJSON QInteger = object [ "type" .= ("integer" :: String) ]
  toJSON QDecimal = object [ "type" .= ("decimal" :: String) ]
  toJSON QDate = object [ "type" .= ("date" :: String) ]
  toJSON QBoolean = object [ "type" .= ("boolean" :: String) ]
  toJSON (QChoice opts) =
    object
      [ "type" .= ("choice" :: String)
      , "options" .= opts
      ]
  toJSON (QMultiChoice opts) =
    object
      [ "type" .= ("multichoice" :: String)
      , "options" .= opts
      ]

instance FromJSON QuestionType where
  parseJSON = withObject "QuestionType" $ \o -> do
    t <- o .: "type"
    case (t :: String) of
      "text"        -> pure QText
      "textarea"    -> pure QTextArea
      "integer"     -> pure QInteger
      "decimal"     -> pure QDecimal
      "date"        -> pure QDate
      "boolean"     -> pure QBoolean
      "choice"      -> QChoice <$> o .: "options"
      "multichoice" -> QMultiChoice <$> o .: "options"
      other         -> fail $ "Unknown question type: " ++ other

-- | Conditional predicate for dynamic visibility or skip logic
data Predicate
  = Equals FieldId String
  | NotEquals FieldId String
  | IsTrue FieldId
  | And [Predicate]
  | Or [Predicate]
  deriving (Show, Eq, Generic)

instance ToJSON Predicate where
  toJSON (Equals fid val) = object [ "op" .= ("equals" :: String), "fieldId" .= fid, "value" .= val ]
  toJSON (NotEquals fid val) = object [ "op" .= ("notEquals" :: String), "fieldId" .= fid, "value" .= val ]
  toJSON (IsTrue fid) = object [ "op" .= ("isTrue" :: String), "fieldId" .= fid ]
  toJSON (And preds) = object [ "op" .= ("and" :: String), "conditions" .= preds ]
  toJSON (Or preds) = object [ "op" .= ("or" :: String), "conditions" .= preds ]

instance FromJSON Predicate where
  parseJSON = withObject "Predicate" $ \o -> do
    op <- o .: "op"
    case (op :: String) of
      "equals"     -> Equals <$> o .: "fieldId" <*> o .: "value"
      "notEquals"  -> NotEquals <$> o .: "fieldId" <*> o .: "value"
      "isTrue"     -> IsTrue <$> o .: "fieldId"
      "and"        -> And <$> o .: "conditions"
      "or"         -> Or <$> o .: "conditions"
      other        -> fail $ "Unknown predicate operation: " ++ other

-- | Atomic question representing one dialogue step
data Question = Question
  { fieldId      :: FieldId
  , prompt       :: Prompt
  , questionType :: QuestionType
  , required     :: Bool
  , condition    :: Maybe Predicate
  , annotations  :: Maybe (KM.KeyMap Value)
  } deriving (Show, Eq, Generic)

instance ToJSON Question where
  toJSON (Question fid prmpt qtype req cond anns) =
    object $
      [ "fieldId"      .= fid
      , "prompt"       .= prmpt
      , "questionType" .= qtype
      , "required"     .= req
      ]
      ++ maybe [] (\c -> ["condition" .= c]) cond
      ++ maybe [] (\a -> ["annotations" .= Object a]) anns

instance FromJSON Question where
  parseJSON = withObject "Question" $ \o ->
    Question <$> o .: "fieldId"
             <*> o .: "prompt"
             <*> o .: "questionType"
             <*> o .: "required"
             <*> o .:? "condition"
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

