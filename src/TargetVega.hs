module TargetVega
  ( TargetVega
  , mkTargetVega
  , unTargetVega
  , positionSizeForTargetVega
  , targetVegaFromMint
  , targetVegaFromMints
  ) where

import Liquidity.LiquidityChunk (chunkLiquidity)
import Payoffs.MintPlan (MintPlan(..), PanopticTokenId(..))

newtype TargetVega = TargetVega Integer
  deriving (Show, Eq)

mkTargetVega :: Integer -> TargetVega
mkTargetVega v
  | v <= 0 =
      error "TargetVega.mkTargetVega: ΔQ_v must be > 0"
  | otherwise = TargetVega v

unTargetVega :: TargetVega -> Integer
unTargetVega (TargetVega v) = v

-- Identity this round: tokenId is scale-free; ΔQ_v* is the SFPM uint128 scalar.
positionSizeForTargetVega :: TargetVega -> Integer
positionSizeForTargetVega = unTargetVega

u128Max :: Integer
u128Max = 2 ^ (128 :: Int) - 1

targetVegaFromMint :: MintPlan -> TargetVega
targetVegaFromMint plan
  | numLegs (mintTokenId plan) /= 4 =
      error "TargetVega.targetVegaFromMint: num_legs must be 4"
  | chunkLiquidity (mintChunk plan) <= 0
      || chunkLiquidity (mintChunk plan) > u128Max =
      error "TargetVega.targetVegaFromMint: chunk liquidity must fit uint128 and be > 0"
  | otherwise = mkTargetVega (chunkLiquidity (mintChunk plan))

targetVegaFromMints :: [MintPlan] -> TargetVega
targetVegaFromMints [] =
  error "TargetVega.targetVegaFromMints: need at least one mint"
targetVegaFromMints ps =
  mkTargetVega $
    sum [ unTargetVega (targetVegaFromMint p) | p <- ps ]
