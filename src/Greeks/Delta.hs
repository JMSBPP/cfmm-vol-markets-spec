{-# LANGUAGE PatternSynonyms #-}

module Greeks.Delta
  ( Delta(..)
  , DeltaX96(..)
  , pattern DELTA_ATM
  , coveredCallDelta
  , rangeAccrualDelta
  , cpmmDelta
  , strikeFromDelta
  , deltaLayout
  ) where

import Data.Colour
import Data.Colour.Names
import Graphics.Rendering.Chart.Easy

import qualified Payoffs.Payoff as Payoff

import OptionRatio (OptionRatio(..))
import SqrtGrid
  ( integerSqrt
  , SqrtPriceX96(..)
  , PayoffX96(..)
  , SqrtPlot(..)
  , pattern Q96
  , toDouble
  )
import StrikeX96 (StrikeX96(..))

-- ∂V/∂P, dimensionless. Parameterized by strike and range ratio r.
newtype Delta = Delta { runDelta :: SqrtPriceX96 -> Rational }

-- Target δ ∈ [0, 1] in Q96 (Kristensen 3.23).
newtype DeltaX96 = DeltaX96 Integer
  deriving (Show, Eq, Ord)

-- δ = 1/2
pattern DELTA_ATM :: DeltaX96
pattern DELTA_ATM = DeltaX96 39614081257132168796771975168


-- (3.23) in price coordinates, then κ_{1/2} = √K · 2^96
strikeFromDelta
  :: SqrtPriceX96
  -> OptionRatio
  -> DeltaX96
  -> StrikeX96
strikeFromDelta spot (OptionRatio r) (DeltaX96 d)
  | d < 0 || d > Q96 =
      error "Greeks.Delta.strikeFromDelta: δ must satisfy 0 ≤ δ ≤ 1"
  | r <= 1 =
      error "Greeks.Delta.strikeFromDelta: r must be > 1"
  | otherwise =
      let
        PayoffX96 pPrice = Payoff.squareSqrtPrice spot
        deltaMath = fromInteger d / fromInteger Q96
        factor = (deltaMath * (r - 1) + 1) ** 2 / r
        kPrice = floor (fromInteger pPrice * factor)
      in
        StrikeX96 (integerSqrt (kPrice * Q96))

priceOfSqrt :: SqrtPriceX96 -> Integer
priceOfSqrt p =
  let PayoffX96 px = Payoff.squareSqrtPrice p
  in  px

priceOfStrike :: StrikeX96 -> Integer
priceOfStrike (StrikeX96 k) =
  priceOfSqrt (SqrtPriceX96 k)

coveredCallDelta :: StrikeX96 -> Delta
coveredCallDelta strike =
  Delta $ \sqrtPrice ->
    if priceOfSqrt sqrtPrice < priceOfStrike strike
      then 1
      else 0

-- Kristensen x_p for full V (CC + RA)
cpmmDelta :: StrikeX96 -> OptionRatio -> Delta
cpmmDelta strike (OptionRatio r) =
  Delta $ \sqrtPrice ->
    let
      p = priceOfSqrt sqrtPrice
      k = priceOfStrike strike
      lo = floor (fromInteger k / r)
      hi = floor (fromInteger k * r)
    in
      if p <= lo then 1
      else if p >= hi then 0
      else
        toRational $
          (sqrt (fromInteger k * r / fromInteger p) - 1) / (r - 1)

rangeAccrualDelta :: StrikeX96 -> OptionRatio -> Delta
rangeAccrualDelta strike ratio =
  Delta $ \sqrtPrice ->
    runDelta (cpmmDelta strike ratio) sqrtPrice
      - runDelta (coveredCallDelta strike) sqrtPrice

deltaLayout
  :: SqrtPlot
  -> StrikeX96
  -> OptionRatio
  -> Layout Double Double
deltaLayout config k r =
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
      seriesPoints (Delta d) =
        [ (toDouble sample, fromRational (d sample) :: Double)
        | sample <- samples
        ]

    layout_title .= "Δ_π₉₆"
    layout_x_axis . laxis_title .= "sqrtPriceX96"
    layout_y_axis . laxis_title .= "Delta"
    setColors [opaque blue, opaque red, opaque green]

    plot $ line "Δ Covered Call" [seriesPoints (coveredCallDelta k)]
    plot $ line "Δ Range Accrual" [seriesPoints (rangeAccrualDelta k r)]
    plot $ line "Δ CPMM" [seriesPoints (cpmmDelta k r)]
