https://powcoder.com
代写代考加微信 powcoder
Assignment Project Exam Help
Add WeChat powcoder
module ParserMonad where
import Control.Monad(ap)

import Data.Char

-- If your interested in this style of parsing look at the parsec, megaparsec, attoparsec libraries

-- the type of a parser
data Parser a = Parser (String -> Maybe (a, String))

-- a helper function to pull out the function bit (same as book)
parse :: Parser a -> (String -> Maybe (a, String))
parse (Parser f) = f




instance Functor Parser where
  -- fmap :: (a -> b) -> Parser a -> Parser b
  fmap f (Parser pa) =  Parser $ \ x -> case pa x of
                                          Nothing        -> Nothing
                                          Just (a, rest) -> Just (f a, rest)

--ignore this for now
instance Applicative Parser where
  pure = return
  (<*>) = ap


instance Monad Parser where
  --return :: a -> Parser a
  return a =  Parser $ \ x -> Just (a,x)


  --(>>=) :: Parser a -> (a -> Parser b) -> Parser b
  (Parser pa) >>= f = Parser $ \ x ->  case pa x of
                                         Nothing       -> Nothing
                                         Just (a,rest) -> parse (f a) rest

-- think, "does it follow the Monad laws?"


-- parse one thing, if that works then parse the other thing
(+++) :: Parser a -> Parser b -> Parser (a,b)
pa +++ pb =  do a <- pa; b <- pb; return (a,b)


mapParser :: Parser a -> (a->b) -> Parser b
mapParser pa f = fmap f pa


-- read in a char (from book)
item :: Parser Char
item = Parser $ \ input -> case input of ""    -> Nothing
                                         (h:t) -> Just (h, t)


-- a parser that always fails (empty in the book)
failParse :: Parser a
failParse = Parser $ \ input -> Nothing


-- read in a char if it passes a test, (from book)
sat :: (Char -> Bool) -> Parser Char
sat p = do c <- item
           if p c
           then return c
           else failParse


-- parse exactly a string, return that string (in book as the poorly named "string")
literal :: String -> Parser String
literal "" = return ""
literal (h:t) = do sat (==h)
                   literal t
                   return (h:t)

-- for example:
-- *ParserMonad> parse (literal "blahh") "blahhhhhh"
-- Just ("blahh","hhhh")



exampleParser' = do literal "let"
                    name <- literal "x" -- in real life this would be a var parser
                    literal "="
                    nat <- literal "2" -- in real life this would be an Ast parser
                    literal "in"
                    body <- literal "3" --in real life this would be an Ast parser
                    return (name, nat, body) -- in real life this would call the constructor

-- for example:
-- *ParserMonad> parse exampleParser' "Letx=2in3"
-- Just (("x","2","3"),"")

--try to parse a, if that doesn't work try to parse b (slightly different from the book)
(<||>) :: Parser a -> Parser b -> Parser (Either a b)
parserA <||> parserB = Parser $ \ input ->  case parse parserA input of
                                                 Just (a, rest) -> Just (Left a, rest)
                                                 Nothing -> case parse parserB input of
                                                              Just (b, rest) -> Just (Right b, rest)
                                                              Nothing        -> Nothing
-- for example:
-- *ParserMonad> parse (literal "aa" <||> literal "bb") "aaaa"
-- Just (Left "aa","aa")
-- *ParserMonad> parse (literal "aa" <||> literal "bb") "bbb"
-- Just (Right "bb","b")

-- like <||> but easier on the same type (from book)
(<|>) :: Parser a -> Parser a -> Parser a
l <|> r =
  do res <- l <||> r
     case res of
       Left  a -> return a
       Right a -> return a


-- take a parser and parse as much as possible into a list, always parse at least 1 thing, (from book)
some :: Parser a -> Parser ([a])
some pa = do a <- pa
             rest <- rep pa
             return (a:rest)

-- for example:
-- *ParserMonad> parse (some (literal "blahh")) "blahhhhhh"
-- Just (["blahh"],"hhhh")
-- *ParserMonad> parse (some (literal "blahh")) "blahhblahhblahhblahhhhhh"
-- Just (["blahh","blahh","blahh","blahh"],"hhhh")
-- *ParserMonad> parse (some (literal "blahh")) "important instructions"
-- Nothing
			 
			 

-- take a parser and parse as much as possible into a list, (in book as "many")
rep :: Parser a -> Parser ([a])
rep pa =  do res <- (some pa) <||> (return [])
             case res of Left ls  -> return ls
                         Right ls -> return ls

-- for example:
-- *ParserMonad> parse (rep (literal "blahh")) "blahhhhhh"
-- Just (["blahh"],"hhhh")
-- *ParserMonad> parse (rep (literal "blahh")) "blahhblahhblahhblahhhhhh"
-- Just (["blahh","blahh","blahh","blahh"],"hhhh")
-- *ParserMonad> parse (rep (literal "blahh")) "important instructions"
-- Just ([],"important instructions")
-- parse a digit (from book)


digit :: Parser Char
digit = sat isDigit


-- parse natural numbers, like "123", or "000230000"
natParser :: Parser Integer
natParser =  do digits <- some digit
                return $ read digits
				
-- for example:
-- *ParserMonad> parse natParser "12345"
-- Just (12345,"")

intParser  :: Parser Integer
intParser = do r <- (literal "-") <||> natParser
               case r of
                Left _ -> fmap (0-) natParser
                Right n -> return n

--parse spaces, throw them away
spaces :: Parser ()
spaces =  do rep (sat isSpace)
             return ()

-- a nicer version of eat spaces, eat the spaces before or after the parser (from book)
token:: Parser a -> Parser a
token pa = do spaces
              a <- pa
              spaces
              return a


-- parse what we will consider a good variable name
varParser :: Parser String
varParser = do chars <- some (sat isAlpha)
               return chars



exampleParser = do token $ literal "let"
                   name <- varParser
                   token $ literal "="
                   nat <- natParser --in real life this would be an Ast parser
                   token $ literal "in"
                   body <- natParser --in real life this would be an Ast parser
                   return (name, nat, body) -- in real life this would call the Let constructor