-- | Reference semantics for dialogue rules (calculations and constraints),
-- independent of any execution target. Other interpreters (Altinn, the simulator)
-- must agree with this module.
module SchemaDSL.Eval
  ( Answers
  , Violation(..)
  , evalExpr
  , evalPredicate
  , holds
  , compareValues
  , applyCalculations
  , checkConstraints
  , constraintTargets
  , enteredInputs
  , calculationOrder
  , validateRules
  , formatNumber
  ) where

import Data.List (nub)
import qualified Data.Map.Strict as M
import Numeric (showFFloat)
import Text.Read (readMaybe)
import SchemaDSL.Types

-- | Respondent answers as entered, keyed by fieldId (booleans as "true"/"false")
type Answers = M.Map FieldId String

-- | A constraint that does not hold for a given set of answers
data Violation = Violation
  { violatedConstraint :: Constraint
  , violationFields    :: [FieldId]
  } deriving (Show, Eq)

-- | Evaluate an expression. Empty or non-numeric fields count as 0;
-- division by zero yields Nothing.
evalExpr :: Answers -> Expr -> Maybe Double
evalExpr answers e = case e of
  Field fid -> Just (fieldValue fid)
  Const n   -> Just n
  Add es    -> sum <$> mapM (evalExpr answers) es
  Sub a b   -> (-) <$> evalExpr answers a <*> evalExpr answers b
  Mul es    -> product <$> mapM (evalExpr answers) es
  Div a b   -> do
    x <- evalExpr answers a
    y <- evalExpr answers b
    if y == 0 then Nothing else Just (x / y)
  Floor a   -> (\x -> fromIntegral (floor x :: Integer)) <$> evalExpr answers a
  where
    fieldValue fid = maybe 0 id (M.lookup fid answers >>= parseNumber)

-- | Accepts both "1.5" and Norwegian "1,5"
parseNumber :: String -> Maybe Double
parseNumber s = case filter (/= ' ') (map (\c -> if c == ',' then '.' else c) s) of
  ""            -> Nothing
  cleaned@('.':_) -> readMaybe ('0' : cleaned)
  cleaned       -> readMaybe cleaned

evalPredicate :: Answers -> Predicate -> Bool
evalPredicate answers p = case p of
  Equals fid v    -> M.lookup fid answers == Just v
  NotEquals fid v -> M.lookup fid answers /= Just v
  IsTrue fid      -> M.lookup fid answers == Just "true"
  Compare l cmp r -> case (evalExpr answers l, evalExpr answers r) of
    (Just x, Just y) -> compareValues cmp x y
    _                -> False
  And ps          -> all (evalPredicate answers) ps
  Or ps           -> any (evalPredicate answers) ps

-- | Whether a constraint is satisfied. Equality tolerates floating point noise,
-- and a constraint whose expressions have no value (division by zero) is not violated.
holds :: Answers -> Constraint -> Bool
holds answers c
  | maybe False (not . evalPredicate answers) (constraintCondition c) = True
  | otherwise =
      case (evalExpr answers (constraintLeft c), evalExpr answers (constraintRight c)) of
        (Just l, Just r) -> compareValues (comparison c) l r
        _                -> True

-- | Numeric comparison tolerating floating point noise (1e-6)
compareValues :: Comparison -> Double -> Double -> Bool
compareValues cmp l r = case cmp of
  CmpEq    -> abs (l - r) < eps
  CmpNotEq -> abs (l - r) >= eps
  CmpLt    -> l < r - eps
  CmpLte   -> l <= r + eps
  CmpGt    -> l > r + eps
  CmpGte   -> l >= r - eps
  where
    eps = 1e-6

-- | Fill in all calculated fields, in dependency order
applyCalculations :: Dialogue -> Answers -> Answers
applyCalculations d answers0 = foldl step answers0 (calculationOrder d)
  where
    step answers calc = case evalExpr answers (calcExpr calc) of
      Just v  -> M.insert (calcTarget calc) (formatNumber v) answers
      Nothing -> M.delete (calcTarget calc) answers

-- | Check all constraints against answers (after applying calculations)
checkConstraints :: Dialogue -> Answers -> [Violation]
checkConstraints d answers0 =
  [ Violation c (constraintTargets d c)
  | c <- constraints d
  , not (holds answers c)
  ]
  where
    answers = applyCalculations d answers0

