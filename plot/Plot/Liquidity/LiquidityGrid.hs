{-# LANGUAGE PatternSynonyms #-}

-- | Chart layouts for 'Liquidity.LiquidityGrid'.  Split out of the pure module so that
-- consumers of the numeric core do not compile Chart/cairo.
module Plot.Liquidity.LiquidityGrid
  ( liquidityLayout
  , liquidityLayoutVsGamma
  , liquidityLayoutVsSqrtPrice
  ) where

import Data.Colour
import Data.Colour.Names
import Graphics.Rendering.Chart.Easy
import Pricing.PriceDeformation (EtaX96)
import SqrtGrid
  ( SqrtPriceX96(..)
  , Tick
  , TickSpacing
  , invX96
  , pattern Q96
  , rpowX96
  , sqrtPriceX96
  , toDouble
  , unTickSpacing
  )
import Volatility.VolatilityGrid (gammaCoordinate)
import Liquidity.LiquidityGrid


liquidityLayoutAgainst
  :: String
  -> String
  -> (Int -> Double)
  -> XiX96
  -> LadderResolution
  -> Layout Double Double
liquidityLayoutAgainst title xTitle xAt xi iota =
  execEC $ do
    let
      n = unLadderResolution iota
      rungs = [0 .. n - 1]
      xs = map xAt rungs
      ys =
        [ liquidityDensityToDouble (ell xi iota x)
        | x <- rungs
        ]
    layout_title .= title
    layout_x_axis . laxis_title .= xTitle
    layout_y_axis . laxis_title .= "uint256 liquidityDensityX96"
    setColors [opaque blue]
    plot $ line "liquidityDensityX96" [zip xs ys]

liquidityLayout
  :: XiX96
  -> LadderResolution
  -> Layout Double Double
liquidityLayout xi iota =
  liquidityLayoutAgainst
    "liquidityDensityX96 on ξ-coordinate"
    "xiCoordinate (Q96)"
    (\x -> fromInteger (unXiX96 (xiCoordinate xi x)))
    xi
    iota

liquidityLayoutVsGamma
  :: XiX96
  -> EtaX96
  -> TickSpacing
  -> Tick
  -> LadderResolution
  -> Layout Double Double
liquidityLayoutVsGamma xi eta spacing iMin iota =
  liquidityLayoutAgainst
    "liquidityDensityX96 on gammaCoordinate"
    "uint256 gammaCoordinate"
    (\x ->
        fromInteger $
          gammaCoordinate
            (unXiX96 xi)
            eta
            spacing
            (rungTick iMin spacing x)
    )
    xi
    iota

liquidityLayoutVsSqrtPrice
  :: XiX96
  -> TickSpacing
  -> Tick
  -> LadderResolution
  -> Layout Double Double
liquidityLayoutVsSqrtPrice xi spacing iMin iota =
  liquidityLayoutAgainst
    "liquidityDensityX96 on sqrtPriceX96"
    "sqrtPriceX96"
    (\x -> toDouble (sqrtPriceX96 (rungTick iMin spacing x)))
    xi
    iota

rungTick :: Tick -> TickSpacing -> Int -> Tick
rungTick iMin spacing x =
  iMin + x * unTickSpacing spacing
