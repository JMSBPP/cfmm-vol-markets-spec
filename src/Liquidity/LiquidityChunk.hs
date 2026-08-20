module Liquidity.LiquidityChunk
  ( LiquidityChunk
  , createChunk
  , unLiquidityChunk
  , chunkTickLower
  , chunkTickUpper
  , chunkLiquidity
  ) where

import Data.Bits (shiftL, shiftR, (.&.))
import SqrtGrid (Tick)

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
