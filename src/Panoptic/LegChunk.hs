{-# LANGUAGE PatternSynonyms #-}

-- | The four leg chunks 𝓛𝓒_leg = (i⁻_leg, i⁺_leg, L_leg) of a 'MintPlan' —
-- the Haskell twin of PanopticMath.getLiquidityChunk(tokenId, leg, positionSize).
--
-- Geometry is decoded from the tokenId bits exactly as Panoptic's asTicks:
--   i⁻ = strike − width·Δ_i/2,  i⁺ = strike + width·Δ_i/2.
-- Size: the leg notional is or(leg)·ΔQ_υ in the numeraire selected by the
-- leg's `asset` bit — PanopticMath.getLiquidityChunk polarity:
--   asset == 0 → getLiquidityForAmount0 (token0):  L = amt·(a·b/Q96)/(b − a)
--   asset == 1 → getLiquidityForAmount1 (token1):  L = amt·Q96/(b − a)
-- volOrderToTokenId sets asset = 1 on every leg (single token1 basis, spec
-- 2026-08-24 §2), so all four legs are token1-sized. `asset` is independent
-- of `tokenType` (which still decides the token RECEIVED at mint).
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
  ( panopticAsset
  , panopticOptionRatio
  , panopticStrike
  , panopticTickSpacing
  , panopticWidth
  )
import SqrtGrid (SqrtPriceX96(..), Tick, mulDiv, pattern Q96, sqrtPriceX96)

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
  | asset == 0 = mulDiv amt (mulDiv a b Q96) (b - a)   -- Math.getLiquidityForAmount0: mulDiv(amt, mulDiv96(a,b), b−a)
  | otherwise  = mulDiv amt Q96 (b - a)                -- Math.getLiquidityForAmount1: mulDiv(amt, Q96, b−a)
  where
    tid = mintTokenId plan
    asset = panopticAsset tid (toInteger leg)
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
