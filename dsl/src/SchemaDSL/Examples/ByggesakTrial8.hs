{-# LANGUAGE OverloadedStrings #-}

-- | Trial 8: Trial 7 corrected slice by slice after the audit against the XML4DR form
-- (plans/byggesak-trial8/, findings in audit/findings/byggesak.json). Trial 7 stays frozen as the
-- audit baseline; each slice below patches one bolk and cites the finding it resolves.
-- Field ids keep the @t7_@ prefix so answers and the alignment overrides carry over.
--
-- Slices: T8a (bolk A, F-003), T8b (F-004), T8c (F-004 rest + F-005).
module SchemaDSL.Examples.ByggesakTrial8
  ( trial8ByggesakDialogue
  , t8aBolkA
  , t8bCalculatedAlwaysVisible
  , t8cConditionalGating
  , t8dCalculationInputs
  , t8eRequiredLevels
  ) where

import SchemaDSL.Builders (weightedAverage)
import SchemaDSL.Examples.ByggesakTrial7 (trial7ByggesakDialogue)
import SchemaDSL.Types

trial8ByggesakDialogue :: Dialogue
trial8ByggesakDialogue = (foldl (flip ($)) trial7ByggesakDialogue slices)
  { dialogueId = "trial8-byggesak"
  , title      = "20. Byggesak 2026 (Trial 8: Rettet etter audit mot XML4DR)"
  }
  where
    slices = [t8aBolkA, t8bCalculatedAlwaysVisible, t8cConditionalGating, t8dCalculationInputs, t8eRequiredLevels]

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

-- | T8c: resolve the remaining F-004 items (10 G1/G2/G3 cells that XML4DR leaves unconditional)
-- and resolve F-005 (add missing gating on C12, C3, D2, F2 matching XML guidance handlers).
t8cConditionalGating :: Dialogue -> Dialogue
t8cConditionalGating = onBolk "bolk_g1" (onQuestions ungateG1 (\q -> q { condition = Nothing }))
                     . onBolk "bolk_g2" (onQuestions ungateG2 (\q -> q { condition = Nothing }))
                     . onBolk "bolk_g3" (onQuestions ["t7_g3_a_a"] (\q -> q { condition = Nothing }))
                     . onBolk "bolk_c12" (onQuestions ["t7_c12_1_b"] (\q -> q { condition = Just (gtZero (Field "t7_c12_1_a")) }))
                     . onBolk "bolk_c12" (onQuestions ["t7_c12_2_b"] (\q -> q { condition = Just (gtZero (Field "t7_c12_2_a")) }))
                     . onBolk "bolk_c3"  (onQuestions ["t7_c3_1_c"] (\q -> q { condition = Just (gtZero (Field "t7_c3_1_a")) }))
                     . onBolk "bolk_c3"  (onQuestions ["t7_c3_2_c"] (\q -> q { condition = Just (gtZero (Field "t7_c3_2_a")) }))
                     . onBolk "bolk_d2"  (onQuestions ["t7_d2_1_a"] (\q -> q { condition = Just (gtZero (Field "t7_c10_2_f")) }))
                     . onBolk "bolk_d2"  (onQuestions ["t7_d2_3_a"] (\q -> q { condition = Just (gtZero (Field "t7_c4_2_a")) }))
                     . onBolk "bolk_f2"  (onQuestions ["t7_f2_a_b", "t7_f2_a_c", "t7_f2_a_d"] (\q -> q { condition = Just (gtZero (Field "t7_f2_a_a")) }))
  where
    ungateG1 = [ "t7_g1_b1_b", "t7_g1_b1_c", "t7_g1_b2_b", "t7_g1_b2_c", "t7_g1_b3_b", "t7_g1_b3_c" ]
    ungateG2 = [ "t7_g2_b1_a", "t7_g2_b2_a", "t7_g2_b3_a" ]
    gtZero e = Compare e CmpGt (Const 0)

-- | T8d: F-008 calculation inputs. Re-express calculations to read direct source inputs:
-- 1. D1 row 1b: sum area restriction main rows [2, 3, 4, 5, 6, 7] (not 2a, which is a sub-row).
-- 2. C14 columns b2 and d: sum C11, C12, C13 (and C10) directly rather than intra-matrix column combinations.
-- 3. C14 row 2.2 columns b2 and d: include C11 in the weighted average calculations.
t8dCalculationInputs :: Dialogue -> Dialogue
t8dCalculationInputs d = d { calculations = map patch (calculations d) }
  where
    patch c = case lookup (calcTarget c) replacements of
      Just e  -> Calculation (calcTarget c) e
      Nothing -> c

    replacements =
      -- D1 row 1b: area restriction rows 2, 3, 4, 5, 6, 7
      [ ("t7_d1_1b_a",  Add [ Field ("t7_d1_" ++ r ++ "_a") | r <- ["2", "3", "4", "5", "6", "7"] ])
      , ("t7_d1_1b_b",  Add [ Field ("t7_d1_" ++ r ++ "_b") | r <- ["2", "3", "4", "5", "6", "7"] ])
      , ("t7_d1_1b_b1", Add [ Field ("t7_d1_" ++ r ++ "_b1") | r <- ["2", "3", "5"] ])
      , ("t7_d1_1b_b2", Add [ Field "t7_d1_2_b2", Field "t7_d1_3_b2", Field "t7_d1_4_b", Field "t7_d1_5_b2" ])
      , ("t7_d1_1b_c",  Add [ Field ("t7_d1_" ++ r ++ "_c") | r <- ["2", "3", "4", "5", "6", "7"] ])
      -- C14 column b2: C11 (all 12w) + C12 + C13
      , ("t7_c14_1_b2",   Add [ Field "t7_c11_1_b", Field "t7_c12_1_b2", Field "t7_c13_1_b2" ])
      , ("t7_c14_2_b2",   Add [ Field "t7_c11_2_b", Field "t7_c12_2_b2", Field "t7_c13_2_b2" ])
      , ("t7_c14_2_1_b2", Add [ Field "t7_c11_2_1_b", Field "t7_c12_2_1_b2", Field "t7_c13_2_1_b2" ])
      , ("t7_c14_2_2_b2", Floor (weightedAverage
          [ (Field "t7_c11_2_2_b", Field "t7_c11_2_b")
          , (Field "t7_c12_2_2_b2", Field "t7_c12_2_b2")
          , (Field "t7_c13_2_2_b2", Field "t7_c13_2_b2")
          ]))
      -- C14 column d: C10 b / C11 + C12 + C13
      , ("t7_c14_1_d",   Add [ Field "t7_c10_1_b", Field "t7_c12_1_d", Field "t7_c13_1_d" ])
      , ("t7_c14_2_d",   Add [ Field "t7_c10_2_b", Field "t7_c12_2_d", Field "t7_c13_2_d" ])
      , ("t7_c14_2_1_d", Add [ Field "t7_c11_2_1_a", Field "t7_c12_2_1_d", Field "t7_c13_2_1_d" ])
      , ("t7_c14_2_2_d", Floor (weightedAverage
          [ (Field "t7_c11_2_2_c", Field "t7_c10_2_b")
          , (Field "t7_c12_2_2_d", Field "t7_c12_2_d")
          , (Field "t7_c13_2_2_d", Field "t7_c13_2_d")
          ]))
      ]

-- | T8e: RequiredLevel feature (F-002, F-003).
-- 1. Relax the 24 F-003 fields where XML4DR has no required check (C10, Bolk I, radios, etc.) to ReqNone.
-- 2. Mark the 106 F-002 fields where XML4DR has FieldFilled(obThis) with severity warning to ReqWarn (soft required).
-- 3. Mark all remaining required fields with ReqError (hard blocking) and non-required with ReqNone.
t8eRequiredLevels :: Dialogue -> Dialogue
t8eRequiredLevels d = d { steps = map patchStep (steps d) }
  where
    patchStep (BolkStep b) = BolkStep b { bolkQuestions = map patchQ (bolkQuestions b) }
    patchStep s = s

    patchQ q
      | fieldId q `elem` f003Fields = setRequired ReqNone q
      | fieldId q `elem` f002Fields = setRequired ReqWarn q
      | required q                  = setRequired ReqError q
      | otherwise                   = setRequired ReqNone q

    -- 24 fields where Trial 7 had required:true but XML4DR has no required check
    f003Fields =
      [ "t7_c10_1_a", "t7_c10_1_b", "t7_c10_1_c", "t7_c10_1_d", "t7_c10_1_e", "t7_c10_1_f"
      , "t7_c10_2_a", "t7_c10_2_b", "t7_c10_2_c", "t7_c10_2_d", "t7_c10_2_e", "t7_c10_2_f"
      , "t7_e0a_klagerMottattEllerBehandlet", "t7_e0b_statsforvalterBehandlet"
      , "t7_elektroniskSakssystemBrukt", "t7_f0a_erUtfoertTilsyn", "t7_f1_a_a"
      , "t7_g0_erGittPaaleggEllerSanksjoner", "t7_g1_a_a", "t7_g2_a_a", "t7_g4_a_a"
      , "t7_maskinelleOpptellinger", "t7_timerFremskaffe", "t7_timerUtfylling"
      ]

    -- 106 fields where XML4DR checks FieldFilled(obThis) with severity=warning
    f002Fields =
      [ "t7_b_1_a", "t7_b_2_a"
      , "t7_c11_1_1_a", "t7_c11_2_1_a", "t7_c11_2_2_b", "t7_c11_2_2_c", "t7_c11_2_b"
      , "t7_c12_1_1_a", "t7_c12_1_b", "t7_c12_1_b1", "t7_c12_2_1_a", "t7_c12_2_1_b"
      , "t7_c12_2_2_b1", "t7_c12_2_2_b2", "t7_c12_2_2_c", "t7_c12_2_b"
      , "t7_c13_1_1_a", "t7_c13_2_1_a", "t7_c13_2_2_b1", "t7_c13_2_2_b2", "t7_c13_2_b", "t7_c13_2_b1"
      , "t7_c15_1_1_a", "t7_c15_1_b", "t7_c15_2_1_a", "t7_c15_2_2_b", "t7_c15_2_2_c", "t7_c15_2_b"
      , "t7_c16_1_a", "t7_c16_1_b", "t7_c16_1_c", "t7_c16_2_a", "t7_c16_2_b", "t7_c16_2_c"
      , "t7_c2_1_b", "t7_c2_1_b1", "t7_c2_2_2_b1", "t7_c2_2_2_b2", "t7_c2_2_2_c", "t7_c2_2_b", "t7_c2_2_b1"
      , "t7_c3_1_a", "t7_c3_2_2_a", "t7_c3_2_2_b", "t7_c3_2_2_c", "t7_c3_2_a"
      , "t7_c4_1_b", "t7_c4_1_c", "t7_c4_1_d", "t7_c4_2_b"
      , "t7_d1_1a_b", "t7_d1_1a_b1", "t7_d1_1a_b2", "t7_d1_1a_c"
      , "t7_d1_2_a", "t7_d1_2_b", "t7_d1_2_b1", "t7_d1_2_b2", "t7_d1_2_c"
      , "t7_d1_2a_a", "t7_d1_2a_b", "t7_d1_2a_c"
      , "t7_d1_3_b", "t7_d1_3_b1", "t7_d1_3_b2", "t7_d1_3_c"
      , "t7_d1_4_a", "t7_d1_4_b", "t7_d1_4_c"
      , "t7_d1_4a_a", "t7_d1_4a_b", "t7_d1_4a_c"
      , "t7_d1_4b_a", "t7_d1_4b_b", "t7_d1_4b_c"
      , "t7_d1_5_a", "t7_d1_5_b", "t7_d1_5_b1", "t7_d1_5_b2", "t7_d1_5_c"
      , "t7_d1_6_a", "t7_d1_6_b", "t7_d1_6_c"
      , "t7_d1_7_a", "t7_d1_7_b", "t7_d1_7_c"
      , "t7_d2_1_b", "t7_d2_1_b1", "t7_d2_1_b2", "t7_d2_1_c"
      , "t7_d2_2_a", "t7_d2_2_b", "t7_d2_2_c"
      , "t7_d2_3_b", "t7_d2_3_c"
      , "t7_e1_2_d", "t7_e1_3a_d", "t7_e1_3b_b", "t7_e1_3b_d", "t7_e1_3d_d"
      , "t7_e2_2_e", "t7_e2_3a_e", "t7_e2_3b_e", "t7_e2_3c_e", "t7_e2_3d_e", "t7_e2_4_e"
      , "t7_f2_a_a"
      ]
