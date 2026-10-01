{-# LANGUAGE OverloadedStrings #-}
-- | Collect audit items (diffs and unmatched checks) and attach them to triaged findings.
module Audit.Audit (runAudit) where

import Audit.Align
import Audit.Dsl
import Audit.Eval (parseEval, pretty)
import Audit.Findings
import Audit.Index
import Audit.Xml4dr
import Data.Aeson (object, (.=), encode)
import qualified Data.ByteString.Lazy as BL
import Data.List (find)
import qualified Data.Map.Strict as M
import Data.Maybe (mapMaybe)
import qualified Data.Set as S
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO

collect :: Form -> Config -> [DField] -> [DConstraint] -> [Report] -> ([Item], Int)
collect f cfg dsl cons rs = (cellItems ++ dslChecks ++ xmlChecks, unmappedChecks)
  where
    gmap = M.fromList [ (cellKey (mCell m), dId (mField m)) | r <- rs, m <- rMatched r ]
    fieldBolk = M.fromList [ (dId d, dBolk d) | d <- dsl ]
    mappedF = S.fromList (M.elems gmap)
    cellItems =
      [ Item "cell-diff" (cellKey (mCell m)) (rBolk r) dtext (kindName (kindOf f (mCell m))) | r <- rs, m <- rMatched r, dtext <- mDiffs m ]
      ++ [ Item "dsl-only" (dId d) (rBolk r) (dLabel d) "" | r <- rs, d <- rDslOnly r ]
      ++ [ Item "xml-only" (cellKey c) (rBolk r) (cellLabel f c) "" | r <- rs, c <- rXmlOnly r ]
    mappedSets = S.fromList (concat [ M.findWithDefault [] b (cfgBolks cfg) | b <- map rBolk rs ])
    refKeys h = [ s <> "/" <> d | (s, d) <- handlerRefs (hEval h) ]
    xchecks =
      [ (c, h, keys)
      | c <- cells f, cSet c `S.member` mappedSets, h <- ownChecks f c
      , T.strip (hEval h) /= "FieldFilled(obThis)"
      , let keys = S.fromList (cellKey c : refKeys h) ]
    resolved = [ (c, h, S.fromList [ x | k <- S.toList keys, Just x <- [M.lookup k gmap] ], all (`M.member` gmap) (S.toList keys)) | (c, h, keys) <- xchecks ]
    unmappedChecks = length [ () | (_, _, _, ok) <- resolved, not ok ]
    xSets = S.fromList [ fs | (_, _, fs, True) <- resolved ]
    dCons = [ (k, S.fromList (kFields k)) | k <- cons, not (null (kFields k)), all (`S.member` mappedF) (kFields k) ]
    dSets = S.fromList (map snd dCons)
    dslChecks = [ Item "dsl-constraint" (kId k) (M.findWithDefault "" (head (kFields k)) fieldBolk) (kComparison k <> " " <> kSeverity k <> ": " <> T.take 90 (kMessage k)) ""
                | (k, fs) <- dCons, fs `S.notMember` xSets ]
    xmlChecks = [ Item "xml-check" (cellKey c) (M.findWithDefault "" (head (S.toList fs)) fieldBolk)
                    (T.take 110 (either (const (hEval h)) pretty (parseEval (hEval h))) <> " " <> sev h) (kindName (kindOf f c))
                | (c, h, fs, True) <- resolved, fs `S.notMember` dSets ]
    sev h = "[" <> T.intercalate "/" [ s | a <- hActions h, SetError s <- aEffects a ] <> "]"

runAudit :: Form -> Config -> [DField] -> [DConstraint] -> [Finding] -> [Text] -> FilePath -> IO ()
runAudit f cfg dsl cons fs bs outJson = do
  let rs = alignMany f cfg dsl bs
      (items, unm) = collect f cfg dsl cons rs
      tagged = [ (i, fmap fId (find (\x -> any (`matches` i) (fRules x)) fs)) | i <- items ]
      forF x = [ i | (i, Just t) <- tagged, t == fId x ]
      untriaged = [ i | (i, Nothing) <- tagged ]
      count k is = length [ () | i <- is, iKind i == k ]
      line x = let is = forF x in T.concat
        [ fId x, " [", fStatus x, "/", fSeverity x, "/", fFixKind x, "] ", fTitle x, " — ", T.pack (show (length is)), " items" ]
  mapM_ (TIO.putStrLn . line) fs
  TIO.putStrLn ("untriaged: " <> T.pack (show (length untriaged)) <> " of " <> T.pack (show (length items))
                <> " (" <> T.pack (show (count "cell-diff" untriaged)) <> " cell diffs, " <> T.pack (show (count "dsl-constraint" untriaged)) <> " DSL constraints, "
                <> T.pack (show (count "xml-check" untriaged)) <> " XML checks); " <> T.pack (show unm) <> " XML checks skipped (touch unmapped bolks)")
  mapM_ (\i -> TIO.putStrLn ("  ? " <> iKind i <> " " <> iWhere i <> " " <> iText i)) (take 15 untriaged)
  BL.writeFile outJson $ encode $ object
    [ "findings" .= [ object [ "id" .= fId x, "title" .= fTitle x, "fixKind" .= fFixKind x, "severity" .= fSeverity x, "status" .= fStatus x
                             , "description" .= fDescription x, "proposedFix" .= fProposed x
                             , "items" .= [ object [ "kind" .= iKind i, "where" .= iWhere i, "bolk" .= iBolk i, "text" .= iText i ] | i <- forF x ] ] | x <- fs ]
    , "cellFindings" .= M.toList (M.fromListWith (++) [ (iWhere i, [t]) | (i, Just t) <- tagged, iKind i `elem` ["cell-diff", "xml-check", "xml-only"] ])
    , "untriaged" .= [ object [ "kind" .= iKind i, "where" .= iWhere i, "bolk" .= iBolk i, "text" .= iText i ] | i <- untriaged ]
    ]
