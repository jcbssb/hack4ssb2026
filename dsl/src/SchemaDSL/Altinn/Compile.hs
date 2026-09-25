{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module SchemaDSL.Altinn.Compile
  ( compileToAltinn
  , compileSteps
  , compileStepItems
  , compilePredicateToHidden
  , compileExpr
  , compileConstraints
  ) where

import Data.Aeson
  ( Value(..)
  , object
  , (.=)
  )
import qualified Data.Aeson.KeyMap as KM
import qualified Data.Vector as V
import qualified Data.Text as T
import SchemaDSL.Types
import Data.List (nub)
import SchemaDSL.Eval (constraintTargets, enteredInputs)
import SchemaDSL.Altinn.Types

-- | Compile generic Dialogue to Altinn artifacts using model binding helper strategy
compileToAltinn :: Dialogue -> AltinnArtifacts
compileToAltinn d@Dialogue{ dialogueId = did, title = dTitle, context = dCtx, calculations = dCalcs, steps = dSteps } =
  let dIdClean = sanitizeName did
      pgName = "S05_" ++ dIdClean
      headerId = dIdClean ++ "-header"
      panelId  = dIdClean ++ "-panel-info"

      -- Base header and panel components
      headerComp = object
        [ "id"                   .= (headerId :: String)
        , "type"                 .= ("Header" :: String)
        , "size"                 .= ("h2" :: String)
        , "textResourceBindings" .= object [ "title" .= ("lang." ++ dIdClean ++ ".tittel") ]
        ]

      panelComp = object
        [ "id"                   .= (panelId :: String)
        , "type"                 .= ("Panel" :: String)
        , "variant"              .= ("info" :: String)
        , "showIcon"             .= True
        , "textResourceBindings" .= object
            [ "title" .= ("lang." ++ dIdClean ++ ".panel.title")
            , "body"  .= ("lang." ++ dIdClean ++ ".panel.body")
            ]
        , "grid"                 .= object [ "xs" .= (12 :: Int) ]
        ]

      -- Compile steps (both standalone questions and grouped bolker)
      (stepComps, stepOpts, stepTexts) = compileStepItems dIdClean dCalcs dSteps
      (validationRules, constraintTexts) = compileConstraints d

      -- Navigation buttons at the end of the page
      navComp = object
        [ "id"                   .= (dIdClean ++ "-nav-buttons")
        , "type"                 .= ("NavigationButtons" :: String)
        , "textResourceBindings" .= object
            [ "next" .= ("lang.tittel.navigation.neste" :: String)
            , "back" .= ("lang.tittel.navigation.tilbake" :: String)
            ]
        , "showBackButton"       .= True
        , "validateOnNext"       .= object
            [ "page" .= ("current" :: String)
            , "show" .= (["All"] :: [String])
            ]
        ]

      fullLayout = object
        [ "$schema" .= ("https://altinncdn.no/toolkits/altinn-app-frontend/4/schemas/json/layout/layout.schema.v1.json" :: String)
        , "data"    .= object [ "layout" .= ([headerComp, panelComp] ++ stepComps ++ [navComp]) ]
        ]

      baseTexts =
        [ (pgName, dTitle)
        , ("lang." ++ dIdClean ++ ".tittel", dTitle)
        , ("lang." ++ dIdClean ++ ".panel.title", "Om registreringen")
        , ("lang." ++ dIdClean ++ ".panel.body", maybe "Dette skjemaet samler inn opplysninger." (maybe "" id . legalNotice) dCtx)
        ]

  in AltinnArtifacts
      { pageName      = pgName
      , pageLayout    = fullLayout
      , optionsLists  = stepOpts
      , textResources = baseTexts ++ stepTexts ++ constraintTexts
      , validations   = validationRules
      }

-- | Convert DSL Predicate to Altinn Frontend v4 hidden rule expression
compilePredicateToHidden :: String -> [Calculation] -> Predicate -> Value
compilePredicateToHidden dIdClean calcs p =
  case p of
    Equals fid val ->
      expr [ String "notEquals", ref fid, str val ]
    NotEquals fid val ->
      expr [ String "equals", ref fid, str val ]
    IsTrue fid ->
      expr [ String "notEquals", ref fid, String "true" ]
    Compare l cmp r ->
      expr [ String "not", compileComparison dIdClean calcs cmp l r ]
    And preds ->
      expr (String "or" : map (compilePredicateToHidden dIdClean calcs) preds)
    Or preds ->
      expr (String "and" : map (compilePredicateToHidden dIdClean calcs) preds)
  where
    ref fid = expr [ String "dataModel", str (fieldPath dIdClean fid) ]

-- | Compile list of Questions to layout components, options, and text resources
compileSteps :: String -> [Calculation] -> [Question] -> ([Value], [(String, Value)], [(String, String)])
compileSteps dIdClean calcs qs =
  let go [] = ([], [], [])
      go (q : rest) =
        let fid = fieldId q
            compLabelKey = "lang." ++ dIdClean ++ "." ++ fid ++ ".label"
            compHelpKey  = "lang." ++ dIdClean ++ "." ++ fid ++ ".help"
            modelBinding = "SkjemaData." ++ dIdClean ++ "." ++ fid
            prefix = dIdClean ++ "-" ++ fid

            labelTxt = label (prompt q)
            helpTxt  = maybe "" id (helpText (prompt q))
            hasHelp  = case helpText (prompt q) of
              Just txt -> not (null txt)
              Nothing  -> False
            curTexts = [ (compLabelKey, labelTxt) ]
                       ++ [ (compHelpKey, helpTxt) | hasHelp ]

            trbBindings =
              [ "title" .= compLabelKey ]
              ++ [ "description" .= compHelpKey | hasHelp ]

            hiddenProp = case (condition (q :: Question)) of
              Just cond -> [ "hidden" .= compilePredicateToHidden dIdClean calcs cond ]
              Nothing   -> []

            gridProp = case annotations q of
              Just ann | Just (Number xsVal) <- KM.lookup "gridXs" ann ->
                object [ "xs" .= (round xsVal :: Int) ]
              _ -> object [ "xs" .= (12 :: Int) ]

            readOnlyProp = case annotations q of
              Just ann | Just (Bool True) <- KM.lookup "readOnly" ann -> [ "readOnly" .= True ]
              _ -> []

            decimalScaleVal = case annotations q of
              Just ann | Just (Number n) <- KM.lookup "decimalScale" ann -> round n :: Int
              _ -> 1 :: Int

            (comp, opts) = case lookup fid [ (calcTarget c, calcExpr c) | c <- calcs ] of
              -- Calculated fields are display-only and derived in the frontend
              Just calcE | questionType q `elem` [QInteger, QDecimal] ->
                let scale = if questionType q == QInteger then 0 else decimalScaleVal
                    c = object $
                      [ "id"                   .= (prefix ++ "-number")
                      , "type"                 .= ("Number" :: String)
                      , "value"                .= compileExpr dIdClean calcs calcE
                      , "formatting"           .= object [ "number" .= object [ "decimalScale" .= scale ] ]
                      , "textResourceBindings" .= object trbBindings
                      , "grid"                 .= gridProp
                      ] ++ hiddenProp
                in (c, [])
              _ -> compileInput

            compileInput = case questionType q of
              QText ->
                let c = object $
                      [ "id"                   .= (prefix ++ "-input")
                      , "type"                 .= ("Input" :: String)
                      , "textResourceBindings" .= object trbBindings
                      , "dataModelBindings"    .= object [ "simpleBinding" .= modelBinding ]
                      , "required"             .= required q
                      , "grid"                 .= gridProp
                      , "labelSettings"        .= object [ "optionalIndicator" .= False ]
                      ] ++ hiddenProp ++ readOnlyProp
                in (c, [])

              QTextArea ->
                let c = object $
                      [ "id"                   .= (prefix ++ "-textarea")
                      , "type"                 .= ("TextArea" :: String)
                      , "textResourceBindings" .= object trbBindings
                      , "dataModelBindings"    .= object [ "simpleBinding" .= modelBinding ]
                      , "required"             .= required q
                      , "grid"                 .= gridProp
                      , "labelSettings"        .= object [ "optionalIndicator" .= False ]
                      ] ++ hiddenProp ++ readOnlyProp
                in (c, [])

              QInteger ->
                let c = object $
                      [ "id"                   .= (prefix ++ "-input")
                      , "type"                 .= ("Input" :: String)
                      , "formatting"           .= object
                          [ "number" .= object
                              [ "allowNegative" .= False
                              ]
                          ]
                      , "textResourceBindings" .= object trbBindings
                      , "dataModelBindings"    .= object [ "simpleBinding" .= modelBinding ]
                      , "required"             .= required q
                      , "grid"                 .= gridProp
                      , "labelSettings"        .= object [ "optionalIndicator" .= False ]
                      ] ++ hiddenProp ++ readOnlyProp
                in (c, [])

              QDecimal ->
                let c = object $
                      [ "id"                   .= (prefix ++ "-input")
                      , "type"                 .= ("Input" :: String)
                      , "formatting"           .= object
                          [ "number" .= object
                              [ "decimalScale"  .= decimalScaleVal
                              , "allowNegative" .= False
                              ]
                          ]
                      , "textResourceBindings" .= object trbBindings
                      , "dataModelBindings"    .= object [ "simpleBinding" .= modelBinding ]
                      , "required"             .= required q
                      , "grid"                 .= object [ "xs" .= (12 :: Int), "innerGrid" .= object [ "md" .= (4 :: Int) ] ]
                      , "labelSettings"        .= object [ "optionalIndicator" .= False ]
                      ] ++ hiddenProp ++ readOnlyProp
                in (c, [])

              QDate ->
                let c = object $
                      [ "id"                   .= (prefix ++ "-datepicker")
                      , "type"                 .= ("Datepicker" :: String)
                      , "timeStamp"            .= False
                      , "textResourceBindings" .= object trbBindings
                      , "dataModelBindings"    .= object [ "simpleBinding" .= modelBinding ]
                      , "required"             .= required q
                      , "grid"                 .= object [ "xs" .= (12 :: Int), "innerGrid" .= object [ "md" .= (6 :: Int) ] ]
                      , "labelSettings"        .= object [ "optionalIndicator" .= False ]
                      ] ++ hiddenProp
                in (c, [])

              QBoolean ->
                let optionsName = capitalize fid ++ "Valg"
                    optArray = V.fromList
                      [ object [ "label" .= ("Ja" :: String), "value" .= ("true" :: String) ]
                      , object [ "label" .= ("Nei" :: String), "value" .= ("false" :: String) ]
                      ]
                    c = object $
                      [ "id"                   .= (prefix ++ "-radio")
                      , "type"                 .= ("RadioButtons" :: String)
                      , "textResourceBindings" .= object trbBindings
                      , "dataModelBindings"    .= object [ "simpleBinding" .= modelBinding ]
                      , "optionsId"            .= optionsName
                      , "required"             .= required q
                      , "grid"                 .= object [ "xs" .= (12 :: Int), "innerGrid" .= object [ "xs" .= (12 :: Int) ] ]
                      , "labelSettings"        .= object [ "optionalIndicator" .= False ]
                      ] ++ hiddenProp
                in (c, [(optionsName ++ ".json", Array optArray)])

              QChoice optStrings ->
                let optionsName = capitalize fid ++ "Valg"
                    optArray = V.fromList (map (\o -> object [ "label" .= o, "value" .= o ]) optStrings)
                    c = object $
                      [ "id"                   .= (prefix ++ "-radio")
                      , "type"                 .= ("RadioButtons" :: String)
                      , "textResourceBindings" .= object trbBindings
                      , "dataModelBindings"    .= object [ "simpleBinding" .= modelBinding ]
                      , "optionsId"            .= optionsName
                      , "required"             .= required q
                      , "grid"                 .= object [ "xs" .= (12 :: Int), "innerGrid" .= object [ "xs" .= (12 :: Int) ] ]
                      , "labelSettings"        .= object [ "optionalIndicator" .= False ]
                      ] ++ hiddenProp
                in (c, [(optionsName ++ ".json", Array optArray)])

              QMultiChoice optStrings ->
                let optionsName = capitalize fid ++ "Valg"
                    optArray = V.fromList (map (\o -> object [ "label" .= o, "value" .= o ]) optStrings)
                    c = object $
                      [ "id"                   .= (prefix ++ "-checkboxes")
                      , "type"                 .= ("Checkboxes" :: String)
                      , "textResourceBindings" .= object trbBindings
                      , "dataModelBindings"    .= object [ "simpleBinding" .= modelBinding ]
                      , "optionsId"            .= optionsName
                      , "required"             .= required q
                      , "grid"                 .= object [ "xs" .= (12 :: Int), "innerGrid" .= object [ "xs" .= (12 :: Int) ] ]
                      , "labelSettings"        .= object [ "optionalIndicator" .= False ]
                      ] ++ hiddenProp
                in (c, [(optionsName ++ ".json", Array optArray)])

            (nextComps, nextOpts, nextTexts) = go rest
        in (comp : nextComps, opts ++ nextOpts, curTexts ++ nextTexts)
  in go qs

-- | Compile list of Steps (either Questions or Bolker) to layout components, options, and text resources
compileStepItems :: String -> [Calculation] -> [Step] -> ([Value], [(String, Value)], [(String, String)])
compileStepItems dIdClean calcs stepList = goItems stepList
  where
    goItems [] = ([], [], [])
    goItems (x:xs) =
      let (c1, o1, t1) = processItem x
          (c2, o2, t2) = goItems xs
      in (c1 ++ c2, o1 ++ o2, t1 ++ t2)

    processItem (QuestionStep q) =
      compileSteps dIdClean calcs [q]

    processItem (BolkStep b) =
      let bIdClean = sanitizeName (bolkId b)
          bHeaderId = dIdClean ++ "-bolk-" ++ bIdClean ++ "-header"
          bDescId   = dIdClean ++ "-bolk-" ++ bIdClean ++ "-desc"

          bTitleKey = "lang." ++ dIdClean ++ ".bolk." ++ bIdClean ++ ".title"
          bDescKey  = "lang." ++ dIdClean ++ ".bolk." ++ bIdClean ++ ".desc"

          bHiddenProp = case bolkCondition b of
            Just cond -> [ "hidden" .= compilePredicateToHidden dIdClean calcs cond ]
            Nothing   -> []

          bHeaderComp = object $
            [ "id"                   .= (bHeaderId :: String)
            , "type"                 .= ("Header" :: String)
            , "size"                 .= ("h3" :: String)
            , "textResourceBindings" .= object [ "title" .= bTitleKey ]
            , "grid"                 .= object [ "xs" .= (12 :: Int) ]
            ] ++ bHiddenProp

          (bDescCompList, bDescTexts) = case bolkDescription b of
            Just descTxt ->
              let comp = object $
                    [ "id"                   .= (bDescId :: String)
                    , "type"                 .= ("Paragraph" :: String)
                    , "textResourceBindings" .= object [ "title" .= bDescKey ]
                    , "grid"                 .= object [ "xs" .= (12 :: Int) ]
                    ] ++ bHiddenProp
              in ([comp], [(bDescKey, descTxt)])
            Nothing -> ([], [])

          bBaseTexts = (bTitleKey, bolkTitle b) : bDescTexts
          (qComps, qOpts, qTexts) = compileSteps dIdClean calcs (bolkQuestions b)
      in ([bHeaderComp] ++ bDescCompList ++ qComps, qOpts, bBaseTexts ++ qTexts)

-- | Data model path for a field in this dialogue
fieldPath :: String -> FieldId -> String
fieldPath dIdClean fid = "SkjemaData." ++ dIdClean ++ "." ++ fid

-- | Compile a DSL expression to an Altinn number expression. Calculated fields are
-- inlined (they are not stored), and empty fields count as 0 as in SchemaDSL.Eval.
compileExpr :: String -> [Calculation] -> Expr -> Value
compileExpr dIdClean calcs e = case e of
  Field fid -> case lookup fid [ (calcTarget c, calcExpr c) | c <- calcs ] of
    Just inner -> compileExpr dIdClean (filter ((/= fid) . calcTarget) calcs) inner
    Nothing ->
      let ref = expr [ String "dataModel", str (fieldPath dIdClean fid) ]
      in expr [ String "if", expr [ String "equals", ref, Null ], Number 0, String "else", ref ]
  Const n  -> Number (realToFrac n)
  Add []   -> Number 0
  Add [x]  -> go x
  Add xs   -> expr (String "plus" : map go xs)
  Sub a b  -> expr [ String "minus", go a, go b ]
  Mul []   -> Number 1
  Mul [x]  -> go x
  Mul xs   -> expr (String "multiply" : map go xs)
  Div a b  -> expr [ String "divide", go a, go b ]
  where
    go = compileExpr dIdClean calcs

-- | Compile constraints to expression validations keyed by data model path,
-- plus the text resources for their messages. A validation's condition is true
-- when the constraint is violated.
compileConstraints :: Dialogue -> ([(String, [Value])], [(String, String)])
compileConstraints d =
  let dIdClean = sanitizeName (dialogueId d)
      calcs = calculations d
      relation c = compileComparison dIdClean calcs (comparison c) (constraintLeft c) (constraintRight c)
      violated c = case constraintCondition c of
        Just p  -> expr [ String "and", compilePredicate dIdClean calcs p, expr [ String "not", relation c ] ]
        Nothing -> expr [ String "not", relation c ]
      msgKey c = "lang." ++ dIdClean ++ ".constraint." ++ constraintId c
      validation c = object
        [ "message"   .= msgKey c
        , "severity"  .= (case severity c of SevError -> "error"; SevWarning -> "warning" :: String)
        , "condition" .= violated c
        ]
      -- Calculated fields are unbound Number components, so their messages go to their inputs
      perField = [ (fieldPath dIdClean fid, validation c)
                 | c <- constraints d
                 , fid <- nub (concatMap (enteredInputs d) (constraintTargets d c))
                 ]
      paths = foldr (\(p, _) acc -> if p `elem` acc then acc else p : acc) [] perField
  in ( [ (p, [ v | (p', v) <- perField, p' == p ]) | p <- paths ]
     , [ (msgKey c, message c) | c <- constraints d ]
     )

-- | Positive (non-negated) predicate expression, used as a constraint guard
compilePredicate :: String -> [Calculation] -> Predicate -> Value
compilePredicate dIdClean calcs p = case p of
  Equals fid v    -> expr [ String "equals", ref fid, str v ]
  NotEquals fid v -> expr [ String "notEquals", ref fid, str v ]
  IsTrue fid      -> expr [ String "equals", ref fid, String "true" ]
  Compare l cmp r -> compileComparison dIdClean calcs cmp l r
  And ps          -> expr (String "and" : map (compilePredicate dIdClean calcs) ps)
  Or ps           -> expr (String "or" : map (compilePredicate dIdClean calcs) ps)
  where
    ref fid = expr [ String "dataModel", str (fieldPath dIdClean fid) ]

-- | Numeric comparison; both sides are rounded to 6 decimals to match the
-- tolerance in SchemaDSL.Eval.compareValues
compileComparison :: String -> [Calculation] -> Comparison -> Expr -> Expr -> Value
compileComparison dIdClean calcs cmp l r =
  let op = case cmp of
        CmpEq    -> "equals"
        CmpNotEq -> "notEquals"
        CmpLt    -> "lessThan"
        CmpLte   -> "lessThanEq"
        CmpGt    -> "greaterThan"
        CmpGte   -> "greaterThanEq"
      rounded x = expr [ String "round", compileExpr dIdClean calcs x, Number 6 ]
  in expr [ String op, rounded l, rounded r ]

expr :: [Value] -> Value
expr = Array . V.fromList

str :: String -> Value
str = String . T.pack
