{-# LANGUAGE PatternSynonyms #-}

-- | Chart layouts for 'Payoffs.PathAccrual'.  Split out of the pure module so that
-- consumers of the numeric core do not compile Chart/cairo.
module Plot.Payoffs.PathAccrual
  ( linesLayout
  ) where

import Data.Colour
import Data.Colour.Names
import Graphics.Rendering.Chart.Easy
import Liquidity.LiquidityChunk
  ( LiquidityChunk
  , chunkLiquidity
  , chunkTickLower
  , chunkTickUpper
  )
import Panoptic.LegChunk (legChunks)
import Panoptic.MintPlan (MintPlan)
import Pricing.Stremia (FeePips, unFeePips)
import SqrtGrid (PayoffX96(..), SqrtPriceX96(..), Tick, mulDiv, pattern Q96, sqrtPriceX96)
import Payoffs.PathAccrual


-- | Named-lines layout. Axes carry EVM-representable numbers only (pips, ticks,
-- raw PayoffX96 words); Double appears here solely as the chart's coordinate type.
linesLayout :: String -> String -> String -> [(String, [(Integer, Integer)])] -> Layout Double Double
linesLayout title xTitle yTitle series = execEC $ do
  layout_title .= title
  layout_x_axis . laxis_title .= xTitle
  layout_y_axis . laxis_title .= yTitle
  setColors (map opaque [blue, red, darkgreen, orange, purple, black])
  mapM_ (\(name, pts) -> plot (line name [[ (fromIntegral x, fromIntegral y) | (x, y) <- pts ]])) series
