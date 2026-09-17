{-# LANGUAGE OverloadedStrings #-}

module SchemaDSL.Altinn.DataModel
  ( updateJsonSchemaModel
  , updateCSharpModel
  ) where

import qualified Data.ByteString.Lazy as BL
import Data.Aeson
  ( Value(..)
  , object
  , (.=)
  , decode
  )
import Data.Aeson.Encode.Pretty (encodePretty)
import Data.Aeson.Key (fromText)
import qualified Data.Aeson.KeyMap as KM
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import System.Directory (doesFileExist)
import System.FilePath ((</>))
import SchemaDSL.Types
import SchemaDSL.Altinn.Types (sanitizeName, capitalize)

-- | Update JSON Schema model to define SkjemaData.<dIdClean>.<fieldId>
updateJsonSchemaModel :: FilePath -> Dialogue -> IO ()
updateJsonSchemaModel modelsDir d = do
  let schemaPath = modelsDir </> "A3_RA-1000_M.schema.json"
  exists <- doesFileExist schemaPath
  if not exists
    then putStrLn $ "  [!] Warning: Data model JSON schema not found at " ++ schemaPath
    else do
      content <- BL.readFile schemaPath
      case decode content of
        Just (Object rootObj) -> do
          let dIdClean = sanitizeName (dialogueId d)
              allQs = allDialogueQuestions d
              fieldProps = [ (fromText (T.pack (fieldId q)), qTypeToJsonSchema (questionType q))
                           | q <- allQs
                           ]
              dialogueObj = object
                [ "type" .= ("object" :: String)
                , "properties" .= object [ k .= v | (k, v) <- fieldProps ]
                ]
              updated = updateSkjemaDataJson (T.pack dIdClean) dialogueObj rootObj
          BL.writeFile schemaPath (encodePretty (Object updated))
          putStrLn $ "  [+] Updated JSON schema data model for " ++ dIdClean ++ " in: " ++ schemaPath
        _ -> putStrLn $ "  [!] Warning: Failed to parse JSON schema at " ++ schemaPath

updateSkjemaDataJson :: T.Text -> Value -> KM.KeyMap Value -> KM.KeyMap Value
updateSkjemaDataJson dKey dVal rootKm =
  case KM.lookup "properties" rootKm of
    Just (Object props) ->
      let dKeyK = fromText dKey
          skjemaDataObj = case KM.lookup "SkjemaData" props of
            Just (Object sd) ->
              let existingInnerProps = case KM.lookup "properties" sd of
                    Just (Object ip) -> ip
                    _ -> KM.empty
                  newInnerProps = KM.insert dKeyK dVal existingInnerProps
              in KM.insert "properties" (Object newInnerProps) sd
            _ -> KM.fromList
              [ ("type", "object")
              , ("properties", object [ dKeyK .= dVal ])
              ]
          newProps = KM.insert "SkjemaData" (Object skjemaDataObj) props
      in KM.insert "properties" (Object newProps) rootKm
    _ -> rootKm

qTypeToJsonSchema :: QuestionType -> Value
qTypeToJsonSchema qt = case qt of
  QText          -> object [ "type" .= ("string" :: String) ]
  QTextArea      -> object [ "type" .= ("string" :: String) ]
  QInteger       -> object [ "type" .= ("integer" :: String) ]
  QDecimal       -> object [ "type" .= ("number" :: String) ]
  QDate          -> object [ "type" .= ("string" :: String), "format" .= ("date" :: String) ]
  QBoolean       -> object [ "type" .= ("boolean" :: String) ]
  QChoice _      -> object [ "type" .= ("string" :: String) ]
  QMultiChoice _ -> object [ "type" .= ("string" :: String) ]

-- | Update C# model to add matching classes for SkjemaData
updateCSharpModel :: FilePath -> Dialogue -> IO ()
updateCSharpModel modelsDir d = do
  let csPath = modelsDir </> "A3_RA-1000_M.cs"
  exists <- doesFileExist csPath
  if not exists
    then putStrLn $ "  [!] Warning: C# model file not found at " ++ csPath
    else do
      txt <- TIO.readFile csPath
      let content = T.unpack txt
          dIdClean = sanitizeName (dialogueId d)
          className = capitalize dIdClean
          propName = dIdClean
      if ("public " ++ className ++ " " ++ propName) `isInfixOfStr` content
        then putStrLn $ "  [=] C# model already has " ++ className ++ " definition."
        else do
          let updated = injectCSharpClass dIdClean className (allDialogueQuestions d) content
          TIO.writeFile csPath (T.pack updated)
          putStrLn $ "  [+] Updated C# data model with class " ++ className ++ " in: " ++ csPath

isInfixOfStr :: String -> String -> Bool
isInfixOfStr needle haystack = any (needle `isPrefixOfStr`) (tailsStr haystack)
  where
    isPrefixOfStr [] _ = True
    isPrefixOfStr _ [] = False
    isPrefixOfStr (x:xs) (y:ys) = x == y && isPrefixOfStr xs ys

    tailsStr [] = [[]]
    tailsStr xxs@(_:xs) = xxs : tailsStr xs

injectCSharpClass :: String -> String -> [Question] -> String -> String
injectCSharpClass dIdClean className qs content =
  let propertyInSkjemaData =
        "    [XmlElement(\"" ++ dIdClean ++ "\")]\n" ++
        "    [JsonProperty(\"" ++ dIdClean ++ "\")]\n" ++
        "    [JsonPropertyName(\"" ++ dIdClean ++ "\")]\n" ++
        "    public " ++ className ++ " " ++ dIdClean ++ " { get; set; }\n\n"

      fieldDef (q, idx) =
        let fid = fieldId q
            csType = qTypeToCSharp (questionType q)
        in "    [XmlElement(\"" ++ fid ++ "\", Order = " ++ show (idx :: Int) ++ ")]\n" ++
           "    [JsonProperty(\"" ++ fid ++ "\")]\n" ++
           "    [JsonPropertyName(\"" ++ fid ++ "\")]\n" ++
           "    public " ++ csType ++ " " ++ fid ++ " { get; set; }\n\n"

      classDef =
        "  public class " ++ className ++ "\n" ++
        "  {\n" ++
        concatMap fieldDef (zip qs [1..]) ++
        "  }\n"

      -- Inject property into SkjemaData class, and append new class at end of namespace
      marker = "public class SkjemaData\n  {"
      contentWithProp = case breakOn marker content of
        (before, after) | not (null after) ->
          before ++ marker ++ "\n" ++ propertyInSkjemaData ++ drop (length marker) after
        _ -> content

      -- Append class definition before the file's closing brace of namespace Altinn.App.Models
      contentWithClass = case breakOnLastClosingBrace contentWithProp of
        Just (beforeBrace, afterBrace) ->
          beforeBrace ++ "\n" ++ classDef ++ afterBrace
        Nothing ->
          contentWithProp ++ "\n" ++ classDef

  in contentWithClass

breakOnLastClosingBrace :: String -> Maybe (String, String)
breakOnLastClosingBrace str =
  let trimmedRev = dropWhile (\c -> c == '\n' || c == '\r' || c == ' ') (reverse str)
  in case trimmedRev of
       ('}' : rest) -> Just (reverse (dropWhile (\c -> c == '\n' || c == '\r' || c == ' ') rest), "\n}\n")
       _            -> Nothing

breakOn :: String -> String -> (String, String)
breakOn needle haystack = go [] haystack
  where
    go acc [] = (reverse acc, [])
    go acc remStr@(c:cs)
      | needle `isInfixOfStr` take (length needle) remStr = (reverse acc, remStr)
      | otherwise = go (c:acc) cs

qTypeToCSharp :: QuestionType -> String
qTypeToCSharp qt = case qt of
  QText          -> "string"
  QTextArea      -> "string"
  QInteger       -> "int?"
  QDecimal       -> "decimal?"
  QDate          -> "string"
  QBoolean       -> "bool?"
  QChoice _      -> "string"
  QMultiChoice _ -> "string"
