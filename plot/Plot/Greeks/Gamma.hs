-- | Chart layouts for 'Greeks.Gamma'.  Split out of the pure module so that
-- consumers of the numeric core do not compile Chart/cairo.
module Plot.Greeks.Gamma
  ( gammaLayout
  , kristensenGammaLayoutVsGamma
  ) where

import Data.Colour
import Data.Colour.Names
import Graphics.Rendering.Chart.Easy

import Greeks.Gamma (Gamma(..), cpmmGamma)
import OptionRatio (OptionRatio)
import Pricing.PriceDeformation (EtaX96)
import SqrtGrid
  ( SqrtPlot(..)
  , SqrtPriceX96(..)
  , Tick
  , TickSpacing
  , sqrtPriceX96
  , toDouble
  , unTickSpacing
  )
import StrikeX96 (StrikeX96)
import Volatility.VolatilityGrid (gammaCoordinate)

gammaLayout
  :: SqrtPlot
  -> StrikeX96
  -> OptionRatio
  -> Layout Double Double
gammaLayout config k r =
  execEC $ do
    let
      SqrtPriceX96 lowerBound = xMin config
      SqrtPriceX96 upperBound = xMax config
      numberOfSamples = 500 :: Integer
      sampleStep =
        max 1 ((upperBound - lowerBound) `div` numberOfSamples)
      samples =
        [ SqrtPriceX96 raw
        | raw <- [lowerBound, lowerBound + sampleStep .. upperBound]
        ]
      seriesPoints (Gamma g) =
        [ (toDouble sample, negate (fromRational (g sample) :: Double))
        | sample <- samples
        ]

    layout_title .= "−Γ_π₉₆"
    layout_x_axis . laxis_title .= "sqrtPriceX96"
    layout_y_axis . laxis_title .= "−Gamma"
    setColors [opaque blue]

    plot $ line "−Γ CPMM" [seriesPoints (cpmmGamma k r)]

-- Interior of [k/r, kr] only: −Γ = |c| Γ_φ, a ray. Wings (Γ=0) dropped.
kristensenGammaLayoutVsGamma
  :: StrikeX96
  -> OptionRatio
  -> Integer
  -> EtaX96
  -> TickSpacing
  -> Tick
  -> Int
  -> Layout Double Double
kristensenGammaLayoutVsGamma strike ratio xiWord eta spacing iMin nRungs =
  execEC $ do
    let
      Gamma g = cpmmGamma strike ratio
      rungs = [0 .. nRungs - 1]
      tickOf x = iMin + x * unTickSpacing spacing
      seriesPts =
        [ (fromInteger coord, negate (fromRational (g spot) :: Double))
        | x <- rungs
        , let i = tickOf x
        , let spot = sqrtPriceX96 i
        , g spot /= 0
        , let coord = gammaCoordinate xiWord eta spacing i
        ]
    layout_title .= "−Γ Kristensen on gammaCoordinate (interior)"
    layout_x_axis . laxis_title .= "uint256 gammaCoordinate"
    layout_y_axis . laxis_title .= "−Gamma"
    setColors [opaque blue]
    plot $ line "−Γ CPMM" [seriesPts]
