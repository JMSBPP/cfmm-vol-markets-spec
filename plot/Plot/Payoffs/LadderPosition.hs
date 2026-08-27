{-# LANGUAGE PatternSynonyms #-}

-- | Chart layouts for 'Payoffs.LadderPosition'.  Split out of the pure module so that
-- consumers of the numeric core do not compile Chart/cairo.
module Plot.Payoffs.LadderPosition
  ( ladderLayout
  , ladderDensityLayout
  ) where

import Graphics.Rendering.Chart.Easy (Layout)
import Liquidity.LiquidityChunk
  ( chunkLiquidity
  , chunkTickLower
  )
import Plotting.PlotSqrt (PlotY(..), sqrtFunctionLayout)
import SqrtGrid
  ( PayoffX96(..)
  , SqrtPlot
  , SqrtPriceX96(..)
  , sqrtPriceX96
  , unTickSpacing
  )
import Payoffs.LadderPosition

-- | T1/N_1 vs c(S)·logPortfolio on one sqrt axis (Theorem 10 overlay).
ladderLayout :: SqrtPlot -> Ladder -> Layout Double Double
ladderLayout config l =
  let s = ladderHi l - ladderLo l
      c = cOfS s
      pStar = sqrtPriceX96 (ladderStar l)
      scaledT0 p = let PayoffX96 y = logPortfolioQ96 p pStar in PayoffX96 (floor (c * fromIntegral y))
  in  sqrtFunctionLayout config PayoffY
        [ ("T1/N_1 (ladder, ξ*)", ladderReturnQ96 l)
        , ("c(S)·logPortfolio (T0)", scaledT0)
        ]

-- | Rung liquidities L(i_x) as a step function of sqrt price.
ladderDensityLayout :: SqrtPlot -> Ladder -> Layout Double Double
ladderDensityLayout config l =
  let chs = ladderChunks l
      d = unTickSpacing (ladderSpacing l)
      at (SqrtPriceX96 p) =
        PayoffX96 $ sum [ chunkLiquidity ch
                        | ch <- chs
                        , let SqrtPriceX96 a = sqrtPriceX96 (chunkTickLower ch)
                        , let SqrtPriceX96 b = sqrtPriceX96 (chunkTickLower ch + d)
                        , a <= p && p < b ]
  in  sqrtFunctionLayout config PayoffY [ ("L(i_x) = ΔQ·ℓ(ξ*,ι;x)", at) ]
