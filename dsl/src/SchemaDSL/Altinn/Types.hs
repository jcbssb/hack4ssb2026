module SchemaDSL.Altinn.Types
  ( AltinnArtifacts(..)
  , pageName
  , pageLayout
  , sanitizeName
  , capitalize
  ) where

import Data.Aeson (Value(..))
import Data.Char (toUpper)

-- | Set of compiled Altinn 3 artifacts
data AltinnArtifacts = AltinnArtifacts
  { pages         :: [(String, Value)]          -- (Page name e.g. "S05_Hack4SSB", layout for App/ui/mainlayout/layouts/<name>.json)
  , optionsLists  :: [(String, Value)]          -- (Filename e.g. "Hack4ssbSporValg.json", OptionsArray)
  , textResources :: [(String, String)]         -- [(ResourceID, TextValue)]
  , validations   :: [(String, [Value])]        -- (Data model path, expression validations) for App/models/<DataType>.validation.json
  } deriving (Show, Eq)

-- | Name of the first (or only) page
pageName :: AltinnArtifacts -> String
pageName a = case pages a of
  (p : _) -> fst p
  []      -> ""

-- | Layout of the first (or only) page
pageLayout :: AltinnArtifacts -> Value
pageLayout a = case pages a of
  (p : _) -> snd p
  []      -> Null

-- | Helper conversions
sanitizeName :: String -> String
sanitizeName = map (\c -> if c == '-' then '_' else c)

capitalize :: String -> String
capitalize [] = []
capitalize (c:cs) = toUpper c : cs
