{-# LANGUAGE PatternSynonyms #-}

module Greeks.Gamma
  ( Gamma(..)
  , coveredCallGamma
  , rangeAccrualGamma
  , cpmmGamma
  , gammaLayout
  , kristensenGammaLayoutVsGamma
  ) where

import Data.Colour
import Data.Colour.Names
import Graphics.Rendering.Chart.Easy

import qualified Payoffs.Payoff as Payoff

import OptionRatio (OptionRatio(..))
import Pricing.PriceDeformation (EtaX96)
import SqrtGrid
  ( PayoffX96(..)
  , SqrtPlot(..)
  , SqrtPriceX96(..)
  , Tick
  , TickSpacing
  , sqrtPriceX96
  , toDouble
  , unTickSpacing
  )
import StrikeX96 (StrikeX96(..))
import Volatility.VolatilityGrid (gammaCoordinate)

-- ∂²V/∂P² = ∂δ/∂P. Units 1/price. Parameterized by strike and range ratio r.
newtype Gamma = Gamma { runGamma :: SqrtPriceX96 -> Rational }

priceOfSqrt :: SqrtPriceX96 -> Integer
priceOfSqrt p =
  let PayoffX96 px = Payoff.squareSqrtPrice p
  in  px

priceOfStrike :: StrikeX96 -> Integer
priceOfStrike (StrikeX96 k) =
  priceOfSqrt (SqrtPriceX96 k)

-- Dirac at K; zero on a discrete grid.
coveredCallGamma :: StrikeX96 -> Gamma
coveredCallGamma _ =
  Gamma $ const 0

-- Kristensen (3.24) for full V (CC + RA). LP Γ ≤ 0.
cpmmGamma :: StrikeX96 -> OptionRatio -> Gamma
cpmmGamma strike (OptionRatio r) =
  Gamma $ \sqrtPrice ->
    let
      p = priceOfSqrt sqrtPrice
      k = priceOfStrike strike
      lo = floor (fromInteger k / r)
      hi = floor (fromInteger k * r)
    in
      if p <= lo || p >= hi || p <= 0
        then 0
        else
          toRational $
            (-0.5)
              * sqrt (fromInteger k * r)
              / ((r - 1) * (fromInteger p ** 1.5))

-- Covered-call Γ is 0 almost everywhere, so RA Γ = CPMM Γ.
rangeAccrualGamma :: StrikeX96 -> OptionRatio -> Gamma
rangeAccrualGamma strike ratio =
  cpmmGamma strike ratio

-- Kristensen plots −Γ because Γ itself is negative.
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
