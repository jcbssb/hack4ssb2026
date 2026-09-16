module SchemaDSL.JSON
  ( encodeDialogue
  , decodeDialogue
  , encodeDialoguePretty
  ) where

import qualified Data.ByteString.Lazy as BL
import Data.Aeson
  ( encode
  , eitherDecode
  )
import SchemaDSL.Types

-- | Encode dialogue to Lazy ByteString
encodeDialogue :: Dialogue -> BL.ByteString
encodeDialogue = encode

-- | Decode dialogue from Lazy ByteString
decodeDialogue :: BL.ByteString -> Either String Dialogue
decodeDialogue = eitherDecode

-- | Simple pretty print without requiring aeson-pretty
encodeDialoguePretty :: Dialogue -> BL.ByteString
encodeDialoguePretty = encodeDialogue
