{-# LANGUAGE PatternSynonyms #-}

module Greeks.Delta
  ( Delta(..)
  , DeltaX96(..)
  , PriceDeltaX96(..)
  , PayoffDelta(..)
  , deltaOfPayoff
  , pattern DELTA_ATM
  , coveredCallDelta
  , rangeAccrualDelta
  , cpmmDelta
  , strikeFromDelta
  ) where

import qualified Payoffs.Payoff as Payoff

import OptionRatio (OptionRatio(..))
import SqrtGrid
  ( integerSqrt
  , mulDiv
  , SqrtPriceX96(..)
  , PayoffX96(..)
  , pattern Q96
  )
import StrikeX96 (StrikeX96(..))

-- ∂V/∂P, dimensionless. Parameterized by strike and range ratio r.
newtype Delta = Delta { runDelta :: SqrtPriceX96 -> Rational }

-- Target δ ∈ [0, 1] in Q96 (Kristensen 3.23).
newtype DeltaX96 = DeltaX96 Integer
  deriving (Show, Eq, Ord)

-- | ∂_P V of a token1-valued payoff V with respect to PRICE P = p²/Q96:
-- ΔV · Q96 / ΔP, i.e. a raw token0 amount (signed).  This is the delta that
-- the hedge ledger of the rebate note (Defs 12–14) tracks in token units.
newtype PriceDeltaX96 = PriceDeltaX96 Integer
  deriving (Show, Eq, Ord)

-- | A delta is a function of a payoff: `PayoffDelta` is the ∂_P of SOME
-- `Payoff SqrtPriceX96`.  `deltaOfPayoff` is the generic (finite-difference)
-- instance; `Payoffs.ReplicaDelta.replicaDelta` is the closed-form instance
-- for `fourLegReplica`, tested against the generic one.
newtype PayoffDelta = PayoffDelta { runPayoffDelta :: SqrtPriceX96 -> PriceDeltaX96 }

-- | Central difference in price, bump = p/2^16 in sqrt-price (≈ 0.3 bp in P,
-- ≈ 0.3 tick — narrower than any leg), floored at 1 wei.  Integer throughout; exact for payoffs that
-- are linear in P on the bump window, O(bump) at kinks.
deltaOfPayoff :: Payoff.Payoff SqrtPriceX96 -> PayoffDelta
deltaOfPayoff (Payoff.Payoff f) =
  PayoffDelta $ \(SqrtPriceX96 p) ->
    let h = max 1 (p `div` 65536)
        PayoffX96 vUp = f (SqrtPriceX96 (p + h))
        PayoffX96 vDn = f (SqrtPriceX96 (p - h))
        PayoffX96 pUp = Payoff.squareSqrtPrice (SqrtPriceX96 (p + h))
        PayoffX96 pDn = Payoff.squareSqrtPrice (SqrtPriceX96 (p - h))
    in  PriceDeltaX96 (mulDiv (vUp - vDn) Q96 (pUp - pDn))

-- δ = 1/2
pattern DELTA_ATM :: DeltaX96
pattern DELTA_ATM = DeltaX96 39614081257132168796771975168

-- (3.23) in price coordinates, then κ_{1/2} = √K · 2^96
strikeFromDelta
  :: SqrtPriceX96
  -> OptionRatio
  -> DeltaX96
  -> StrikeX96
strikeFromDelta spot (OptionRatio r) (DeltaX96 d)
  | d < 0 || d > Q96 =
      error "Greeks.Delta.strikeFromDelta: δ must satisfy 0 ≤ δ ≤ 1"
  | r <= 1 =
      error "Greeks.Delta.strikeFromDelta: r must be > 1"
  | otherwise =
      let
        PayoffX96 pPrice = Payoff.squareSqrtPrice spot
        deltaMath = fromInteger d / fromInteger Q96
        factor = (deltaMath * (r - 1) + 1) ** 2 / r
        kPrice = floor (fromInteger pPrice * factor)
      in
        StrikeX96 (integerSqrt (kPrice * Q96))

priceOfSqrt :: SqrtPriceX96 -> Integer
priceOfSqrt p =
  let PayoffX96 px = Payoff.squareSqrtPrice p
  in  px

priceOfStrike :: StrikeX96 -> Integer
priceOfStrike (StrikeX96 k) =
  priceOfSqrt (SqrtPriceX96 k)

coveredCallDelta :: StrikeX96 -> Delta
coveredCallDelta strike =
  Delta $ \sqrtPrice ->
    if priceOfSqrt sqrtPrice < priceOfStrike strike
      then 1
      else 0

-- Kristensen x_p for full V (CC + RA)
cpmmDelta :: StrikeX96 -> OptionRatio -> Delta
cpmmDelta strike (OptionRatio r) =
  Delta $ \sqrtPrice ->
    let
      p = priceOfSqrt sqrtPrice
      k = priceOfStrike strike
      lo = floor (fromInteger k / r)
      hi = floor (fromInteger k * r)
    in
      if p <= lo then 1
      else if p >= hi then 0
      else
        toRational $
          (sqrt (fromInteger k * r / fromInteger p) - 1) / (r - 1)

rangeAccrualDelta :: StrikeX96 -> OptionRatio -> Delta
rangeAccrualDelta strike ratio =
  Delta $ \sqrtPrice ->
    runDelta (cpmmDelta strike ratio) sqrtPrice
      - runDelta (coveredCallDelta strike) sqrtPrice
