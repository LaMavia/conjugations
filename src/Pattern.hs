{-# LANGUAGE OverloadedStrings #-}


module Pattern where

import Control.Monad
import Control.Applicative
import Data.Aeson
  
type Conjugation = [String]
type Suffixes    = [String]
type Irreg       = (Int, Char)
type Infinitive  = String
-- baseStem, [irregularity], suffix
data Pattern     = Pattern String [Irreg] String
  deriving (Show)
-- A non-specific version of `Pattern`
type Verb        = (Infinitive, [[[Pattern]]]) -- ¿?
-- Index, baseForm, TransformedForm
{- ex: [poder, puedo] -> [ Pattern (pd, [(0, o)], er) 
                         , Pattern (pd, [(0, u), (1, e)], o) 
                         ]
                     -> Transform (0, o, ue)
-}
type Transform   = String
data Category    = Category [Transform] String
  deriving (Eq, Show)

instance ToJSON Category where
  toJSON (Category ts suffix) = object 
    [ "transformations" .= ts
    , "suffix"          .= suffix
    ]
  
  toEncoding (Category ts suffix) = pairs  
    $  "transformations" .= ts
    <> "suffix"          .= suffix
    
instance FromJSON Category where
  parseJSON (Object v) = Category <$>
                        v .: "transformations" <*>
                        v .: "suffix"

  parseJSON _          = empty