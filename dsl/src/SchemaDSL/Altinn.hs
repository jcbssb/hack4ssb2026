{-# LANGUAGE OverloadedStrings #-}

module SchemaDSL.Altinn
  ( AltinnArtifacts(..)
  , compileToAltinn
  , injectIntoAltinnApp
  ) where

import qualified Data.ByteString.Lazy as BL
import Data.Aeson
  ( Value(..)
  , object
  , (.=)
  , decode
  )
import Data.Aeson.Encode.Pretty (encodePretty)
import qualified Data.Aeson.KeyMap as KM
import qualified Data.Vector as V
import qualified Data.Text as T
import System.Directory (createDirectoryIfMissing, doesFileExist)
import System.FilePath ((</>))
import SchemaDSL.Types

-- | Set of compiled Altinn 3 artifacts
data AltinnArtifacts = AltinnArtifacts
  { pageName      :: String                     -- e.g. "S05_Hack4SSB"
  , pageLayout    :: Value                      -- Content for App/ui/mainlayout/layouts/S05_Hack4SSB.json
  , optionsLists  :: [(String, Value)]          -- (Filename e.g. "Hack4ssbSporValg.json", OptionsArray)
  , textResources :: [(String, String)]         -- [(ResourceID, TextValue)]
  } deriving (Show, Eq)

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
      (stepComps, stepOpts, stepTexts) = compileSteps dIdClean (steps d) 1

      fullLayout = object
        [ "$schema" .= ("https://altinncdn.no/toolkits/altinn-app-frontend/4/schemas/json/layout/layout.schema.v1.json" :: String)
        , "data"    .= object [ "layout" .= ([headerComp, panelComp] ++ stepComps) ]
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
        Nothing -> "Hjelpefelter.hjelpefelt1"

-- | Compile list of Questions to layout components, options, and text resources
compileSteps :: String -> [Question] -> Int -> ([Value], [(String, Value)], [(String, String)])
compileSteps dIdClean qs startIdx =
  let fieldMap = [ (fieldId q, "Hjelpefelter.hjelpefelt" ++ show idx)
                 | (q, idx) <- zip qs [startIdx..]
                 ]
      go [] _ = ([], [], [])
      go (q : rest) idx =
        let fid = fieldId q
            compLabelKey = "lang." ++ dIdClean ++ "." ++ fid ++ ".label"
            compHelpKey  = "lang." ++ dIdClean ++ "." ++ fid ++ ".help"
            modelBinding = "Hjelpefelter.hjelpefelt" ++ show idx
            prefix = dIdClean ++ "-" ++ fid

            labelTxt = label (prompt q)
            helpTxt  = maybe "" id (helpText (prompt q))
            curTexts = [ (compLabelKey, labelTxt), (compHelpKey, helpTxt) ]

            hiddenProp = case condition q of
              Just cond -> [ "hidden" .= compilePredicateToHidden fieldMap cond ]
              Nothing   -> []

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
                      ] ++ hiddenProp
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
                      ] ++ hiddenProp
                in (c, [])

              QInteger ->
                let c = object $
                      [ "id"                   .= (prefix ++ "-input")
                      , "type"                 .= ("Input" :: String)
                      , "formatting"           .= object [ "number" .= object [ "maximumFractionDigits" .= (0 :: Int) ] ]
                      , "textResourceBindings" .= object [ "title" .= compLabelKey, "help" .= compHelpKey ]
                      , "dataModelBindings"    .= object [ "simpleBinding" .= modelBinding ]
                      , "required"             .= required q
                      , "grid"                 .= object [ "xs" .= (12 :: Int), "innerGrid" .= object [ "md" .= (8 :: Int) ] ]
                      , "labelSettings"        .= object [ "optionalIndicator" .= False ]
                      ] ++ hiddenProp
                in (c, [])

              QDecimal ->
                let c = object $
                      [ "id"                   .= (prefix ++ "-input")
                      , "type"                 .= ("Input" :: String)
                      , "formatting"           .= object [ "number" .= object [ "maximumFractionDigits" .= (2 :: Int) ] ]
                      , "textResourceBindings" .= object [ "title" .= compLabelKey, "help" .= compHelpKey ]
                      , "dataModelBindings"    .= object [ "simpleBinding" .= modelBinding ]
                      , "required"             .= required q
                      , "grid"                 .= object [ "xs" .= (12 :: Int), "innerGrid" .= object [ "md" .= (8 :: Int) ] ]
                      , "labelSettings"        .= object [ "optionalIndicator" .= False ]
                      ] ++ hiddenProp
                in (c, [])

              QDate ->
                let c = object $
                      [ "id"                   .= (prefix ++ "-date")
                      , "type"                 .= ("Datepicker" :: String)
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

            (nextComps, nextOpts, nextTexts) = go rest (idx + 1)
        in (comp : nextComps, opts ++ nextOpts, curTexts ++ nextTexts)
  in go qs startIdx

-- | Inject compiled artifacts into target Altinn app checkout
injectIntoAltinnApp :: FilePath -> Dialogue -> IO ()
injectIntoAltinnApp targetDir d = do
  let artifacts = compileToAltinn d
      appDir = targetDir </> "App"
      uiDir = appDir </> "ui" </> "mainlayout"
      layoutsDir = uiDir </> "layouts"
      optionsDir = appDir </> "options"
      textsDir = appDir </> "config" </> "texts"

  putStrLn $ "Injecting artifacts into Altinn app at: " ++ targetDir

  -- 1. Ensure target subdirectories exist
  createDirectoryIfMissing True layoutsDir
  createDirectoryIfMissing True optionsDir
  createDirectoryIfMissing True textsDir

  -- 2. Write Layout File: App/ui/mainlayout/layouts/<PageName>.json
  let layoutPath = layoutsDir </> (pageName artifacts ++ ".json")
  BL.writeFile layoutPath (encodePretty (pageLayout artifacts))
  putStrLn $ "  [+] Wrote layout: " ++ layoutPath

  -- 3. Write Options Files: App/options/<OptionsId>.json
  mapM_ (\(fname, val) -> do
    let optPath = optionsDir </> fname
    BL.writeFile optPath (encodePretty val)
    putStrLn $ "  [+] Wrote options: " ++ optPath
    ) (optionsLists artifacts)

  -- 4. Inject Page into App/ui/mainlayout/Settings.json
  let settingsPath = uiDir </> "Settings.json"
  settingsExist <- doesFileExist settingsPath
  if settingsExist
    then do
      content <- BL.readFile settingsPath
      case decode (stripBOM content) of
        Just (Object obj) -> do
          let updated = updateSettingsPageOrder (pageName artifacts) obj
          BL.writeFile settingsPath (encodePretty (Object updated))
          putStrLn $ "  [+] Updated page order in: " ++ settingsPath
        _ -> putStrLn $ "  [!] Warning: Failed to parse Settings.json at " ++ settingsPath
    else putStrLn $ "  [!] Warning: Settings.json not found at " ++ settingsPath

  -- 5. Merge Text Resources into App/config/texts/resource.{nb,nn,en}.json
  let textLangs = ["nb", "nn", "en"]
  mapM_ (\lang -> do
    let textPath = textsDir </> ("resource." ++ lang ++ ".json")
    tExists <- doesFileExist textPath
    if tExists
      then do
        content <- BL.readFile textPath
        case decode (stripBOM content) of
          Just (Object obj) -> do
            let updated = mergeTextResources (textResources artifacts) obj
            BL.writeFile textPath (encodePretty (Object updated))
            putStrLn $ "  [+] Merged " ++ show (length (textResources artifacts)) ++ " text keys into: " ++ textPath
          _ -> putStrLn $ "  [!] Warning: Failed to parse text resource at " ++ textPath
      else putStrLn $ "  [!] Warning: Text resource not found at " ++ textPath
    ) textLangs

  putStrLn "Successfully completed Altinn schema injection!"

-- | Strip UTF-8 Byte Order Mark (EF BB BF) if present
stripBOM :: BL.ByteString -> BL.ByteString
stripBOM bs
  | BL.isPrefixOf (BL.pack [0xEF, 0xBB, 0xBF]) bs = BL.drop 3 bs
  | otherwise                                     = bs

-- | Helper to insert pageName into pages.groups[0].order after S01_Forside
updateSettingsPageOrder :: String -> KM.KeyMap Value -> KM.KeyMap Value
updateSettingsPageOrder pName km =
  case KM.lookup "pages" km of
    Just (Object pObj) ->
      case KM.lookup "groups" pObj of
        Just (Array grps) ->
          let updatedGrps = V.map updateGroup grps
              newPObj = KM.insert "groups" (Array updatedGrps) pObj
          in KM.insert "pages" (Object newPObj) km
        _ -> km
    _ -> km
  where
    updateGroup (Object gObj) =
      case KM.lookup "order" gObj of
        Just (Array ord) ->
          let listOrd = [s | String s <- V.toList ord]
              pNameT = T.pack pName
              newListOrd = if pNameT `elem` listOrd
                             then listOrd
                             else insertAfter "S01_Forside" pNameT listOrd
          in Object (KM.insert "order" (Array (V.fromList (map String newListOrd))) gObj)
        _ -> Object gObj
    updateGroup other = other

    insertAfter _ item [] = [item]
    insertAfter target item (x : xs)
      | x == target = x : item : xs
      | otherwise   = x : insertAfter target item xs

-- | Helper to merge text resources without duplicating IDs
mergeTextResources :: [(String, String)] -> KM.KeyMap Value -> KM.KeyMap Value
mergeTextResources newRes km =
  case KM.lookup "resources" km of
    Just (Array resArr) ->
      let existingList = V.toList resArr
          existingIds = [i | Object o <- existingList, Just (String i) <- [KM.lookup "id" o]]
          newEntries = [ object ["id" .= k, "value" .= v]
                       | (k, v) <- newRes
                       , T.pack k `notElem` existingIds
                       ]
          allRes = existingList ++ newEntries
      in KM.insert "resources" (Array (V.fromList allRes)) km
    _ -> km

-- Standard helper conversions
sanitizeName :: String -> String
sanitizeName = map (\c -> if c == '-' then '_' else c)

capitalize :: String -> String
capitalize [] = []
capitalize (c:cs) = toUpper c : cs
  where
    toUpper x | x >= 'a' && x <= 'z' = toEnum (fromEnum x - 32)
              | otherwise            = x
