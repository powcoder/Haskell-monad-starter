https://powcoder.com
代写代考加微信 powcoder
Assignment Project Exam Help
Add WeChat powcoder
module Lang3Parser where

import Data.Map (Map)-- for state
import qualified Data.Map as Map -- for State in tests

import State
import Lang3 (Ast(..), eval)
import ParserMonad

-- You might want to use helper functions like
setVar :: String -> Integer -> State AssignmetState ()
setVar v i = 
  do s <- get
     put (Map.insert v i s)
     
-- same as
--State (\ s -> ((), Map.insert v i s))

getVar :: String -> State AssignmetState Integer
getVar v =
  do s <- get
     case (Map.lookup v s) of
       Just i  -> return i
       Nothing -> return 0  -- since for this problem we may return 0 if the var is not set
-- same as
--State (\ s -> ((case Map.lookup v s of
--                  Nothing -> 0 -- since for this problem we may return 0 if the var is not set
--                  Just i  -> i), s)





parser :: Parser Ast
parser = undefined

-- for repl testing
data Lang3Out = ParseError | RuntimeError | Result Integer deriving (Show, Eq)

-- execute in a clean state keeping only the result
exec :: String -> Lang3Out
exec s = case (parse parser) s of
  Just (ast,"") -> case runState (eval ast) Map.empty of
    (i, _) -> Result i
  _  -> ParseError
