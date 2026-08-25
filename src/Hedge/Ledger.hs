{-# LANGUAGE PatternSynonyms #-}

-- | Hedge ledger — Defs 13–14 of the delta-hedge rebate note
-- (docs/superpowers/specs/2026-08-25-scratchpad-delta-hedge-rebate-design.md).
--
-- State per position: (h, B_s, B_r) = (token0 delta already hedged, streamia paid,
-- rebates paid), invariant B_r ≤ B_s.  A holder swap moving p_before → p_after
-- with signed token0 flow q (q > 0: holder receives token0) has target
-- Δ* = Δ̂^σ(p_after) (Payoffs.ReplicaDelta, raw token0); the qualifying part is
-- the portion of q that moves h toward Δ*:
--   q* = sgn(Δ* − h) · min(|q|, |Δ* − h|)  if sgn q = sgn(Δ* − h), else 0.
-- Rebate ρ = min(φ · value1(q*, p_after), B_s − B_r), value1 = |q*|·P/Q96 in token1;
-- then h ← h + q*, B_r ← B_r + ρ.  Re-submitting a hedged delta gives q* = 0, ρ = 0.
-- Amendment to the note's Def 14: q is in token0 (the delta's unit); the fee on it
-- is valued in token1 at p_after.  All Integer, mulDiv staged (docs/BITWIDTHS.md).
module Hedge.Ledger
  ( Ledger(..)
  , emptyLedger
  , payStreamia
  , HolderSwap(..)
  , RebateX96(..)
  , qualifying
  , hedgeStep
  , ledgerInvariant
  ) where

import Greeks.Delta (PayoffDelta(..), PriceDeltaX96(..))
import Pricing.Stremia (FeePips, unFeePips)
import SqrtGrid (SqrtPriceX96(..), mulDiv, pattern Q96)

data Ledger = Ledger
  { hedged       :: Integer   -- h, raw token0, signed
  , streamiaPaid :: Integer   -- B_s, raw token1
  , rebated      :: Integer   -- B_r, raw token1
  }
  deriving (Show, Eq)

emptyLedger :: Ledger
emptyLedger = Ledger 0 0 0

-- | Streamia accrues to the budget; never decreases it.
payStreamia :: Integer -> Ledger -> Ledger
payStreamia s led
  | s < 0     = error "Hedge.Ledger.payStreamia: streamia must be ≥ 0"
  | otherwise = led { streamiaPaid = streamiaPaid led + s }

-- | One swap by the position holder.
data HolderSwap = HolderSwap
  { swapAfter  :: SqrtPriceX96   -- p_after
  , swapToken0 :: Integer        -- q, signed raw token0 the holder receives
  }
  deriving (Show, Eq)

newtype RebateX96 = RebateX96 Integer
  deriving (Show, Eq, Ord)

-- | q* of Def 14.
qualifying :: Integer -> Integer -> Integer -> Integer
qualifying deltaStar h q
  | gap == 0 || q == 0        = 0
  | signum q /= signum gap    = 0
  | otherwise                 = signum gap * min (abs q) (abs gap)
  where gap = deltaStar - h

-- | (Ledger, ρ) after the holder's swap; the delta is the payoff's (Def 12 instance).
hedgeStep :: FeePips -> PayoffDelta -> Ledger -> HolderSwap -> (Ledger, RebateX96)
hedgeStep phi (PayoffDelta delta) led (HolderSwap pAfter@(SqrtPriceX96 p) q) =
  let PriceDeltaX96 deltaStar = delta pAfter
      qStar  = qualifying deltaStar (hedged led) q
      value1 = mulDiv (mulDiv p p Q96) (abs qStar) Q96      -- |q*| valued in token1 at p_after
      feeOn  = mulDiv value1 (unFeePips phi) 1000000
      budget = streamiaPaid led - rebated led
      rho    = max 0 (min feeOn budget)
      led'   = led { hedged = hedged led + qStar, rebated = rebated led + rho }
  in  (led', RebateX96 rho)

ledgerInvariant :: Ledger -> Bool
ledgerInvariant led = rebated led <= streamiaPaid led && rebated led >= 0
