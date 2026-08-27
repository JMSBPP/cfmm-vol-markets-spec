{-# LANGUAGE PatternSynonyms #-}

-- | Δ̂^σ = ∂_P π̂^σ — the replica delta (rebate note Def 12), the closed-form
-- `Greeks.Delta.PayoffDelta` instance for `Payoffs.VolatilityReplica.fourLegReplica`.
--
-- Per leg, with 𝓛𝓒 = (a, b, L) in sqrt-price and P = p²:
--   ∂_P π^{ΔQ_X}(𝓛𝓒; P) = amount0(L, max(a, min(p, b)), b)   — the token0 the chunk
--                          holds at p (amount0(𝓛𝓒) below range, 0 above, continuous);
--   ∂_P H_leg            = 0 (put: H = amount1, constant) | amount0(𝓛𝓒) (call: H = P·amount0).
-- So Δ̂^σ = Σ_leg [∂_P H_leg − ∂_P π^{ΔQ_X}]: 0 at p* (all legs OTM), ≤ 0 below p*,
-- ≥ 0 above, nondecreasing (π̂^σ is convex).  Integer, `mulDiv` forms; raw token0.
-- Lean twin: `principal_price_deriv` (peer item, next to `principal_price_second_deriv`).
module Payoffs.ReplicaDelta
  ( replicaDelta
  , legDelta
  , principalDelta
  ) where

import Greeks.Delta (PayoffDelta(..), PriceDeltaX96(..))
import Liquidity.LiquidityChunk (LiquidityChunk, chunkAmount0, chunkLiquidity, chunkTickLower, chunkTickUpper)
import Panoptic.LegChunk (legChunk)
import Panoptic.MintPlan (MintPlan(..), fourLegNumLegs)
import Panoptic.NId (panopticTokenType)
import SqrtGrid (PayoffX96(..), SqrtPriceX96(..), mulDiv, pattern Q96, sqrtPriceX96)

-- | ∂_P of the chunk principal at p: token0 held = L·(b − p̄)·Q96/(p̄·b), p̄ = clamp(p; a, b).
-- Staged as `getAmount0ForLiquidity`: mulDiv(L << 96, b − p̄, b) / p̄.
principalDelta :: LiquidityChunk -> SqrtPriceX96 -> PriceDeltaX96
principalDelta ch (SqrtPriceX96 p) =
  let SqrtPriceX96 a = sqrtPriceX96 (chunkTickLower ch)
      SqrtPriceX96 b = sqrtPriceX96 (chunkTickUpper ch)
      pc = max a (min p b)
  in  PriceDeltaX96 (mulDiv (chunkLiquidity ch * Q96) (b - pc) b `div` pc)

-- | ∂_P [H_leg − π^{ΔQ_X}(𝓛𝓒_leg)] for one leg.
legDelta :: MintPlan -> Int -> SqrtPriceX96 -> PriceDeltaX96
legDelta plan leg p =
  let ch = legChunk plan leg
      PriceDeltaX96 dPrincipal = principalDelta ch p
      PayoffX96 am0 = chunkAmount0 ch
      dH | panopticTokenType (mintTokenId plan) (toInteger leg) == 0 = 0
         | otherwise = am0
  in  PriceDeltaX96 (dH - dPrincipal)

-- | Δ̂^σ(p) = Σ_leg legDelta.
replicaDelta :: MintPlan -> PayoffDelta
replicaDelta plan =
  PayoffDelta $ \p ->
    PriceDeltaX96 $ sum
      [ d | leg <- [0 .. fourLegNumLegs (mintTokenId plan) - 1]
          , let PriceDeltaX96 d = legDelta plan leg p ]
