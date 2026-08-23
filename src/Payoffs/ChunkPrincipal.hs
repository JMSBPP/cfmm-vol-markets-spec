{-# LANGUAGE PatternSynonyms #-}

-- | π^φ of a liquidity chunk: the Uniswap V3 position PRINCIPAL valued in
-- token1 at sqrt-price p½ (README "π^φ of a chunk", three-piece form;
-- = v3-periphery PositionValue.principal, amount0·P + amount1).
--
-- Per-tick CLMM identity (README MODEL_CLOSURE, TODO #24 / #35):
--
--   chunkPrincipal (unitChunk i Δ) p
--     = chunkAmount0 (unitChunk i Δ) · [π^{c|p}(k½) + π^RAN(k½, r)](p) / Q96
--
-- with k½ = √(p^bid p^ask) and r = p^ask/p^bid the SQRT-price ratio.  The
-- normalization is the unit chunk's token0 amount — it depends on (i, Δ_i),
-- not on Δ_i alone.  Witness test in test/Spec.hs.
module Payoffs.ChunkPrincipal
  ( chunkPrincipal
  , chunkAmount0
  , chunkAmount1
  , unitChunk
  , unitLiquidity
  ) where

import Liquidity.LiquidityChunk
  ( LiquidityChunk
  , chunkLiquidity
  , chunkTickLower
  , chunkTickUpper
  , createChunk
  )
import SqrtGrid
  ( PayoffX96(..)
  , SqrtPriceX96(..)
  , Tick
  , TickSpacing
  , pattern Q96
  , sqrtPriceX96
  , unTickSpacing
  )

-- | Id_i[𝓛𝓒] ≡ (i, i + Δ_i, 1e18): units handled on the EVM, 1e18 = one unit of L.
unitLiquidity :: Integer
unitLiquidity = 10 ^ (18 :: Int)

unitChunk :: Tick -> TickSpacing -> LiquidityChunk
unitChunk i spacing = createChunk i (i + unTickSpacing spacing) unitLiquidity

bounds :: LiquidityChunk -> (Integer, Integer, Integer)
bounds ch =
  let SqrtPriceX96 a = sqrtPriceX96 (chunkTickLower ch)
      SqrtPriceX96 b = sqrtPriceX96 (chunkTickUpper ch)
  in  (a, b, chunkLiquidity ch)

-- | token0 amount of the whole chunk when price is at/below p^bid:
--   L · (1/a − 1/b) = L · (b − a) · Q96 / (a · b)   (LiquidityAmounts.getAmount0ForLiquidity)
chunkAmount0 :: LiquidityChunk -> PayoffX96
chunkAmount0 ch =
  let (a, b, l) = bounds ch
  in  PayoffX96 $ (l * (b - a) * Q96) `div` (a * b)

-- | token1 amount of the whole chunk when price is at/above p^ask:
--   L · (b − a)   (LiquidityAmounts.getAmount1ForLiquidity)
chunkAmount1 :: LiquidityChunk -> PayoffX96
chunkAmount1 ch =
  let (a, b, l) = bounds ch
  in  PayoffX96 $ (l * (b - a)) `div` Q96

-- | Principal valued in token1 at sqrt-price p (all quantities Q96-scaled):
--   p < a      : L · p² · (1/a − 1/b)
--   a ≤ p < b  : L · (2p − a − p²/b)
--   p ≥ b      : L · (b − a)
chunkPrincipal :: LiquidityChunk -> SqrtPriceX96 -> PayoffX96
chunkPrincipal ch (SqrtPriceX96 p)
  | p < a     = PayoffX96 $ (l * p * p * (b - a)) `div` (a * b) `div` Q96
  | p < b     = PayoffX96 $ (l * (2 * p - a - (p * p) `div` b)) `div` Q96
  | otherwise = PayoffX96 $ (l * (b - a)) `div` Q96
  where
    (a, b, l) = bounds ch
