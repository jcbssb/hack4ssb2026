{-# LANGUAGE OverloadedStrings #-}

-- | Trial 8: Trial 7 corrected slice by slice after the audit against the XML4DR form
-- (plans/byggesak-trial8/, findings in audit/findings/byggesak.json). Trial 7 stays frozen as the
-- audit baseline; each slice below patches one bolk and cites the finding it resolves.
-- Field ids keep the @t7_@ prefix so answers and the alignment overrides carry over.
--
-- Slices: T8a (bolk A, F-003), T8b (F-004).
module SchemaDSL.Examples.ByggesakTrial8
  ( trial8ByggesakDialogue
  ) where

import SchemaDSL.Examples.ByggesakTrial7 (trial7ByggesakDialogue)
import SchemaDSL.Types

trial8ByggesakDialogue :: Dialogue
trial8ByggesakDialogue = (foldl (flip ($)) trial7ByggesakDialogue slices)
  { dialogueId = "trial8-byggesak"
  , title      = "20. Byggesak 2026 (Trial 8: Rettet etter audit mot XML4DR)"
  }
  where
    slices = [t8aBolkA, t8bCalculatedAlwaysVisible]

onBolk :: String -> (Bolk -> Bolk) -> Dialogue -> Dialogue
onBolk bid f d = d { steps = [ case s of BolkStep b | bolkId b == bid -> BolkStep (f b); _ -> s | s <- steps d ] }

onQuestions :: [FieldId] -> (Question -> Question) -> Bolk -> Bolk
onQuestions ids f b = b { bolkQuestions = [ if fieldId q `elem` ids then f q else q | q <- bolkQuestions b ] }

-- | T8a, F-003: the source has no required check on kommunenummer, kommunens navn and
-- skjemaansvarlig (name, e-post); only the telefonnummer is checked. The DSL no longer blocks on them.
t8aBolkA :: Dialogue -> Dialogue
t8aBolkA = onBolk "bolk_a" $ onQuestions
  [ "t7_kommunenummer", "t7_kommunensNavn", "t7_navnSkjemaansvarlig", "t7_epostSkjemaansvarlig" ]
  (\q -> q { required = False })

-- | T8b, F-004: calculated cells are always visible (dark grey) in the source; only input cells
-- are opened by guidance handlers. Drop the DSL condition on every calculated field, except
-- t7_c3_2_1_c: the source gates that calculated cell (Section31/VB2021_8), so the condition stays.
t8bCalculatedAlwaysVisible :: Dialogue -> Dialogue
t8bCalculatedAlwaysVisible d = d { steps = map step (steps d) }
  where
    targets = map calcTarget (calculations d)
    step (BolkStep b) = BolkStep b { bolkQuestions = map unGate (bolkQuestions b) }
    step s = s
    unGate q | fieldId q `elem` targets, fieldId q /= "t7_c3_2_1_c" = q { condition = Nothing }
             | otherwise = q