-- | Fields that should display a constraint's message: reportOn if given,
-- otherwise the respondent-entered fields it depends on (calculated fields are
-- traced back to their inputs).
constraintTargets :: Dialogue -> Constraint -> [FieldId]
constraintTargets d c
  | not (null (reportOn c)) = reportOn c
  | otherwise = nub (concatMap (enteredInputs d) (exprFields (constraintLeft c) ++ exprFields (constraintRight c)))

-- | The respondent-entered fields a field depends on: itself if entered,
-- otherwise (transitively) the inputs of its calculation.
enteredInputs :: Dialogue -> FieldId -> [FieldId]
enteredInputs d = nub . inputs []
  where
    calcs = [ (calcTarget calc, calcExpr calc) | calc <- calculations d ]
    inputs seen fid = case lookup fid calcs of
      Just e | fid `notElem` seen -> concatMap (inputs (fid : seen)) (exprFields e)
      Just _                      -> []
      Nothing                     -> [fid]

-- | Calculations sorted so each one runs after the calculations it depends on.
-- Calculations involved in a cycle are dropped (validateRules reports them).
calculationOrder :: Dialogue -> [Calculation]
calculationOrder d = go [] (calculations d)
  where
    targets = map calcTarget (calculations d)
    deps calc = filter (`elem` targets) (exprFields (calcExpr calc))
    go done pending =
      let ready = [ c | c <- pending, all (`elem` map calcTarget done) (deps c) ]
      in if null ready
           then done
           else go (done ++ ready) (filter (`notElem` ready) pending)

-- | Static checks of a dialogue's rules; returns human readable problems
validateRules :: Dialogue -> [String]
validateRules d =
  [ "Calculation for unknown field: " ++ calcTarget c
  | c <- calculations d, calcTarget c `notElem` known ]
  ++
  [ "Calculated field is not numeric: " ++ calcTarget c
  | c <- calculations d
  , Just q <- [lookup (calcTarget c) questionsById]
  , not (isNumeric (questionType q)) ]
  ++
  [ "Field calculated more than once: " ++ t
  | t <- nub targets, length (filter (== t) targets) > 1 ]
  ++
  [ "Calculation " ++ calcTarget c ++ " references unknown field: " ++ f
  | c <- calculations d, f <- nub (exprFields (calcExpr c)), f `notElem` known ]
  ++
  [ "Constraint " ++ constraintId c ++ " references unknown field: " ++ f
  | c <- constraints d
  , f <- nub (exprFields (constraintLeft c) ++ exprFields (constraintRight c) ++ reportOn c)
  , f `notElem` known ]
  ++
  [ "Condition on " ++ owner ++ " references unknown field: " ++ f
  | (owner, p) <- conditions
  , f <- nub (predicateFields p)
  , f `notElem` known ]
  ++
  [ "Duplicate constraint id: " ++ i
  | i <- nub constraintIds, length (filter (== i) constraintIds) > 1 ]
  ++
  [ "Calculation cycle involving: " ++ calcTarget c
  | c <- calculations d, calcTarget c `notElem` map calcTarget (calculationOrder d) ]
  where
    questionsById = [ (fieldId q, q) | q <- allDialogueQuestions d ]
    known = map fst questionsById
    targets = map calcTarget (calculations d)
    constraintIds = map constraintId (constraints d)
    conditions =
      [ (fieldId q, p) | q <- allDialogueQuestions d, Just p <- [condition q] ]
      ++ [ (bolkId b, p) | BolkStep b <- steps d, Just p <- [bolkCondition b] ]
      ++ [ (constraintId c, p) | c <- constraints d, Just p <- [constraintCondition c] ]
    isNumeric qt = qt == QInteger || qt == QDecimal

-- | Render a computed value: integers without decimals, others with at most 6 decimals
formatNumber :: Double -> String
formatNumber v
  | v == fromIntegral r = show r
  | otherwise = trimZeros (showFFloat (Just 6) v "")
  where
    r = round v :: Integer
    trimZeros = reverse . dropWhile (== '.') . dropWhile (== '0') . reverse
