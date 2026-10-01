{-# LANGUAGE OverloadedStrings #-}
-- | Parser for the JavaScript subset used in XML4DR <Eval> handlers.
module Audit.Eval (Ex(..), BinOp(..), Chain(..), parseEval, pretty, refsOf) where

import Data.Functor (($>))
import Data.Text (Text)
import qualified Data.Text as T
import Text.Parsec
import Text.Parsec.Text (Parser)

data BinOp = Add | Sub | Mul | Div | Lt | Le | Gt | Ge | Eq | Ne | And | Or
  deriving (Eq, Show)

data Ex
  = Num Double
  | Str Text
  | NullV
  | Ref Text Text          -- GetFieldValue("Set","Data")
  | This                   -- obThis
  | Filled (Maybe (Text, Text))   -- FieldFilled(obThis | "Set","Data")
  | IsEmail
  | Bin BinOp Ex Ex
  deriving (Eq, Show)

-- | Either a plain expression or an if / else if / else value chain (calculations).
data Chain = Plain Ex | Cond [(Ex, Ex)] Ex
  deriving (Eq, Show)

parseEval :: Text -> Either String Chain
parseEval t = either (Left . show) Right (parse (ws *> chain <* eof) "eval" t)

ws :: Parser ()
ws = skipMany (space <|> char '\r' $> ' ')

tok :: Parser a -> Parser a
tok p = p <* ws

sym :: String -> Parser ()
sym s = tok (try (string s) $> ())

kw :: String -> Parser ()
kw s = tok (try (string s <* notFollowedBy alphaNum) $> ())

chain :: Parser Chain
chain = ifChain <|> (Plain <$> expr)

ifChain :: Parser Chain
ifChain = do
  kw "if"
  c0 <- paren expr
  v0 <- braces expr
  rest <- many (try (kw "else" *> kw "if") *> ((,) <$> paren expr <*> braces expr))
  el <- option NullV (kw "else" *> braces expr)
  pure (Cond ((c0, v0) : rest) el)

paren, braces :: Parser a -> Parser a
paren p = sym "(" *> p <* sym ")"
braces p = sym "{" *> p <* sym "}"

expr :: Parser Ex
expr = orE

binLevel :: Parser Ex -> [(String, BinOp)] -> Parser Ex
binLevel next ops = next >>= loop
  where
    loop l = (do op <- choice [ sym s $> o | (s, o) <- ops ]
                 r <- next
                 loop (Bin op l r)) <|> pure l

orE, andE, cmpE, addE, mulE :: Parser Ex
orE = binLevel andE [("||", Or)]
andE = binLevel cmpE [("&&", And)]
cmpE = binLevel addE [("<=", Le), (">=", Ge), ("==", Eq), ("!=", Ne), ("<", Lt), (">", Gt)]
addE = binLevel mulE [("+", Add), ("-", Sub)]
mulE = binLevel atom [("*", Mul), ("/", Div)]

atom :: Parser Ex
atom = tok (choice
  [ Num . read <$> try number
  , Str . T.pack <$> (char '"' *> many (noneOf "\"") <* char '"')
  , kw "null" $> NullV
  , try (kw "GetFieldValue" *> paren ((This <$ kw "obThis") <|> refArgs))
  , try (kw "FieldFilled" *> paren ((Filled Nothing <$ kw "obThis") <|> (Filled . Just <$> pairArgs)))
  , try (kw "isEmailAddress" *> paren (kw "obThis")) $> IsEmail
  , paren expr ])
  where
    number = do
      a <- many1 digit
      b <- option "" ((:) <$> char '.' <*> many1 digit)
      pure (a ++ b)
    pairArgs = (,) <$> (strLit <* sym ",") <*> strLit
    refArgs = uncurry Ref <$> pairArgs
    strLit = tok (T.pack <$> (char '"' *> many (noneOf "\"") <* char '"'))

pretty :: Chain -> Text
pretty (Plain e) = ex e
pretty (Cond bs el) = T.intercalate " ; " [ ex c <> " ⇒ " <> ex v | (c, v) <- bs ] <> " ; else " <> ex el

ex :: Ex -> Text
ex e = case e of
  Num n -> T.pack (if n == fromIntegral (round n :: Integer) then show (round n :: Integer) else show n)
  Str s -> "\"" <> s <> "\""
  NullV -> "null"
  Ref s d -> s <> "." <> d
  This -> "this"
  Filled Nothing -> "filled(this)"
  Filled (Just (s, d)) -> "filled(" <> s <> "." <> d <> ")"
  IsEmail -> "isEmail(this)"
  Bin o a b -> "(" <> ex a <> " " <> opT o <> " " <> ex b <> ")"
  where
    opT o = case o of
      Add -> "+"; Sub -> "-"; Mul -> "*"; Div -> "/"; Lt -> "<"; Le -> "<="; Gt -> ">"; Ge -> ">="
      Eq -> "=="; Ne -> "!="; And -> "&&"; Or -> "||"

-- | All cell references, in order of appearance.
refsOf :: Chain -> [(Text, Text)]
refsOf (Plain e) = go e
refsOf (Cond bs el) = concat [ go c ++ go v | (c, v) <- bs ] ++ go el

go :: Ex -> [(Text, Text)]
go (Ref s d) = [(s, d)]
go (Filled (Just r)) = [r]
go (Bin _ a b) = go a ++ go b
go _ = []
