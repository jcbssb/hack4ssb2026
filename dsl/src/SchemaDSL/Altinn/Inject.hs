{-# LANGUAGE OverloadedStrings #-}

module SchemaDSL.Altinn.Inject
  ( injectIntoAltinnApp
  , updateSettingsPageOrder
  , mergeTextResources
  , stripBOM
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
