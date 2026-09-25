{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}

module SchemaDSL.Types
  ( FieldId
  , Prompt(..)
  , QuestionType(..)
  , Predicate(..)
  , Expr(..)
  , Comparison(..)
  , Severity(..)
  , Calculation(..)
  , Constraint(..)
  , sumOf
  , exprFields
  , predicateFields
  , Question(..)
  , Bolk(..)
  , Step(..)
  , SurveyContext(..)
  , Dialogue(..)
  , allDialogueQuestions
  ) where

import GHC.Generics (Generic)
import Control.Applicative ((<|>))
import Data.Aeson
  ( ToJSON(..)
  , FromJSON(..)
  , Value(..)
  , object
  , (.=)
  , (.:)
  , (.:?)
  , (.!=)
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
  | Compare Expr Comparison Expr  -- ^ numeric condition, e.g. a field > 0
  | And [Predicate]
  | Or [Predicate]
  deriving (Show, Eq, Generic)

instance ToJSON Predicate where
  toJSON (Equals fid val) = object [ "op" .= ("equals" :: String), "fieldId" .= fid, "value" .= val ]
  toJSON (NotEquals fid val) = object [ "op" .= ("notEquals" :: String), "fieldId" .= fid, "value" .= val ]
  toJSON (IsTrue fid) = object [ "op" .= ("isTrue" :: String), "fieldId" .= fid ]
  toJSON (Compare l cmp r) = object [ "op" .= ("compare" :: String), "left" .= l, "comparison" .= cmp, "right" .= r ]
  toJSON (And preds) = object [ "op" .= ("and" :: String), "conditions" .= preds ]
  toJSON (Or preds) = object [ "op" .= ("or" :: String), "conditions" .= preds ]

instance FromJSON Predicate where
  parseJSON = withObject "Predicate" $ \o -> do
    op <- o .: "op"
    case (op :: String) of
      "equals"     -> Equals <$> o .: "fieldId" <*> o .: "value"
      "notEquals"  -> NotEquals <$> o .: "fieldId" <*> o .: "value"
      "isTrue"     -> IsTrue <$> o .: "fieldId"
      "compare"    -> Compare <$> o .: "left" <*> o .: "comparison" <*> o .: "right"
      "and"        -> And <$> o .: "conditions"
      "or"         -> Or <$> o .: "conditions"
      other        -> fail $ "Unknown predicate operation: " ++ other

-- | Numeric expression over answered field values.
-- Target-neutral: interpreters (SchemaDSL.Eval, Altinn, simulator) share these semantics:
-- an empty or non-numeric field counts as 0, and division by zero has no value.
data Expr
  = Field FieldId
  | Const Double
  | Add [Expr]
  | Sub Expr Expr
  | Mul [Expr]
  | Div Expr Expr
  deriving (Show, Eq, Generic)

instance ToJSON Expr where
  toJSON (Field fid) = object [ "op" .= ("field" :: String), "fieldId" .= fid ]
  toJSON (Const n)   = object [ "op" .= ("const" :: String), "value" .= n ]
  toJSON (Add es)    = object [ "op" .= ("add" :: String), "terms" .= es ]
  toJSON (Sub a b)   = object [ "op" .= ("sub" :: String), "left" .= a, "right" .= b ]
  toJSON (Mul es)    = object [ "op" .= ("mul" :: String), "terms" .= es ]
  toJSON (Div a b)   = object [ "op" .= ("div" :: String), "left" .= a, "right" .= b ]

instance FromJSON Expr where
  parseJSON = withObject "Expr" $ \o -> do
    op <- o .: "op"
    case (op :: String) of
      "field" -> Field <$> o .: "fieldId"
      "const" -> Const <$> o .: "value"
      "add"   -> Add <$> o .: "terms"
      "sub"   -> Sub <$> o .: "left" <*> o .: "right"
      "mul"   -> Mul <$> o .: "terms"
      "div"   -> Div <$> o .: "left" <*> o .: "right"
      other   -> fail $ "Unknown expression operation: " ++ other

-- | Sum of a list of fields, e.g. a total over its parts
sumOf :: [FieldId] -> Expr
sumOf = Add . map Field

-- | All fields referenced by an expression, in order of appearance
exprFields :: Expr -> [FieldId]
exprFields e = case e of
  Field fid -> [fid]
  Const _   -> []
  Add es    -> concatMap exprFields es
  Sub a b   -> exprFields a ++ exprFields b
  Mul es    -> concatMap exprFields es
  Div a b   -> exprFields a ++ exprFields b

-- | All fields referenced by a predicate
predicateFields :: Predicate -> [FieldId]
predicateFields p = case p of
  Equals fid _    -> [fid]
  NotEquals fid _ -> [fid]
  IsTrue fid      -> [fid]
  Compare l _ r   -> exprFields l ++ exprFields r
  And ps          -> concatMap predicateFields ps
  Or ps           -> concatMap predicateFields ps

-- | Relation between two expressions in a constraint or numeric condition
data Comparison = CmpEq | CmpNotEq | CmpLt | CmpLte | CmpGt | CmpGte
  deriving (Show, Eq, Generic)

instance ToJSON Comparison where
  toJSON c = toJSON $ case c of
    CmpEq    -> "eq" :: String
    CmpNotEq -> "notEq"
    CmpLt    -> "lt"
    CmpLte   -> "lte"
    CmpGt    -> "gt"
    CmpGte   -> "gte"

instance FromJSON Comparison where
  parseJSON v = do
    s <- parseJSON v
    case (s :: String) of
      "eq"    -> pure CmpEq
      "notEq" -> pure CmpNotEq
      "lt"    -> pure CmpLt
      "lte"   -> pure CmpLte
      "gt"    -> pure CmpGt
      "gte"   -> pure CmpGte
      other   -> fail $ "Unknown comparison: " ++ other

-- | Whether a violated constraint blocks submission or only warns the respondent
data Severity = SevError | SevWarning
  deriving (Show, Eq, Generic)

instance ToJSON Severity where
  toJSON SevError   = toJSON ("error" :: String)
  toJSON SevWarning = toJSON ("warning" :: String)

instance FromJSON Severity where
  parseJSON v = do
    s <- parseJSON v
    case (s :: String) of
      "error"   -> pure SevError
      "warning" -> pure SevWarning
      other     -> fail $ "Unknown severity: " ++ other

-- | Derived field: the value of calcTarget is always calcExpr (e.g. a total or a remainder)
data Calculation = Calculation
  { calcTarget :: FieldId
  , calcExpr   :: Expr
  } deriving (Show, Eq, Generic)

instance ToJSON Calculation where
  toJSON (Calculation tgt e) = object [ "fieldId" .= tgt, "expr" .= e ]

instance FromJSON Calculation where
  parseJSON = withObject "Calculation" $ \o ->
    Calculation <$> o .: "fieldId" <*> o .: "expr"

-- | Cross-field rule that must hold: left `comparison` right, e.g. sum of parts == total
data Constraint = Constraint
  { constraintId        :: String
  , constraintLeft      :: Expr
  , comparison          :: Comparison
  , constraintRight     :: Expr
  , message             :: String
  , severity            :: Severity
  , constraintCondition :: Maybe Predicate  -- ^ only checked when this holds
  , reportOn            :: [FieldId]        -- ^ fields showing the message; empty = inferred from the expressions
  } deriving (Show, Eq, Generic)

instance ToJSON Constraint where
  toJSON (Constraint cid l cmp r msg sev cond rep) =
    object $
      [ "constraintId" .= cid
      , "left"         .= l
      , "comparison"   .= cmp
      , "right"        .= r
      , "message"      .= msg
      , "severity"     .= sev
      ]
      ++ maybe [] (\c -> ["condition" .= c]) cond
      ++ [ "reportOn" .= rep | not (null rep) ]

instance FromJSON Constraint where
  parseJSON = withObject "Constraint" $ \o ->
    Constraint <$> o .: "constraintId"
               <*> o .: "left"
               <*> o .: "comparison"
               <*> o .: "right"
               <*> o .: "message"
               <*> o .:? "severity" .!= SevError
               <*> o .:? "condition"
               <*> o .:? "reportOn" .!= []

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

-- | A Bolk or thematic group of related questions with title, guidance, and optional condition
data Bolk = Bolk
  { bolkId          :: String
  , bolkTitle       :: String
  , bolkDescription :: Maybe String
  , bolkCondition   :: Maybe Predicate
  , bolkQuestions   :: [Question]
  } deriving (Show, Eq, Generic)

instance ToJSON Bolk where
  toJSON (Bolk bid ttl desc cond qs) =
    object $
      [ "type"        .= ("bolk" :: String)
      , "bolkId"      .= bid
      , "title"       .= ttl
      ]
      ++ maybe [] (\d -> ["description" .= d]) desc
      ++ maybe [] (\c -> ["condition" .= c]) cond
      ++ [ "questions" .= qs ]

instance FromJSON Bolk where
  parseJSON = withObject "Bolk" $ \o ->
    Bolk <$> o .: "bolkId"
         <*> o .: "title"
         <*> o .:? "description"
         <*> o .:? "condition"
         <*> o .: "questions"

-- | A Dialogue Step: either an atomic Question or a structured Bolk
data Step
  = QuestionStep Question
  | BolkStep Bolk
  deriving (Show, Eq, Generic)

instance ToJSON Step where
  toJSON (QuestionStep q) = toJSON q
  toJSON (BolkStep b)     = toJSON b

instance FromJSON Step where
  parseJSON v = (BolkStep <$> parseJSON v) <|> (QuestionStep <$> parseJSON v)

-- | Extract all questions in a dialogue regardless of whether they are in bolker or standalone
allDialogueQuestions :: Dialogue -> [Question]
allDialogueQuestions d = concatMap stepQuestions (steps d)
  where
    stepQuestions (QuestionStep q) = [q]
    stepQuestions (BolkStep b)     = bolkQuestions b

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
  , calculations :: [Calculation]
  , constraints  :: [Constraint]
  , steps      :: [Step]
  } deriving (Show, Eq, Generic)

instance ToJSON Dialogue where
  toJSON (Dialogue did ttl ctx calcs cons stps) =
    object $
      [ "$schema"    .= ("./baseline-schema-meta.json" :: String)
      , "dialogueId" .= did
      , "title"      .= ttl
      ]
      ++ maybe [] (\c -> ["context" .= c]) ctx
      ++ [ "calculations" .= calcs | not (null calcs) ]
      ++ [ "constraints" .= cons | not (null cons) ]
      ++ [ "steps" .= stps ]

instance FromJSON Dialogue where
  parseJSON = withObject "Dialogue" $ \o ->
    Dialogue <$> o .: "dialogueId"
             <*> o .: "title"
             <*> o .:? "context"
             <*> o .:? "calculations" .!= []
             <*> o .:? "constraints" .!= []
             <*> o .: "steps"

