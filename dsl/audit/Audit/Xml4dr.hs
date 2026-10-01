{-# LANGUAGE OverloadedStrings #-}
-- | Reads an XML4DR form definition into a flat, queryable fact model.
module Audit.Xml4dr
  ( Form(..), Section(..), Cell(..), Handler(..), Effect(..), Action(..)
  , loadForm, cellKey, handlerRefs
  ) where

import qualified Data.Map.Strict as M
import Data.Maybe (fromMaybe, mapMaybe, listToMaybe)
import Data.Text (Text)
import qualified Data.Text as T
import Text.XML

data Form = Form
  { formId     :: Text
  , formTitle  :: Text
  , sections   :: [Section]
  , cells      :: [Cell]
  , handlers   :: M.Map Text Handler
  } deriving Show

data Section = Section
  { secId :: Text, secPath :: [Text], secTitle :: [Text], secRows :: Int, secDomains :: [Text]
  } deriving Show

data Cell = Cell
  { cSet :: Text, cSetPath :: [Text], cTuple :: Text, cData :: Text
  , cRow :: Int, cCol :: Int, cRowText :: [Text]
  , cText :: [Text], cNn :: [Text], cValue :: Maybe Text
  , cFormat :: Maybe Text, cControl :: Maybe Text, cSize :: Maybe Text
  , cStyles :: [Text], cHandlers :: [Text]
  } deriving Show

data Handler = Handler
  { hId :: Text, hType :: Maybe Text, hEval :: Text, hActions :: [Action] } deriving Show

data Action = Action { aWhen :: Text, aEffects :: [Effect] } deriving Show

data Effect
  = SetState Text [(Text, Text)]
  | MsgBox [Text]
  | SetError Text
  deriving Show

cellKey :: Cell -> Text
cellKey c = cSet c <> "/" <> cData c

kids :: Element -> [Element]
kids e = [k | NodeElement k <- elementNodes e]

named :: Text -> Element -> [Element]
named n = filter ((== n) . nameLocalName . elementName) . kids

attr :: Text -> Element -> Maybe Text
attr k = M.lookup (Name k Nothing Nothing) . elementAttributes

attrD :: Text -> Element -> Text
attrD k = fromMaybe "" . attr k

content :: Element -> Text
content e = T.concat [t | NodeContent t <- elementNodes e]

descendants :: Text -> Element -> [Element]
descendants n e = concat [ [k | nameLocalName (elementName k) == n] ++ descendants n k | k <- kids e ]

-- | Cell references used by an Eval expression: GetFieldValue("Set","Data") and FieldFilled("Set","Data").
handlerRefs :: Text -> [(Text, Text)]
handlerRefs = go
  where
    go t = case T.breakOn "(\"" t of
      (_, r) | T.null r -> []
      (_, r) ->
        let r1 = T.drop 2 r
            (a, r2) = T.breakOn "\"" r1
        in case T.stripPrefix "\", \"" r2 of
             Just r3 -> let (b, r4) = T.breakOn "\"" r3 in (a, b) : go r4
             Nothing -> go r2

stripHtml :: Text -> Text
stripHtml = T.unwords . T.words . go . T.replace "<br>" " " . T.replace "&nbsp;" " "
  where
    go t = case T.breakOn "<" t of
      (a, r) | T.null r -> a
             | otherwise -> a <> go (T.drop 1 (T.dropWhile (/= '>') r))

loadForm :: FilePath -> IO Form
loadForm path = do
  doc <- readFile' path
  let root = documentRoot doc
      texts = M.fromList
        [ (attrD "textId" t, M.fromList [(attrD "language" s, T.strip (content s)) | s <- named "TextString" t])
        | t <- descendants "Text" root ]
      txt lang ref = fromMaybe "" (M.lookup ref texts >>= M.lookup lang)
      ptrs lang e = [ s | p <- named "TextPointer" e, let s = stripHtml (txt lang (attrD "textRef" p)), not (T.null s) ]
      styles = M.fromList
        [ (attrD "styleId" s, attrD "property" s <> ":" <> T.strip (content s)) | s <- descendants "Style" root ]
      groups = M.fromList
        [ (attrD "styleGroupId" g, mapMaybe (\p -> M.lookup (attrD "styleRef" p) styles) (named "StylePointer" g))
        | g <- descendants "StyleGroup" root ]
      ctrls = M.fromList [ (attrD "inputControlId" c, c) | c <- descendants "InputControl" root ]
      fmts = M.fromList [ (attrD "formatId" f, f) | f <- descendants "Format" root ]
      hdl = M.fromList
        [ (hId h, h) | e <- descendants "Handler" root
        , let h = Handler
                { hId = attrD "handlerId" e, hType = attr "handlerType" e
                , hEval = maybe "" (T.strip . content) (listToMaybe (named "Eval" e))
                , hActions = [ Action (attrD "when" a) (concatMap effect (kids a)) | a <- named "Action" e ] } ]
      effect k = case nameLocalName (elementName k) of
        "SetState" -> [SetState (attrD "state" k) [ (attrD "setRef" p, attrD "dataRef" p) | p <- named "Pointer" k ]]
        "MsgBox"   -> [MsgBox (ptrs "nb" k)]
        "SetError" -> [SetError (attrD "error" k)]
        _ -> []
      handlersOf fmt = case fmt >>= \f -> listToMaybe [ c | r <- descendants "Rendering" f
                                                          , Just c <- [attr "inputControlRef" r >>= (`M.lookup` ctrls)] ] of
        Nothing -> (Nothing, [])
        Just c  -> (attr "inputControlType" c, [ attrD "handlerRef" p | ce <- descendants "CatchEvent" c, p <- named "HandlerPointer" ce ])
      walk parent s = (sec : concat subs, concat subCells ++ ownCells)
        where
          sid = attrD "setId" s
          path' = parent ++ [sid]
          domains = map (attrD "domainId") (named "Domain" s)
          tuples = named "Tuple" s
          sec = Section sid path' (ptrs "nb" s) (length tuples) domains
          ownCells =
            [ Cell { cSet = sid, cSetPath = path', cTuple = attrD "tupleId" tp, cData = attrD "dataId" d
                   , cRow = ri, cCol = ci, cRowText = ptrs "nb" tp
                   , cText = ptrs "nb" d, cNn = ptrs "nn" d
                   , cValue = fmap (T.strip . content) (listToMaybe (named "Value" d))
                   , cFormat = attr "formatRef" d
                   , cControl = ctl, cSize = fmap (T.strip . content) (fmt >>= listToMaybe . named "Size")
                   , cStyles = concat [ fromMaybe [] (M.lookup (attrD "styleGroupRef" g) groups) | g <- named "StyleGroupPointer" d ]
                   , cHandlers = hs }
            | (ri, tp) <- zip [1 ..] tuples, (ci, d) <- zip [1 ..] (named "Data" tp)
            , let fmt = attr "formatRef" d >>= (`M.lookup` fmts)
            , let (ctl, hs) = handlersOf fmt ]
          (subs, subCells) = unzip [ walk path' k | k <- named "Set" s ]
      instances = concatMap (named "Set") (named "Instance" root)
      (secs, cs) = unzip (map (walk []) instances)
      title = fromMaybe "" (listToMaybe [ txt "nb" (attrD "textRef" p) | p <- named "TextPointer" root ])
  pure Form { formId = attrD "formId" root, formTitle = title
            , sections = concat secs, cells = concat cs, handlers = hdl }
  where readFile' = Text.XML.readFile def
