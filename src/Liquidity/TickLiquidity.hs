module Liquidity.TickLiquidity
  ( TickLiquidity(..)
  , tickLiquidityAt
  ) where

import Liquidity.LiquidityChunk
  ( LiquidityChunk
  , chunkLiquidity
  , chunkTickLower
  , chunkTickUpper
  )
import Liquidity.LiquidityGrid (XiX96, unXiX96)
import SqrtGrid (Tick, mulX96)

-- | Per-tick active liquidity \(L_{(1/2,0)}(i)\) read by Def 45.
data TickLiquidity = TickLiquidity
  { tlTick :: Tick
  , tlLiquidity :: Integer
  }
  deriving (Show, Eq)

-- | Geometric book (Approach 1): \(L(\mathrm{lo})=\mathrm{chunk}\,L\);
-- \(L(\mathrm{hi})=L(\mathrm{lo})\cdot\xi\) so \(L_{\mathrm{hi}}/L_{\mathrm{lo}}=\xi\)
-- ⇒ Def 45 \(\kappa=1/(2\eta\Delta)\) (Thm 43 trading base).
-- Chunk×density mul deferred — see LiquidityDensity TODO.
tickLiquidityAt :: XiX96 -> LiquidityChunk -> Tick -> TickLiquidity
tickLiquidityAt xi ch tick =
  let
    lo = chunkTickLower ch
    hi = chunkTickUpper ch
    l0 = chunkLiquidity ch
  in
    if tick == lo
      then TickLiquidity lo l0
      else if tick == hi
        then TickLiquidity hi (mulX96 l0 (unXiX96 xi))
        else
          error
            "Liquidity.TickLiquidity.tickLiquidityAt: tick must be chunk lo or hi"
