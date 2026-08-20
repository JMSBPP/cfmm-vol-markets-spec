{-# LANGUAGE PatternSynonyms #-}

module Payoffs.Savings
  ( savingsPayoff
  , savings
  ) where

import Payoffs.Payoff (Payoff(..))
import Pricing.InterestSqrt (InterestSqrtX96(..))
import SqrtGrid (PayoffX96(..), pattern Q96)

-- | Interest-domain linear level: \(Y = s_r^{2} = 1+r = \lambda^{t}\).
savingsPayoff :: InterestSqrtX96 -> PayoffX96
savingsPayoff (InterestSqrtX96 s) =
  PayoffX96 $ (s * s) `div` Q96

savings :: Payoff InterestSqrtX96
savings = Payoff savingsPayoff
