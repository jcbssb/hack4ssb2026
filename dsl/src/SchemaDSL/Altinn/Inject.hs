{-# LANGUAGE OverloadedStrings #-}

module SchemaDSL.Altinn.Inject
  ( injectIntoAltinnApp
  , injectIntoAltinnAppPaged
  , isOwnPage
  , updateSettingsPageOrder
  , enforceEvolutionPageOrder
  , mergeTextResources
  , mergeValidations
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
import Data.Aeson.Key (fromText, toText)
import qualified Data.Aeson.KeyMap as KM
import qualified Data.Vector as V
import qualified Data.Text as T
import System.Directory (createDirectoryIfMissing, doesFileExist, listDirectory, removeFile)
import System.FilePath ((</>))
import SchemaDSL.Types
import SchemaDSL.Altinn.Types
import SchemaDSL.Altinn.Compile (compileToAltinn, compileToAltinnPaged)
import SchemaDSL.Altinn.DataModel (updateJsonSchemaModel, updateCSharpModel)

-- | Inject a dialogue as one Altinn page
injectIntoAltinnApp :: FilePath -> Dialogue -> IO ()
injectIntoAltinnApp targetDir d = injectArtifacts targetDir d (compileToAltinn d)

-- | Inject a dialogue as one Altinn page per bolk
injectIntoAltinnAppPaged :: FilePath -> Dialogue -> IO ()
injectIntoAltinnAppPaged targetDir d = injectArtifacts targetDir d (compileToAltinnPaged d)

-- | Whether a page belongs to the dialogue with base page name `base`:
-- the base itself or a numbered page <base>_NN
isOwnPage :: String -> String -> Bool
isOwnPage base p =
  p == base || (take (length base + 1) p == base ++ "_" && isNumbered (drop (length base + 1) p))
  where
    isNumbered n = not (null n) && all (`elem` ("0123456789" :: String)) n

-- | Inject compiled artifacts into target Altinn app checkout. Pages previously
-- injected for the same dialogue (single or paged) are replaced.
injectArtifacts :: FilePath -> Dialogue -> AltinnArtifacts -> IO ()
injectArtifacts targetDir d artifacts = do
  let appDir = targetDir </> "App"
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

  -- 2. Write Layout Files: App/ui/mainlayout/layouts/<PageName>.json, removing stale pages
  let base = "S05_" ++ sanitizeName (dialogueId d)
      newNames = map fst (pages artifacts)
  existingLayouts <- listDirectory layoutsDir
  mapM_ (\f -> do
    removeFile (layoutsDir </> f)
    putStrLn $ "  [-] Removed stale layout: " ++ (layoutsDir </> f)
    ) [ f | f <- existingLayouts
          , Just n <- [stripJsonSuffix f]
          , isOwnPage base n
          , n `notElem` newNames ]
  mapM_ (\(name, layout) -> do
    let layoutPath = layoutsDir </> (name ++ ".json")
    BL.writeFile layoutPath (encodePretty layout)
    putStrLn $ "  [+] Wrote layout: " ++ layoutPath
    ) (pages artifacts)

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
          let updated = updateSettingsPages base newNames obj
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

  -- 7. Merge constraint validations into App/models/A3_RA-1000_M.validation.json
  let validationPath = modelsDir </> "A3_RA-1000_M.validation.json"
      dataPrefix = T.pack ("SkjemaData." ++ sanitizeName (dialogueId d) ++ ".")
  vExists <- doesFileExist validationPath
  existing <- if vExists
    then do
      content <- BL.readFile validationPath
      pure $ case decode (stripBOM content) of
        Just (Object obj) -> obj
        _                 -> KM.empty
    else pure KM.empty
  let mergedValidations = mergeValidations dataPrefix (validations artifacts) existing
  if null (validations artifacts) && not vExists
    then pure ()
    else do
      BL.writeFile validationPath (encodePretty (Object mergedValidations))
      putStrLn $ "  [+] Wrote " ++ show (length (validations artifacts)) ++ " validated fields to: " ++ validationPath

  putStrLn "Successfully completed Altinn schema injection!"

stripJsonSuffix :: FilePath -> Maybe String
stripJsonSuffix f =
  let n = length f - length (".json" :: String)
  in if n > 0 && drop n f == ".json" then Just (take n f) else Nothing

-- | Strip UTF-8 Byte Order Mark (EF BB BF) if present
stripBOM :: BL.ByteString -> BL.ByteString
stripBOM bs
  | BL.isPrefixOf (BL.pack [0xEF, 0xBB, 0xBF]) bs = BL.drop 3 bs
  | otherwise                                     = bs

-- | Canonical schema evolution rank for demoing schema development progress.
-- Numbered pages (<base>_NN from paged injection) rank with their base page.
evolutionRank :: T.Text -> Int
evolutionRank page = baseRank (stripPageNumber page)
  where
    stripPageNumber t =
      let (pre, num) = T.breakOnEnd "_" t
      in if not (T.null num) && T.all (`elem` ("0123456789" :: String)) num && T.length pre > 1
           then T.dropEnd 1 pre
           else t

baseRank :: T.Text -> Int
baseRank p
  | p == "S05_hack4ssb_hello"          = 10  -- v1: Minimal Hello World baseline
  | p == "S05_hack4ssb_comprehensive"  = 20  -- v2: Extended synthetic schema with full question types
  | p == "S05_kostra51_kulturminner"   = 30  -- v3: OCR screenshot prototype (B1 Kulturminner)
  | p == "S05_kostra51_side1"          = 41  -- v4.1: Skjema 51 Side 1
  | p == "S05_kostra51_side2"          = 42  -- v4.2: Skjema 51 Side 2
  | p == "S05_kostra51_side3"          = 43  -- v4.3: Skjema 51 Side 3
  | p == "S05_kostra51_side4"          = 44  -- v4.4: Skjema 51 Side 4
  | p == "S05_kostra51_side5"          = 45  -- v4.5: Skjema 51 Side 5
  | p == "S05_kostra51_side6"          = 46  -- v4.6: Skjema 51 Side 6
  | p == "S05_trial1_byggesak"         = 51  -- v5.1: 20Byggesak Trial 1 (Metadata & Gebyrer)
  | p == "S05_trial2_byggesak"         = 52  -- v5.2: 20Byggesak Trial 2
  | p == "S05_trial3_byggesak"         = 53  -- v5.3: 20Byggesak Trial 3
  | p == "S05_trial4_byggesak"         = 54  -- v5.4: 20Byggesak Trial 4
  | p == "S05_trial5_byggesak"         = 55  -- v5.5: 20Byggesak Trial 5 (full PDF rebuild with rules, one page per bolk)
  | p == "S05_hack4ssb_matrix"         = 60  -- Matrix builder demo
  | otherwise                          = 999 -- Other / custom pages

-- | Sort injected pages by schema evolution progression while preserving outer boundary pages
sortPagesByEvolution :: [T.Text] -> [T.Text]
sortPagesByEvolution pageOrder =
  let (before, rest1) = break (== "S01_Forside") pageOrder
      (prefix, withoutPrefix) = case rest1 of
        (f:rest) -> (before ++ [f], rest)
        []       -> ([], pageOrder)
      -- Exclude both the fixed suffix pages AND any injected pages that might have been appended at the end
      fixedSuffix = ["S20_Summary", "S70_Tidsbruk", "S80_Brukeropplevelse", "S90_Kommentarogkontakt"]
      isFixedSuffix p = p `elem` fixedSuffix
      injectedPages = filter (\p -> not (isFixedSuffix p)) withoutPrefix
      suffixPages   = filter isFixedSuffix withoutPrefix
      sortedInjected = sortBy (comparing evolutionRank) injectedPages
  in prefix ++ sortedInjected ++ suffixPages

-- | Replace a dialogue's pages (base name and numbered pages) in the page order
-- with new ones, then sort in schema evolution order
updateSettingsPages :: String -> [String] -> KM.KeyMap Value -> KM.KeyMap Value
updateSettingsPages base newPages km =
  case KM.lookup "pages" km of
    Just (Object pObj) ->
      case KM.lookup "groups" pObj of
        Just (Array grps) ->
          let updatedGrps = V.imap updateGroup grps
              newPObj = KM.insert "groups" (Array updatedGrps) pObj
          in KM.insert "pages" (Object newPObj) km
        _ -> km
    _ -> km
  where
    updateGroup idx (Object gObj) =
      case KM.lookup "order" gObj of
        Just (Array ord) ->
          let listOrd = [ t | String t <- V.toList ord ]
              kept = filter (not . isOwnPage base . T.unpack) listOrd
              -- New pages go into the first group only
              withNew = if idx == 0 then kept ++ map T.pack newPages else kept
          in Object (KM.insert "order" (Array (V.fromList (map String (sortPagesByEvolution withNew)))) gObj)
        _ -> Object gObj
    updateGroup _ other = other

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

-- | Merge text resources: keys generated by the compiler get their new value,
-- other resources are kept as they are
mergeTextResources :: [(String, String)] -> KM.KeyMap Value -> KM.KeyMap Value
mergeTextResources newRes km =
  case KM.lookup "resources" km of
    Just (Array resArr) ->
      let newMap = [ (T.pack k, v) | (k, v) <- newRes ]
          updateEntry (Object o)
            | Just (String i) <- KM.lookup "id" o, Just v <- lookup i newMap = Object (KM.insert "value" (String (T.pack v)) o)
          updateEntry e = e
          existingList = map updateEntry (V.toList resArr)
          existingIds = [i | Object o <- existingList, Just (String i) <- [KM.lookup "id" o]]
          newEntries = [ object ["id" .= k, "value" .= v]
                       | (k, v) <- nubByKey newRes
                       , T.pack k `notElem` existingIds
                       ]
          allRes = existingList ++ newEntries
      in KM.insert "resources" (Array (V.fromList allRes)) km
    _ -> km
  where
    -- Last value wins for keys emitted twice
    nubByKey = foldr (\(k, v) acc -> if k `elem` map fst acc then acc else (k, v) : acc) [] . reverse

-- | Replace this dialogue's expression validations (keys under dataPrefix), keeping all others
mergeValidations :: T.Text -> [(String, [Value])] -> KM.KeyMap Value -> KM.KeyMap Value
mergeValidations dataPrefix newRules km =
  let existingRules = case KM.lookup "validations" km of
        Just (Object o) -> o
        _               -> KM.empty
      kept = KM.filterWithKey (\k _ -> not (dataPrefix `T.isPrefixOf` toText k)) existingRules
      added = KM.fromList [ (fromText (T.pack path), Array (V.fromList rules)) | (path, rules) <- newRules ]
  in KM.insert "$schema" (String "https://altinncdn.no/toolkits/altinn-app-frontend/4/schemas/json/validation/validation.schema.v1.json")
       (KM.insert "validations" (Object (KM.union added kept)) km)
