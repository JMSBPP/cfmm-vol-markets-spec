{-# LANGUAGE PatternSynonyms #-}
module Liquidity.LiquidityChunk
  ( LiquidityChunk
  , createChunk
  , unLiquidityChunk
  , chunkTickLower
  , chunkTickUpper
  , chunkLiquidity
  , chunkAmount0
  , chunkAmount1
  , unitChunk
  , unitLiquidity
  ) where

import Data.Bits (shiftL, shiftR, (.&.))
import SqrtGrid
  ( PayoffX96(..)
  , SqrtPriceX96(..)
  , Tick
  , TickSpacing
  , pattern Q96
  , sqrtPriceX96
  , unTickSpacing
  )

newtype LiquidityChunk = LiquidityChunk Integer
  deriving (Show, Eq)

u128Max :: Integer
u128Max = 2 ^ (128 :: Int) - 1

mask24 :: Integer
mask24 = 0xffffff

createChunk :: Tick -> Tick -> Integer -> LiquidityChunk
createChunk lo hi liq
  | lo >= hi =
      error "Liquidity.LiquidityChunk.createChunk: tickLower must be < tickUpper"
  | liq <= 0 || liq > u128Max =
      error "Liquidity.LiquidityChunk.createChunk: liquidity must fit uint128 and be > 0"
  | otherwise =
      LiquidityChunk $
        shiftL (toInteger lo .&. mask24) 232
          + shiftL (toInteger hi .&. mask24) 208
          + liq

signExtend24 :: Integer -> Integer
signExtend24 w =
  if w >= 0x800000 then w - 0x1000000 else w

chunkTickLower :: LiquidityChunk -> Tick
chunkTickLower (LiquidityChunk w) =
  fromInteger (signExtend24 (shiftR w 232 .&. mask24))

chunkTickUpper :: LiquidityChunk -> Tick
chunkTickUpper (LiquidityChunk w) =
  fromInteger (signExtend24 (shiftR w 208 .&. mask24))

chunkLiquidity :: LiquidityChunk -> Integer
chunkLiquidity (LiquidityChunk w) = w .&. u128Max

unLiquidityChunk :: LiquidityChunk -> Integer
unLiquidityChunk (LiquidityChunk w) = w

-- | Id_i[𝓛𝓒] ≡ (i, i + Δ_i, 1e18): units handled on the EVM, 1e18 = one unit of L.
unitLiquidity :: Integer
unitLiquidity = 10 ^ (18 :: Int)

unitChunk :: Tick -> TickSpacing -> LiquidityChunk
unitChunk i spacing = createChunk i (i + unTickSpacing spacing) unitLiquidity

sqrtBounds :: LiquidityChunk -> (Integer, Integer)
sqrtBounds ch =
  let SqrtPriceX96 a = sqrtPriceX96 (chunkTickLower ch)
      SqrtPriceX96 b = sqrtPriceX96 (chunkTickUpper ch)
  in  (a, b)

-- | token0 amount of the chunk when price is at/below p^bid:
--   L · (1/a − 1/b) = L · (b − a) · Q96 / (a · b)   (LiquidityAmounts.getAmount0ForLiquidity).
--   By the per-tick CLMM identity (README, #35) this is the scale relating the
--   chunk principal to the unit CLMMPosition at k½ = √(ab), r = b/a.
chunkAmount0 :: LiquidityChunk -> PayoffX96
chunkAmount0 ch =
  let (a, b) = sqrtBounds ch
  in  PayoffX96 $ (chunkLiquidity ch * (b - a) * Q96) `div` (a * b)

-- | token1 amount of the chunk when price is at/above p^ask:
--   L · (b − a)   (LiquidityAmounts.getAmount1ForLiquidity)
chunkAmount1 :: LiquidityChunk -> PayoffX96
chunkAmount1 ch =
  let (a, b) = sqrtBounds ch
  in  PayoffX96 $ (chunkLiquidity ch * (b - a)) `div` Q96
