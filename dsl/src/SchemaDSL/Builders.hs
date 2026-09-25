{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}

-- | Haskell-side building blocks for authoring large forms. They expand to plain
-- questions, calculations and constraints, so the JSON format is unchanged.
--
-- A 'Matrix' is a table of numeric cells (rows × columns), as in paper and
-- PDF statistics forms. Each cell becomes one question with field id
-- @<prefix>_<rowKey>_<colKey>@. Formulas refer to cells by key:
--
-- > MatrixCol "c" "Ikke i samsvar med plan" (Just (\cell -> Sub (cell "a") (cell "b")))
--
-- A column formula computes a cell from other cells in the same row, a row
-- formula from other cells in the same column, and a cell formula gives one cell
-- any expression (e.g. copied from another matrix). Precedence: cell, column, row.
-- Column formulas skip rows that are not summable and row formulas skip columns
-- that are not summable (e.g. averages); those cells stay entered, as do cells
-- whose column or row formula refers to cells missing from the matrix. The result is a triple of lists, so several parts combine with
-- 'mconcat'.
module SchemaDSL.Builders
  ( Matrix(..)
  , MatrixRow(..)
  , MatrixCol(..)
  , MatrixRule(..)
  , RuleScope(..)
  , FormParts
  , matrix
  , matrixRow
  , matrixCol
  , matrixCells
  , cellId
  , sumOfKeys
  , weightedAverage
  , partsAtMost
  , atLeastZero
  , questionsOnly
  ) where

import Data.Aeson (Value(..), object, (.=))
import qualified Data.Aeson.KeyMap as KM
import SchemaDSL.Types

-- | Questions plus the rules that belong to them; combine with 'mconcat'
type FormParts = ([Question], [Calculation], [Constraint])

data Matrix = Matrix
  { matrixPrefix :: String        -- ^ field id prefix, e.g. "t4_c12"
  , matrixRows   :: [MatrixRow]
  , matrixCols   :: [MatrixCol]
  , matrixRules  :: [MatrixRule]
  , matrixCellFormulas :: [((String, String), Expr)]  -- ^ ((row key, column key), formula)
  }

data MatrixRow = MatrixRow
  { rowKey       :: String
  , rowLabel     :: String
  , rowCols      :: Maybe [String]                        -- ^ columns present in this row; Nothing = all
  , rowType      :: QuestionType                          -- ^ QInteger or QDecimal
  , rowFormula   :: Maybe ((String -> Expr) -> Expr)      -- ^ cell from other rows' cells, by row key
  , rowCondition :: Maybe ((String -> String -> Expr) -> String -> Predicate)
                                                          -- ^ when a cell is shown, given a (row key, column key)
                                                          --   cell reference and the cell's column key
  , rowSummable  :: Bool                                  -- ^ whether column formulas apply (False for averages)
  , rowRequired  :: [String]                              -- ^ columns that must be answered in this row
  }

data MatrixCol = MatrixCol
  { colKey     :: String
  , colLabel   :: String
  , colFormula :: Maybe ((String -> Expr) -> Expr)        -- ^ cell from other columns' cells, by column key
  , colSummable :: Bool                                   -- ^ whether row formulas apply (False for averages)
  , colPrefilled :: Bool                                  -- ^ filled in beforehand by the data owner, shown read-only
  }

-- | Whether a rule is instantiated once per row (cells referred to by column key)
-- or once per column (cells referred to by row key)
data RuleScope = EachRow | EachColumn

-- | A constraint repeated over rows or columns. It is only generated where all
-- the cells it refers to exist.
data MatrixRule = MatrixRule
  { ruleId         :: String
  , ruleScope      :: RuleScope
  , ruleLeft       :: (String -> Expr) -> Expr
  , ruleComparison :: Comparison
  , ruleRight      :: (String -> Expr) -> Expr
  , ruleSeverity   :: Severity
  , ruleMessage    :: String
  }

-- | Entered integer row present in all columns
matrixRow :: String -> String -> MatrixRow
matrixRow key lbl = MatrixRow key lbl Nothing QInteger Nothing Nothing True []

-- | (row key, column key) of every cell present in a matrix
matrixCells :: Matrix -> [(String, String)]
matrixCells m =
  [ (rowKey r, colKey c)
  | r <- matrixRows m
  , c <- matrixCols m
  , maybe True (colKey c `elem`) (rowCols r)
  ]

-- | Entered column
matrixCol :: String -> String -> MatrixCol
matrixCol key lbl = MatrixCol key lbl Nothing True False

-- | Field id of a cell
cellId :: String -> String -> String -> FieldId
cellId prefix row col = prefix ++ "_" ++ safeKey row ++ "_" ++ safeKey col

