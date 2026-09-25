module SchemaDSL.Altinn.Types
  ( AltinnArtifacts(..)
  , sanitizeName
  , capitalize
  ) where

import Data.Aeson (Value)
import Data.Char (toUpper)

-- | Set of compiled Altinn 3 artifacts
data AltinnArtifacts = AltinnArtifacts
  { pageName      :: String                     -- e.g. "S05_Hack4SSB"
  , pageLayout    :: Value                      -- Content for App/ui/mainlayout/layouts/S05_Hack4SSB.json
  , optionsLists  :: [(String, Value)]          -- (Filename e.g. "Hack4ssbSporValg.json", OptionsArray)
  , textResources :: [(String, String)]         -- [(ResourceID, TextValue)]
  , validations   :: [(String, [Value])]        -- (Data model path, expression validations) for App/models/<DataType>.validation.json
  } deriving (Show, Eq)

-- | Helper conversions
sanitizeName :: String -> String
sanitizeName = map (\c -> if c == '-' then '_' else c)

capitalize :: String -> String
capitalize [] = []
capitalize (c:cs) = toUpper c : cs
