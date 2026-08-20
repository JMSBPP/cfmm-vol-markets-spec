module Payoffs.Linear
  ( linearPayoff
  , linear
  ) where

import qualified Payoffs.Payoff as Payoff
import SqrtGrid (PayoffX96, SqrtPriceX96)

-- Standardized linear P = s² as PayoffX96.
linearPayoff :: SqrtPriceX96 -> PayoffX96
linearPayoff = Payoff.squareSqrtPrice

linear :: Payoff.Payoff SqrtPriceX96
linear = Payoff.Payoff linearPayoff