-- | Row and column keys like "2.1" become "2_1" in field and constraint ids
safeKey :: String -> String
safeKey = map (\c -> if c `elem` (".- " :: String) then '_' else c)

-- | Sum of cells by key, for use in formulas and rules
sumOfKeys :: [String] -> (String -> Expr) -> Expr
sumOfKeys keys cell = Add (map cell keys)

-- | Weighted average of (value, weight) pairs, e.g. average processing times weighted
-- by the number of cases. Has no value when the weights sum to 0.
weightedAverage :: [(Expr, Expr)] -> Expr
weightedAverage pairs = Div (Add [ Mul [v, w] | (v, w) <- pairs ]) (Add (map snd pairs))

-- | "Herav" rule: the parts together do not exceed the total
partsAtMost :: String -> RuleScope -> [String] -> String -> String -> MatrixRule
partsAtMost rid scope parts total msg =
  MatrixRule rid scope (sumOfKeys parts) CmpLte ($ total) SevError msg

-- | A (typically calculated remainder) cell must not be negative
atLeastZero :: String -> RuleScope -> String -> String -> MatrixRule
atLeastZero rid scope key msg =
  MatrixRule rid scope ($ key) CmpGte (const (Const 0)) SevError msg

-- | Plain questions without rules, to combine with matrices via 'mconcat'
questionsOnly :: [Question] -> FormParts
questionsOnly qs = (qs, [], [])

-- | Expand a matrix into cell questions, calculations and constraints
matrix :: Matrix -> FormParts
matrix m = (questions, calcs, rules)
  where
    prefix = matrixPrefix m
    cols = matrixCols m
    colsIn r = [ c | c <- cols, maybe True (colKey c `elem`) (rowCols r) ]
    cells = [ (r, c) | r <- matrixRows m, c <- colsIn r ]
    present = [ cellId prefix (rowKey r) (colKey c) | (r, c) <- cells ]
    ref r c = Field (cellId prefix r c)

    formulaFor r c = case lookup (rowKey r, colKey c) (matrixCellFormulas m) of
      Just e -> Just e
      Nothing -> case (colFormula c, rowFormula r) of
        (Just f, _) | rowSummable r, complete (f (ref (rowKey r)))        -> Just (f (ref (rowKey r)))
        (_, Just f) | colSummable c, complete (f (\rk -> ref rk (colKey c))) -> Just (f (\rk -> ref rk (colKey c)))
        _                                                                -> Nothing

    -- Column and row formulas only apply where all their cells exist
    complete e = all (`elem` present) (exprFields e)

    questions =
      [ Question
          { fieldId      = cellId prefix (rowKey r) (colKey c)
          , prompt       = Prompt (rowLabel r ++ ": " ++ colLabel c) Nothing
          , questionType = rowType r
          , required     = colKey c `elem` rowRequired r && not (colPrefilled c)
          , condition    = fmap (\f -> f ref (colKey c)) (rowCondition r)
          , annotations  = Just (KM.fromList
              ([ ("matrix", object
                   [ "id" .= prefix, "row" .= rowKey r, "col" .= colKey c
                   , "rowLabel" .= rowLabel r, "colLabel" .= colLabel c ])
               ] ++ [ ("readOnly", Bool True) | Just _ <- [formulaFor r c] ]
                 ++ [ ("prefilled", Bool True) | colPrefilled c ]
                 ++ [ ("readOnly", Bool True) | colPrefilled c, Nothing <- [formulaFor r c] ]))
          }
      | (r, c) <- cells
      ]

    calcs =
      [ Calculation (cellId prefix (rowKey r) (colKey c)) e
      | (r, c) <- cells
      , Just e <- [formulaFor r c]
      ]

    rules = concatMap instantiate (matrixRules m)

    instantiate rule = case ruleScope rule of
      EachRow ->
        [ c | r <- matrixRows m
            , Just c <- [mk rule (safeKey (rowKey r)) (rowLabel r) (ref (rowKey r))] ]
      EachColumn ->
        [ c | col <- cols
            , Just c <- [mk rule (safeKey (colKey col)) (colLabel col) (\rk -> ref rk (colKey col))] ]

    mk rule suffix lbl cell =
      let l = ruleLeft rule cell
          r = ruleRight rule cell
      in if all (`elem` present) (exprFields l ++ exprFields r)
           then Just Constraint
             { constraintId        = prefix ++ "_" ++ ruleId rule ++ "_" ++ suffix
             , constraintLeft      = l
             , comparison          = ruleComparison rule
             , constraintRight     = r
             , message             = ruleMessage rule ++ " (" ++ lbl ++ ")"
             , severity            = ruleSeverity rule
             , constraintCondition = Nothing
             , reportOn            = []
             }
           else Nothing
