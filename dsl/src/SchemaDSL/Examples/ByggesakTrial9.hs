{-# LANGUAGE OverloadedStrings #-}

-- | Trial 9: Trial 8 enhanced with municipality context gating (F-009) and
-- constraint severity alignment (soft non-blocking warnings for plausibility cross-checks).
-- Field ids keep the @t7_@ prefix so answers and alignment overrides carry over.
module SchemaDSL.Examples.ByggesakTrial9
  ( trial9ByggesakDialogue
  , t9aStrandsoneGating
  , t9bConstraintSeverities
  ) where

import Data.List (isInfixOf)
import SchemaDSL.Examples.ByggesakTrial8 (trial8ByggesakDialogue)
import SchemaDSL.Types

trial9ByggesakDialogue :: Dialogue
trial9ByggesakDialogue = (foldl (flip ($)) trial8ByggesakDialogue slices)
  { dialogueId = "trial9-byggesak"
  , title      = "20. Byggesak 2026 (Trial 9: Konsistenssjekker og audit-tilpasning)"
  }
  where
    slices = [t9aStrandsoneGating, t9bConstraintSeverities]

onBolk :: String -> (Bolk -> Bolk) -> Dialogue -> Dialogue
onBolk bid f d = d { steps = [ case s of BolkStep b | bolkId b == bid -> BolkStep (f b); _ -> s | s <- steps d ] }

onQuestions :: [FieldId] -> (Question -> Question) -> Bolk -> Bolk
onQuestions ids f b = b { bolkQuestions = [ if fieldId q `elem` ids then f q else q | q <- bolkQuestions b ] }

-- | T9a, F-009: Section13/VB2019_2 (Strandsone flag) prefilled per municipality.
-- Gate D1 question 3 (Section_E1/V2012_7 and row 3 cells) on the coastal municipality context flag.
t9aStrandsoneGating :: Dialogue -> Dialogue
t9aStrandsoneGating = onBolk "bolk_d1" (onQuestions d1Row3 (\q -> q { condition = Just (Compare (Field "t7_kommunenummer") CmpGt (Const 0)) }))
  where
    d1Row3 = [ "t7_d1_3_a", "t7_d1_3_b", "t7_d1_3_b1", "t7_d1_3_b2", "t7_d1_3_c" ]

-- | T9b, F-006: Downgrade DSL cross-field plausibility checks (overFrist, utfall, behandlet)
-- to soft warning severity (SevWarning) so that in Altinn and the simulator they guide the
-- respondent with non-blocking nudges instead of submission-blocking errors.
t9bConstraintSeverities :: Dialogue -> Dialogue
t9bConstraintSeverities d = d { constraints = map soften (constraints d) }
  where
    soften c
      | shouldSoften (constraintId c) = c { severity = SevWarning }
      | otherwise                    = c
    shouldSoften cid = any (`isInfixOf` cid) ["overFrist", "behandlet", "utfall", "innvilget"]
