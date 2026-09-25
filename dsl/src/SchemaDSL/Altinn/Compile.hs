{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module SchemaDSL.Altinn.Compile
  ( compileToAltinn
  , compileToAltinnPaged
  , compileSteps
  , compileStepItems
  , compilePredicateToHidden
  , compileExpr
  , compileConstraints
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
import Data.List (nub)
import SchemaDSL.Eval (constraintTargets, enteredInputs)
import SchemaDSL.Altinn.Types

-- | Compile generic Dialogue to one Altinn page using model binding helper strategy
compileToAltinn :: Dialogue -> AltinnArtifacts
compileToAltinn = compileWith False

-- | Compile a Dialogue to one Altinn page per bolk (consecutive standalone questions
-- share a page). Pages are named <base>_01, <base>_02, ... and a bolk condition hides
-- its whole page.
compileToAltinnPaged :: Dialogue -> AltinnArtifacts
compileToAltinnPaged = compileWith True

compileWith :: Bool -> Dialogue -> AltinnArtifacts
compileWith paged d@Dialogue{ dialogueId = did, title = dTitle, context = dCtx, calculations = dCalcs, steps = dSteps } =
  let dIdClean = sanitizeName did
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

      -- Navigation buttons at the end of each page
      navComp suffix = object
        [ "id"                   .= (dIdClean ++ "-nav-buttons" ++ suffix)
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

      layoutFile :: Maybe Value -> [Value] -> Value
      layoutFile hidden comps = object
        [ "$schema" .= ("https://altinncdn.no/toolkits/altinn-app-frontend/4/schemas/json/layout/layout.schema.v1.json" :: String)
        , "data"    .= object ([ "layout" .= map altinnComponentIds comps ] ++ [ "hidden" .= h | Just h <- [hidden] ])
        ]

      (validationRules, constraintTexts) = compileConstraints d

      baseTexts =
        [ ("lang." ++ dIdClean ++ ".tittel", dTitle)
        , ("lang." ++ dIdClean ++ ".panel.title", "Om registreringen")
        , ("lang." ++ dIdClean ++ ".panel.body", maybe "Dette skjemaet samler inn opplysninger." (maybe "" id . legalNotice) dCtx)
        ]

      -- Single page: everything on S05_<id>
      singlePage =
        let (stepComps, stepOpts, stepTexts) = compileStepItems dIdClean dCalcs dSteps
        in ( [ (pgName, layoutFile Nothing ([headerComp, panelComp] ++ stepComps ++ [navComp ""])) ]
           , stepOpts
           , (pgName, dTitle) : stepTexts )

      -- Paged: one page per bolk, loose questions grouped
      pageGroups = groupSteps dSteps
      pagedPages =
        [ let name = pgName ++ "_" ++ pad2 i
              (comps, opts, texts) = compileStepItems dIdClean dCalcs grp
              intro = if i == 1 then [headerComp, panelComp] else []
              hidden = case grp of
                [BolkStep b] -> fmap (compilePredicateToHidden dIdClean dCalcs) (bolkCondition b)
                _            -> Nothing
              pageTitle = case grp of
                [BolkStep b] -> bolkTitle b
                _            -> dTitle
          in ((name, layoutFile hidden (intro ++ comps ++ [navComp ("-p" ++ pad2 i)])), opts, (name, pageTitle) : texts)
        | (i, grp) <- zip [1 :: Int ..] pageGroups
        ]

      (pageList, allOpts, stepTextsAll) =
        if paged
          then (map (\(p, _, _) -> p) pagedPages, concatMap (\(_, o, _) -> o) pagedPages, concatMap (\(_, _, t) -> t) pagedPages)
          else singlePage

  in AltinnArtifacts
      { pages         = pageList
      , optionsLists  = allOpts
      , textResources = baseTexts ++ stepTextsAll ++ constraintTexts
      , validations   = validationRules
      }
  where
    pad2 n = if n < 10 then '0' : show n else show n

-- | Altinn component ids must match ^[0-9a-zA-Z][0-9a-zA-Z-]*...: replace underscores
-- in a component's id and in the component references of a Grid
altinnComponentIds :: Value -> Value
altinnComponentIds (Object o) =
  let fixId = adjustKey fixStr "id"
      fixRows = adjustKey (mapArray fixRow) "rows"
      fixRow (Object r) = Object (adjustKey (mapArray fixCell) "cells" r)
      fixRow v = v
      fixCell (Object c) = Object (adjustKey fixStr "component" c)
      fixCell v = v
      mapArray f (Array a) = Array (V.map f a)
      mapArray _ v = v
      fixStr (String t) = String (T.replace "_" "-" t)
      fixStr v = v
  in Object (fixRows (fixId o))
altinnComponentIds v = v

adjustKey :: (Value -> Value) -> KM.Key -> KM.KeyMap Value -> KM.KeyMap Value
adjustKey f k m = maybe m (\v -> KM.insert k (f v) m) (KM.lookup k m)

-- | Each bolk is its own group; consecutive standalone questions form one group
groupSteps :: [Step] -> [[Step]]
groupSteps = foldr add []
  where
    add s@(QuestionStep _) ((q@(QuestionStep _) : qs) : rest) = (s : q : qs) : rest
    add s acc = [s] : acc

-- | Convert DSL Predicate to Altinn Frontend v4 hidden rule expression
compilePredicateToHidden :: String -> [Calculation] -> Predicate -> Value
compilePredicateToHidden dIdClean calcs p =
  case p of
    Equals fid val ->
      expr [ String "notEquals", ref fid, str val ]
    NotEquals fid val ->
      expr [ String "equals", ref fid, str val ]
    IsTrue fid ->
      expr [ String "notEquals", ref fid, String "true" ]
    Compare l cmp r ->
      expr [ String "not", compileComparison dIdClean calcs cmp l r ]
    And preds ->
      expr (String "or" : map (compilePredicateToHidden dIdClean calcs) preds)
    Or preds ->
      expr (String "and" : map (compilePredicateToHidden dIdClean calcs) preds)
  where
    ref fid = expr [ String "dataModel", str (fieldPath dIdClean fid) ]

-- | Compile list of Questions to layout components, options, and text resources
compileSteps :: String -> [Calculation] -> [Question] -> ([Value], [(String, Value)], [(String, String)])
compileSteps dIdClean calcs qs =
  let go [] = ([], [], [])
      go (q : rest) =
        let fid = fieldId q
            compLabelKey = "lang." ++ dIdClean ++ "." ++ fid ++ ".label"
            compHelpKey  = "lang." ++ dIdClean ++ "." ++ fid ++ ".help"
            modelBinding = "SkjemaData." ++ dIdClean ++ "." ++ fid
            prefix = dIdClean ++ "-" ++ fid

            labelTxt = label (prompt q)
            helpTxt  = maybe "" id (helpText (prompt q))
            hasHelp  = case helpText (prompt q) of
              Just txt -> not (null txt)
              Nothing  -> False
            curTexts = [ (compLabelKey, labelTxt) ]
                       ++ [ (compHelpKey, helpTxt) | hasHelp ]

            trbBindings =
              [ "title" .= compLabelKey ]
              ++ [ "description" .= compHelpKey | hasHelp ]

            hiddenProp = case (condition (q :: Question)) of
              Just cond -> [ "hidden" .= compilePredicateToHidden dIdClean calcs cond ]
              Nothing   -> []

            -- Full width on phones (xs); the gridXs annotation applies from sm up,
            -- as in the SSB base app and research/ssb-altinn-skjemastandarder.md
            gridXsAnn = case annotations q of
              Just ann | Just (Number xsVal) <- KM.lookup "gridXs" ann -> Just (round xsVal :: Int)
              _ -> Nothing

            gridProp = case gridXsAnn of
              Just n  -> object [ "xs" .= (12 :: Int), "sm" .= n ]
              Nothing -> object [ "xs" .= (12 :: Int) ]

            -- Short number fields: full row, narrower input box from md up (SSB base app convention)
            numberGrid = case gridXsAnn of
              Just n  -> object [ "xs" .= (12 :: Int), "sm" .= n ]
              Nothing -> object [ "xs" .= (12 :: Int), "innerGrid" .= object [ "md" .= (4 :: Int) ] ]

            readOnlyProp = case annotations q of
              Just ann | Just (Bool True) <- KM.lookup "readOnly" ann -> [ "readOnly" .= True ]
              _ -> []

            decimalScaleVal = case annotations q of
              Just ann | Just (Number n) <- KM.lookup "decimalScale" ann -> round n :: Int
              _ -> 1 :: Int

            (comp, opts) = case lookup fid [ (calcTarget c, calcExpr c) | c <- calcs ] of
              -- Calculated fields are display-only and derived in the frontend
              Just calcE | questionType q `elem` [QInteger, QDecimal] ->
                let scale = if questionType q == QInteger then 0 else decimalScaleVal
                    c = object $
                      [ "id"                   .= (prefix ++ "-number")
                      , "type"                 .= ("Number" :: String)
                      , "value"                .= compileExpr dIdClean calcs calcE
                      , "formatting"           .= object [ "number" .= object [ "decimalScale" .= scale ] ]
                      , "textResourceBindings" .= object trbBindings
                      , "grid"                 .= numberGrid
                      ] ++ hiddenProp
                in (c, [])
              _ -> compileInput

            compileInput = case questionType q of
              QText ->
                let c = object $
                      [ "id"                   .= (prefix ++ "-input")
                      , "type"                 .= ("Input" :: String)
                      , "textResourceBindings" .= object trbBindings
                      , "dataModelBindings"    .= object [ "simpleBinding" .= modelBinding ]
                      , "required"             .= required q
                      , "grid"                 .= gridProp
                      , "labelSettings"        .= object [ "optionalIndicator" .= False ]
                      ] ++ hiddenProp ++ readOnlyProp
                in (c, [])

              QTextArea ->
                let c = object $
                      [ "id"                   .= (prefix ++ "-textarea")
                      , "type"                 .= ("TextArea" :: String)
                      , "textResourceBindings" .= object trbBindings
                      , "dataModelBindings"    .= object [ "simpleBinding" .= modelBinding ]
                      , "required"             .= required q
                      , "grid"                 .= gridProp
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
                      , "textResourceBindings" .= object trbBindings
                      , "dataModelBindings"    .= object [ "simpleBinding" .= modelBinding ]
                      , "required"             .= required q
                      , "grid"                 .= numberGrid
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
                      , "textResourceBindings" .= object trbBindings
                      , "dataModelBindings"    .= object [ "simpleBinding" .= modelBinding ]
                      , "required"             .= required q
                      , "grid"                 .= numberGrid
                      , "labelSettings"        .= object [ "optionalIndicator" .= False ]
                      ] ++ hiddenProp ++ readOnlyProp
                in (c, [])

              QDate ->
                let c = object $
                      [ "id"                   .= (prefix ++ "-datepicker")
                      , "type"                 .= ("Datepicker" :: String)
                      , "timeStamp"            .= False
                      , "textResourceBindings" .= object trbBindings
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
                      , "textResourceBindings" .= object trbBindings
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
                      , "textResourceBindings" .= object trbBindings
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
                      , "textResourceBindings" .= object trbBindings
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

-- | Compile list of Steps (either Questions or Bolker) to layout components, options, and text resources
compileStepItems :: String -> [Calculation] -> [Step] -> ([Value], [(String, Value)], [(String, String)])
compileStepItems dIdClean calcs stepList = goItems stepList
  where
    goItems [] = ([], [], [])
    goItems (x:xs) =
      let (c1, o1, t1) = processItem x
          (c2, o2, t2) = goItems xs
      in (c1 ++ c2, o1 ++ o2, t1 ++ t2)

    processItem (QuestionStep q) =
      compileSteps dIdClean calcs [q]

    processItem (BolkStep b) =
      let bIdClean = sanitizeName (bolkId b)
          bHeaderId = dIdClean ++ "-bolk-" ++ bIdClean ++ "-header"
          bDescId   = dIdClean ++ "-bolk-" ++ bIdClean ++ "-desc"

          bTitleKey = "lang." ++ dIdClean ++ ".bolk." ++ bIdClean ++ ".title"
          bDescKey  = "lang." ++ dIdClean ++ ".bolk." ++ bIdClean ++ ".desc"

          bHiddenProp = case bolkCondition b of
            Just cond -> [ "hidden" .= compilePredicateToHidden dIdClean calcs cond ]
            Nothing   -> []

          bHeaderComp = object $
            [ "id"                   .= (bHeaderId :: String)
            , "type"                 .= ("Header" :: String)
            , "size"                 .= ("h3" :: String)
            , "textResourceBindings" .= object [ "title" .= bTitleKey ]
            , "grid"                 .= object [ "xs" .= (12 :: Int) ]
            ] ++ bHiddenProp

          (bDescCompList, bDescTexts) = case bolkDescription b of
            Just descTxt ->
              let comp = object $
                    [ "id"                   .= (bDescId :: String)
                    , "type"                 .= ("Paragraph" :: String)
                    , "textResourceBindings" .= object [ "title" .= bDescKey ]
                    , "grid"                 .= object [ "xs" .= (12 :: Int) ]
                    ] ++ bHiddenProp
              in ([comp], [(bDescKey, descTxt)])
            Nothing -> ([], [])

          bBaseTexts = (bTitleKey, bolkTitle b) : bDescTexts
          (qComps, qOpts, qTexts) = compileQuestionsWithMatrices dIdClean calcs (bolkQuestions b)
      in ([bHeaderComp] ++ bDescCompList ++ qComps, qOpts, bBaseTexts ++ qTexts)

-- | Compile questions, rendering consecutive cells of the same matrix (questions with a
-- "matrix" annotation) as a Grid table that places the cell components
compileQuestionsWithMatrices :: String -> [Calculation] -> [Question] -> ([Value], [(String, Value)], [(String, String)])
compileQuestionsWithMatrices dIdClean calcs = go
  where
    go [] = ([], [], [])
    go qs@(q : _) = case matrixInfo q of
      Just (mid, _, _, _, _) ->
        let (cells, rest) = span (\x -> fmap (\(m, _, _, _, _) -> m) (matrixInfo x) == Just mid) qs
            (gridComp, gridTexts) = matrixGrid mid cells
            (cComps, cOpts, cTexts) = compileSteps dIdClean calcs cells
            (rComps, rOpts, rTexts) = go rest
        in (gridComp : map withoutGrid cComps ++ rComps, cOpts ++ rOpts, gridTexts ++ cTexts ++ rTexts)
      Nothing ->
        let (plain, rest) = break (\x -> matrixInfo x /= Nothing) qs
            (pComps, pOpts, pTexts) = compileSteps dIdClean calcs plain
            (rComps, rOpts, rTexts) = go rest
        in (pComps ++ rComps, pOpts ++ rOpts, pTexts ++ rTexts)

    calculated = map calcTarget calcs

    matrixGrid mid cells =
      let infos = [ (r, c, rl, cl, q) | q <- cells, Just (_, r, c, rl, cl) <- [matrixInfo q] ]
          rows = nubBy' [ (r, rl) | (r, _, rl, _, _) <- infos ]
          cols = nubBy' [ (c, cl) | (_, c, _, cl, _) <- infos ]
          key kind k = "lang." ++ dIdClean ++ ".matrix." ++ mid ++ "." ++ kind ++ "." ++ k
          compId q = dIdClean ++ "-" ++ fieldId q ++ (if fieldId q `elem` calculated then "-number" else "-input")
          cellFor r c = case [ q | (r', c', _, _, q) <- infos, r' == r, c' == c ] of
            (q : _) -> object [ "component" .= compId q ]
            []      -> Null
          -- The row label column gets a fixed share; number columns split the rest.
          -- Labels may wrap instead of being cut off after 2 lines (the default).
          labelWidth = if length cols >= 5 then "25%" else if length cols >= 3 then "30%" else "40%" :: String
          wrap = object [ "lineWrap" .= True, "maxHeight" .= (10 :: Int) ]
          header = object
            [ "header" .= True
            , "cells"  .= ( object [ "text" .= ("" :: String), "width" .= labelWidth ]
                          : [ object [ "text" .= key "col" c, "alignText" .= ("right" :: String), "textOverflow" .= wrap ] | (c, _) <- cols ] )
            ]
          body (r, _) = object
            [ "cells" .= (object [ "text" .= key "row" r, "textOverflow" .= wrap ] : [ cellFor r c | (c, _) <- cols ]) ]
          grid = object
            [ "id"   .= (dIdClean ++ "-matrix-" ++ mid)
            , "type" .= ("Grid" :: String)
            , "rows" .= (header : map body rows)
            ]
      in (grid, [ (key "col" c, l) | (c, l) <- cols ] ++ [ (key "row" r, l) | (r, l) <- rows ])

    -- Keys in order of first appearance
    nubBy' = foldl (\acc x -> if fst x `elem` map fst acc then acc else acc ++ [x]) []

-- | Components placed in a Grid table take the width of their table cell
withoutGrid :: Value -> Value
withoutGrid (Object o) = Object (KM.delete "grid" o)
withoutGrid v = v

-- | (matrix id, row key, column key, row label, column label) from a question's "matrix" annotation
matrixInfo :: Question -> Maybe (String, String, String, String, String)
matrixInfo q = do
  anns <- annotations q
  Object m <- KM.lookup "matrix" anns
  String mid <- KM.lookup "id" m
  String r <- KM.lookup "row" m
  String c <- KM.lookup "col" m
  let label k fallback = case KM.lookup k m of
        Just (String t) -> T.unpack t
        _               -> fallback
  pure (T.unpack mid, T.unpack r, T.unpack c, label "rowLabel" (T.unpack r), label "colLabel" (T.unpack c))

-- | Data model path for a field in this dialogue
fieldPath :: String -> FieldId -> String
fieldPath dIdClean fid = "SkjemaData." ++ dIdClean ++ "." ++ fid

-- | Compile a DSL expression to an Altinn number expression. Calculated fields are
-- inlined (they are not stored), and empty fields count as 0 as in SchemaDSL.Eval.
compileExpr :: String -> [Calculation] -> Expr -> Value
compileExpr dIdClean calcs e = case e of
  Field fid -> case lookup fid [ (calcTarget c, calcExpr c) | c <- calcs ] of
    Just inner -> compileExpr dIdClean (filter ((/= fid) . calcTarget) calcs) inner
    Nothing ->
      let ref = expr [ String "dataModel", str (fieldPath dIdClean fid) ]
      in expr [ String "if", expr [ String "equals", ref, Null ], Number 0, String "else", ref ]
  Const n  -> Number (realToFrac n)
  Add []   -> Number 0
  Add [x]  -> go x
  Add xs   -> expr (String "plus" : map go xs)
  Sub a b  -> expr [ String "minus", go a, go b ]
  Mul []   -> Number 1
  Mul [x]  -> go x
  Mul xs   -> expr (String "multiply" : map go xs)
  Div a b  -> expr [ String "divide", go a, go b ]
  where
    go = compileExpr dIdClean calcs

-- | Compile constraints to expression validations keyed by data model path,
-- plus the text resources for their messages. A validation's condition is true
-- when the constraint is violated.
compileConstraints :: Dialogue -> ([(String, [Value])], [(String, String)])
compileConstraints d =
  let dIdClean = sanitizeName (dialogueId d)
      calcs = calculations d
      relation c = compileComparison dIdClean calcs (comparison c) (constraintLeft c) (constraintRight c)
      violated c = case constraintCondition c of
        Just p  -> expr [ String "and", compilePredicate dIdClean calcs p, expr [ String "not", relation c ] ]
        Nothing -> expr [ String "not", relation c ]
      msgKey c = "lang." ++ dIdClean ++ ".constraint." ++ constraintId c
      validation c = object
        [ "message"   .= msgKey c
        , "severity"  .= (case severity c of SevError -> "error"; SevWarning -> "warning" :: String)
        , "condition" .= violated c
        ]
      -- Calculated fields are unbound Number components, so their messages go to their inputs
      perField = [ (fieldPath dIdClean fid, validation c)
                 | c <- constraints d
                 , fid <- nub (concatMap (enteredInputs d) (constraintTargets d c))
                 ]
      paths = foldr (\(p, _) acc -> if p `elem` acc then acc else p : acc) [] perField
  in ( [ (p, [ v | (p', v) <- perField, p' == p ]) | p <- paths ]
     , [ (msgKey c, message c) | c <- constraints d ]
     )

-- | Positive (non-negated) predicate expression, used as a constraint guard
compilePredicate :: String -> [Calculation] -> Predicate -> Value
compilePredicate dIdClean calcs p = case p of
  Equals fid v    -> expr [ String "equals", ref fid, str v ]
  NotEquals fid v -> expr [ String "notEquals", ref fid, str v ]
  IsTrue fid      -> expr [ String "equals", ref fid, String "true" ]
  Compare l cmp r -> compileComparison dIdClean calcs cmp l r
  And ps          -> expr (String "and" : map (compilePredicate dIdClean calcs) ps)
  Or ps           -> expr (String "or" : map (compilePredicate dIdClean calcs) ps)
  where
    ref fid = expr [ String "dataModel", str (fieldPath dIdClean fid) ]

-- | Numeric comparison; both sides are rounded to 6 decimals to match the
-- tolerance in SchemaDSL.Eval.compareValues
compileComparison :: String -> [Calculation] -> Comparison -> Expr -> Expr -> Value
compileComparison dIdClean calcs cmp l r =
  let op = case cmp of
        CmpEq    -> "equals"
        CmpNotEq -> "notEquals"
        CmpLt    -> "lessThan"
        CmpLte   -> "lessThanEq"
        CmpGt    -> "greaterThan"
        CmpGte   -> "greaterThanEq"
      rounded x = expr [ String "round", compileExpr dIdClean calcs x, Number 6 ]
  in expr [ String op, rounded l, rounded r ]

expr :: [Value] -> Value
expr = Array . V.fromList

str :: String -> Value
str = String . T.pack
