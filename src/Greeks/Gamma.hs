{-# LANGUAGE PatternSynonyms #-}

module Greeks.Gamma
  ( Gamma(..)
  , coveredCallGamma
  , rangeAccrualGamma
  , cpmmGamma
  ) where

import qualified Payoffs.Payoff as Payoff

import OptionRatio (OptionRatio(..))
import SqrtGrid
  ( PayoffX96(..)
  , SqrtPriceX96(..)
  )
import StrikeX96 (StrikeX96(..))

-- ∂²V/∂P² = ∂δ/∂P. Units 1/price. Parameterized by strike and range ratio r.
newtype Gamma = Gamma { runGamma :: SqrtPriceX96 -> Rational }

priceOfSqrt :: SqrtPriceX96 -> Integer
priceOfSqrt p =
  let PayoffX96 px = Payoff.squareSqrtPrice p
  in  px

priceOfStrike :: StrikeX96 -> Integer
priceOfStrike (StrikeX96 k) =
  priceOfSqrt (SqrtPriceX96 k)

-- Dirac at K; zero on a discrete grid.
coveredCallGamma :: StrikeX96 -> Gamma
coveredCallGamma _ =
  Gamma $ const 0

-- Kristensen (3.24) for full V (CC + RA). LP Γ ≤ 0.
cpmmGamma :: StrikeX96 -> OptionRatio -> Gamma
cpmmGamma strike (OptionRatio r) =
  Gamma $ \sqrtPrice ->
    let
      p = priceOfSqrt sqrtPrice
      k = priceOfStrike strike
      lo = floor (fromInteger k / r)
      hi = floor (fromInteger k * r)
    in
      if p <= lo || p >= hi || p <= 0
        then 0
        else
          toRational $
            (-0.5)
              * sqrt (fromInteger k * r)
              / ((r - 1) * (fromInteger p ** 1.5))

-- Covered-call Γ is 0 almost everywhere, so RA Γ = CPMM Γ.
rangeAccrualGamma :: StrikeX96 -> OptionRatio -> Gamma
rangeAccrualGamma strike ratio =
  cpmmGamma strike ratio

-- Kristensen plots −Γ because Γ itself is negative.
