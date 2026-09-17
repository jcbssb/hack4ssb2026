{-# LANGUAGE OverloadedStrings #-}

module SchemaDSL.Altinn.Compile
  ( compileToAltinn
  , compileSteps
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
compileToAltinn d =
  let dIdClean = sanitizeName (dialogueId d)
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

      -- Compile question steps to components, options, and text resources
      (stepComps, stepOpts, stepTexts) = compileSteps dIdClean (steps d)

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
        [ (pgName, title d)
        , ("lang." ++ dIdClean ++ ".tittel", title d)
        , ("lang." ++ dIdClean ++ ".panel.title", "Om registreringen")
        , ("lang." ++ dIdClean ++ ".panel.body", maybe "Dette skjemaet samler inn opplysninger." (maybe "" id . legalNotice) (context d))
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
            curTexts = [ (compLabelKey, labelTxt), (compHelpKey, helpTxt) ]

            hiddenProp = case condition q of
              Just cond -> [ "hidden" .= compilePredicateToHidden fieldMap cond ]
              Nothing   -> []

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
                      , "textResourceBindings" .= object [ "title" .= compLabelKey, "help" .= compHelpKey ]
                      , "dataModelBindings"    .= object [ "simpleBinding" .= modelBinding ]
                      , "required"             .= required q
                      , "grid"                 .= object [ "xs" .= (12 :: Int), "innerGrid" .= object [ "md" .= (8 :: Int) ] ]
                      , "labelSettings"        .= object [ "optionalIndicator" .= False ]
                      ] ++ hiddenProp ++ readOnlyProp
                in (c, [])

              QTextArea ->
                let c = object $
                      [ "id"                   .= (prefix ++ "-textarea")
                      , "type"                 .= ("TextArea" :: String)
                      , "textResourceBindings" .= object [ "title" .= compLabelKey, "help" .= compHelpKey ]
                      , "dataModelBindings"    .= object [ "simpleBinding" .= modelBinding ]
                      , "required"             .= required q
                      , "grid"                 .= object [ "xs" .= (12 :: Int) ]
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
                      , "textResourceBindings" .= object [ "title" .= compLabelKey, "help" .= compHelpKey ]
                      , "dataModelBindings"    .= object [ "simpleBinding" .= modelBinding ]
                      , "required"             .= required q
                      , "grid"                 .= object [ "xs" .= (12 :: Int), "innerGrid" .= object [ "md" .= (4 :: Int) ] ]
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
                      , "textResourceBindings" .= object [ "title" .= compLabelKey, "help" .= compHelpKey ]
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
                      , "textResourceBindings" .= object [ "title" .= compLabelKey, "help" .= compHelpKey ]
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
                      , "textResourceBindings" .= object [ "title" .= compLabelKey, "help" .= compHelpKey ]
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
                      , "textResourceBindings" .= object [ "title" .= compLabelKey, "help" .= compHelpKey ]
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
                      , "textResourceBindings" .= object [ "title" .= compLabelKey, "help" .= compHelpKey ]
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
