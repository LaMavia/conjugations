module Ling where

import Data.List
import Data.Typeable
import Control.Exception
import Debug.Trace
import Helpers

type Conjugation = [String]
type Suffixes    = [String]
type Irreg       = (Int, Char)
type Infinitive  = String
-- baseStem, [irregularity], suffix
data Pattern     = Pattern String [Irreg] String
  deriving (Show)
-- A non-specific version of `Pattern`
data Category    = Category [Irreg] String
  deriving (Show)
type Verb        = (Infinitive, [[[Pattern]]]) -- ¿?
-- Index, baseForm, TransformedForm
{- ex: [poder, puedo] -> [ Pattern (pd, [(0, o)], er) 
                         , Pattern (pd, [(0, u), (1, e)], o) 
                         ]
                     -> Transform (0, o, ue)
-}
-- type Transform   = (Int, String, String) 

data ConjugationError = ConjugationError [[Conjugation]]
  deriving (Show, Typeable)

instance Exception ConjugationError


assemblePattern :: Pattern -> String
assemblePattern (Pattern base irs suffix) =
  foldl aux (base <> suffix) irs
  where 
    aux w (i, l) = insertAt l i w

stemWIrreg :: Conjugation -> [Pattern]
stemWIrreg ws = map (aux [] 0 baseStem) ws
  where
    -- `foldl1 common ws` did not work with [inf, pres.p, past.p] of contradecir
    baseStem                = foldl1 common [ common a b 
                                            | a <- ws
                                            , b <- ws
                                            , a /= b]
      -- foldl1 common ws -- $ map subsequences 
    aux rest i base w
      | isExhausted         = Pattern baseStem (reverse rest) w
      | head base == head w = aux rest (i + 1) (tail base) (tail w)
      | otherwise           = aux ((i - 1, head w) : rest) (i + 1) base (tail w)
      where 
        isExhausted = length base == 0 
                      || length w == 0

-- deprecated
stem :: Conjugation -> String
stem cs = aux (cs !! 0) cs
  where
    n0 = length cs
    aux pf wds
      | matches == n0 = pf 
      | otherwise     = aux (init pf) wds
      where 
          matches = length 
                    $ filter (/= Nothing)
                    $ map (stripPrefix pf) wds

-- deprecated
conn :: IO ()
conn = print $ map (\\ (stem words)) words
  where 
    words = [ "robię", "robisz", "robi", "robimy", "robicie", "robią"] 

-- checks whether a given word is a Spanish verb (excluding reflexive ones)
isVerbSpanish :: String -> Bool
isVerbSpanish str = 
  or [ isSuffixOf ending str
     | ending <- ["ar", "er", "ér", "ir", "ír"]
     ] && not (isInfixOf "%20" str)

normalizeConjugations :: [[Conjugation]] -> [[Conjugation]]
normalizeConjugations (ps:ws) = ([concat ps] : ws)
normalizeConjugations ws = throw $ ConjugationError ws

categoryOfPattern :: Pattern -> Category
categoryOfPattern (Pattern _ ir s) = Category ir s

{-
  | - mood splitter
  _ - tense splitter
  , - person splitter
-}
categoryOfVerb :: [[[Pattern]]] -> [[[Category]]]
categoryOfVerb cs = 
  map
  (map (map categoryOfPattern))
  cs
  {-intercalate "|"
  $ map (
    (intercalate "_") 
    . map (intercalate ",")
  ) cs-}