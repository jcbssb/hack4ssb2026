{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module SchemaDSL.Altinn.Compile
  ( compileToAltinn
  , compileSteps
  , compileStepItems
  , compilePredicateToHidden
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
import SchemaDSL.Altinn.Types

-- | Compile generic Dialogue to Altinn artifacts using model binding helper strategy
compileToAltinn :: Dialogue -> AltinnArtifacts
compileToAltinn Dialogue{ dialogueId = did, title = dTitle, context = dCtx, steps = dSteps } =
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
      (stepComps, stepOpts, stepTexts) = compileStepItems dIdClean dSteps

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
      , textResources = baseTexts ++ stepTexts
      }

-- | Convert DSL Predicate to Altinn Frontend v4 hidden rule expression
compilePredicateToHidden :: [(FieldId, String)] -> Predicate -> Value
compilePredicateToHidden fieldMap p =
  case p of
    Equals fid val ->
      let binding = resolveBinding fid fieldMap
      in Array $ V.fromList [ String "notEquals", Array (V.fromList [String "dataModel", String (T.pack binding)]), String (T.pack val) ]
    NotEquals fid val ->
      let binding = resolveBinding fid fieldMap
      in Array $ V.fromList [ String "equals", Array (V.fromList [String "dataModel", String (T.pack binding)]), String (T.pack val) ]
    IsTrue fid ->
      let binding = resolveBinding fid fieldMap
      in Array $ V.fromList [ String "notEquals", Array (V.fromList [String "dataModel", String (T.pack binding)]), String "true" ]
    And preds ->
      Array $ V.fromList (String "or" : map (compilePredicateToHidden fieldMap) preds)
    Or preds ->
      Array $ V.fromList (String "and" : map (compilePredicateToHidden fieldMap) preds)
  where
    resolveBinding fid fMap =
      case lookup fid fMap of
        Just b  -> b
        Nothing -> "SkjemaData." ++ fid

-- | Compile list of Questions to layout components, options, and text resources
compileSteps :: String -> [Question] -> ([Value], [(String, Value)], [(String, String)])
compileSteps dIdClean qs =
  let fieldMap = [ (fieldId q, "SkjemaData." ++ dIdClean ++ "." ++ fieldId q)
                 | q <- qs
                 ]
      go [] = ([], [], [])
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
              Just cond -> [ "hidden" .= compilePredicateToHidden fieldMap cond ]
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

            (comp, opts) = case questionType q of
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
compileStepItems :: String -> [Step] -> ([Value], [(String, Value)], [(String, String)])
compileStepItems dIdClean stepList = goItems stepList
  where
    allQs = concatMap getQs stepList
    getQs (QuestionStep q) = [q]
    getQs (BolkStep b)     = bolkQuestions b

    fieldMap = [ (fieldId q, "SkjemaData." ++ dIdClean ++ "." ++ fieldId q)
               | q <- allQs
               ]

    goItems [] = ([], [], [])
    goItems (x:xs) =
      let (c1, o1, t1) = processItem x
          (c2, o2, t2) = goItems xs
      in (c1 ++ c2, o1 ++ o2, t1 ++ t2)

    processItem (QuestionStep q) =
      compileSteps dIdClean [q]

    processItem (BolkStep b) =
      let bIdClean = sanitizeName (bolkId b)
          bHeaderId = dIdClean ++ "-bolk-" ++ bIdClean ++ "-header"
          bDescId   = dIdClean ++ "-bolk-" ++ bIdClean ++ "-desc"

          bTitleKey = "lang." ++ dIdClean ++ ".bolk." ++ bIdClean ++ ".title"
          bDescKey  = "lang." ++ dIdClean ++ ".bolk." ++ bIdClean ++ ".desc"

          bHiddenProp = case bolkCondition b of
            Just cond -> [ "hidden" .= compilePredicateToHidden fieldMap cond ]
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
          (qComps, qOpts, qTexts) = compileSteps dIdClean (bolkQuestions b)
      in ([bHeaderComp] ++ bDescCompList ++ qComps, qOpts, bBaseTexts ++ qTexts)
