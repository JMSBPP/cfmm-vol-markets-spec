module Payoffs.Return
  ( returnPipsScale
  , ReturnPips(..)
  , unReturnPips
  , mkReturn
  ) where

import SqrtGrid (PayoffX96(..))

returnPipsScale :: Integer
returnPipsScale = 1000000

newtype ReturnPips = ReturnPips Integer
  deriving (Show, Eq, Ord)

unReturnPips :: ReturnPips -> Integer
unReturnPips (ReturnPips r) = r

mkReturn :: PayoffX96 -> PayoffX96 -> ReturnPips
mkReturn (PayoffX96 pn) (PayoffX96 pd)
  | pd <= 0 =
      error "Payoffs.Return.mkReturn: denominator PayoffX96 must be > 0"
  | otherwise =
      ReturnPips $ ((pn - pd) * returnPipsScale) `div` pd
