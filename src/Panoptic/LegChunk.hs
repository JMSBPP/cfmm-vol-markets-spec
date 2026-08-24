{-# LANGUAGE PatternSynonyms #-}

-- | The four leg chunks 𝓛𝓒_leg = (i⁻_leg, i⁺_leg, L_leg) of a 'MintPlan' —
-- the Haskell twin of PanopticMath.getLiquidityChunk(tokenId, leg, positionSize).
--
-- Geometry is decoded from the tokenId bits exactly as Panoptic's asTicks:
--   i⁻ = strike − width·Δ_i/2,  i⁺ = strike + width·Δ_i/2.
-- Size (README "Per-leg option ratio and leg chunk"): the leg notional is
-- or(leg)·ΔQ_υ, in token1 for puts (tokenType 0) and token0 for calls
-- (tokenType 1), inverted to liquidity over the leg range
-- (LiquidityAmounts.getLiquidityForAmount1 / getLiquidityForAmount0):
--
--   L_leg = or·ΔQ_υ / (p½^ask − p½^bid)              (put,  token1 notional)
--   L_leg = or·ΔQ_υ / (1/p½^bid − 1/p½^ask)          (call, token0 notional)
--
-- ΔQ_υ is the SFPM positionSize = liquidity field of the envelope 'mintChunk'
-- (what 'targetVegaFromMint' reads).  The envelope chunk itself is NOT a leg.
module Panoptic.LegChunk
  ( legChunk
  , legChunks
  , legLiquidity
  , legTicks
  , legNotional
  ) where

import Liquidity.LiquidityChunk (LiquidityChunk, chunkLiquidity, createChunk)
import Panoptic.MintPlan (MintPlan(..), PanopticTokenId, fourLegNumLegs)
import Panoptic.NId
  ( panopticOptionRatio
  , panopticStrike
  , panopticTickSpacing
  , panopticTokenType
  , panopticWidth
  )
import SqrtGrid (SqrtPriceX96(..), Tick, pattern Q96, sqrtPriceX96)

-- | (i⁻, i⁺) of a leg, decoded from the tokenId (Panoptic asTicks).
legTicks :: PanopticTokenId -> Int -> (Tick, Tick)
legTicks tid leg =
  let l      = toInteger leg
      strike = panopticStrike tid l
      half   = (panopticWidth tid l * panopticTickSpacing tid) `div` 2
  in  (fromInteger (strike - half), fromInteger (strike + half))

-- | or(leg) · ΔQ_υ — the leg notional in its own token (raw units).
legNotional :: MintPlan -> Int -> Integer
legNotional plan leg =
  panopticOptionRatio (mintTokenId plan) (toInteger leg) * chunkLiquidity (mintChunk plan)

-- | L_leg: notional inverted to liquidity over the leg range.
legLiquidity :: MintPlan -> Int -> Integer
legLiquidity plan leg
  | leg < 0 || leg >= fourLegNumLegs (mintTokenId plan) =
      error "Panoptic.LegChunk.legLiquidity: leg out of range"
  | b <= a =
      error "Panoptic.LegChunk.legLiquidity: degenerate leg range"
  | tokenType == 0 = (amt * Q96) `div` (b - a)              -- put:  getLiquidityForAmount1
  | otherwise      = (amt * a * b) `div` ((b - a) * Q96)    -- call: getLiquidityForAmount0
  where
    tid = mintTokenId plan
    tokenType = panopticTokenType tid (toInteger leg)
    amt = legNotional plan leg
    (lo, hi) = legTicks tid leg
    SqrtPriceX96 a = sqrtPriceX96 lo
    SqrtPriceX96 b = sqrtPriceX96 hi

-- | 𝓛𝓒_leg.
legChunk :: MintPlan -> Int -> LiquidityChunk
legChunk plan leg =
  let (lo, hi) = legTicks (mintTokenId plan) leg
  in  createChunk lo hi (legLiquidity plan leg)

-- | All legs, in tokenId order (puts 0,1 below i*; calls 2,3 above).
legChunks :: MintPlan -> [LiquidityChunk]
legChunks plan =
  [ legChunk plan leg | leg <- [0 .. fourLegNumLegs (mintTokenId plan) - 1] ]
