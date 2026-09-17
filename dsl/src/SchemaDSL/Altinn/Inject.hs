{-# LANGUAGE OverloadedStrings #-}

module SchemaDSL.Altinn.Inject
  ( injectIntoAltinnApp
  , updateSettingsPageOrder
  , enforceEvolutionPageOrder
  , mergeTextResources
  , stripBOM
  ) where

import qualified Data.ByteString.Lazy as BL
import Data.List (sortBy)
import Data.Ord (comparing)
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
import SchemaDSL.Altinn.Types
import SchemaDSL.Altinn.Compile (compileToAltinn)
import SchemaDSL.Altinn.DataModel (updateJsonSchemaModel, updateCSharpModel)

-- | Inject compiled artifacts into target Altinn app checkout
injectIntoAltinnApp :: FilePath -> Dialogue -> IO ()
injectIntoAltinnApp targetDir d = do
  let artifacts = compileToAltinn d
      appDir = targetDir </> "App"
      uiDir = appDir </> "ui" </> "mainlayout"
      layoutsDir = uiDir </> "layouts"
      optionsDir = appDir </> "options"
      textsDir = appDir </> "config" </> "texts"
      modelsDir = appDir </> "models"

  putStrLn $ "Injecting artifacts into Altinn app at: " ++ targetDir

  -- 1. Ensure target subdirectories exist
  createDirectoryIfMissing True layoutsDir
  createDirectoryIfMissing True optionsDir
  createDirectoryIfMissing True textsDir
  createDirectoryIfMissing True modelsDir

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

  -- 6. Update Data Models: JSON Schema & C# definitions for SkjemaData
  updateJsonSchemaModel modelsDir d
  updateCSharpModel modelsDir d

  putStrLn "Successfully completed Altinn schema injection!"

-- | Strip UTF-8 Byte Order Mark (EF BB BF) if present
stripBOM :: BL.ByteString -> BL.ByteString
stripBOM bs
  | BL.isPrefixOf (BL.pack [0xEF, 0xBB, 0xBF]) bs = BL.drop 3 bs
  | otherwise                                     = bs

-- | Canonical schema evolution rank for demoing schema development progress
evolutionRank :: T.Text -> Int
evolutionRank p
  | p == "S05_hack4ssb_hello"          = 10  -- v1: Minimal Hello World baseline
  | p == "S05_hack4ssb_comprehensive"  = 20  -- v2: Extended synthetic schema with full question types
  | p == "S05_kostra51_kulturminner"   = 30  -- v3: OCR screenshot prototype (B1 Kulturminner)
  | p == "S05_kostra51_side1"          = 41  -- v4.1: Skjema 51 Side 1
  | p == "S05_kostra51_side2"          = 42  -- v4.2: Skjema 51 Side 2
  | p == "S05_kostra51_side3"          = 43  -- v4.3: Skjema 51 Side 3
  | p == "S05_kostra51_side4"          = 44  -- v4.4: Skjema 51 Side 4
  | p == "S05_kostra51_side5"          = 45  -- v4.5: Skjema 51 Side 5
  | p == "S05_kostra51_side6"          = 46  -- v4.6: Skjema 51 Side 6
  | otherwise                          = 999 -- Other / custom pages

-- | Sort injected pages by schema evolution progression while preserving outer boundary pages
sortPagesByEvolution :: [T.Text] -> [T.Text]
sortPagesByEvolution pages =
  let (before, rest1) = break (== "S01_Forside") pages
      (prefix, withoutPrefix) = case rest1 of
        (f:rest) -> (before ++ [f], rest)
        []       -> ([], pages)
      (injected, suffix) = break (`elem` ["S20_Summary", "S70_Tidsbruk", "S80_Brukeropplevelse", "S90_Kommentarogkontakt"]) withoutPrefix
      sortedInjected = sortBy (comparing evolutionRank) injected
  in prefix ++ sortedInjected ++ suffix

-- | Helper to insert pageName into pages.groups[0].order in schema evolution order
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
              baseList = if pNameT `elem` listOrd then listOrd else listOrd ++ [pNameT]
              newListOrd = sortPagesByEvolution baseList
          in Object (KM.insert "order" (Array (V.fromList (map String newListOrd))) gObj)
        _ -> Object gObj
    updateGroup other = other

-- | Standalone helper to enforce canonical schema evolution order on Settings.json
enforceEvolutionPageOrder :: KM.KeyMap Value -> KM.KeyMap Value
enforceEvolutionPageOrder km =
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
              newListOrd = sortPagesByEvolution listOrd
          in Object (KM.insert "order" (Array (V.fromList (map String newListOrd))) gObj)
        _ -> Object gObj
    updateGroup other = other

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
