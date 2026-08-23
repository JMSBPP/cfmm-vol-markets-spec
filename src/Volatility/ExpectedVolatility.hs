module Volatility.ExpectedVolatility
  ( ExpectedVolatility(..)
  , unExpectedVolatility
  , RealizedVolatility(..)
  , unRealizedVolatility
  , VolHorizon(..)
  , VolGap(..)
  , unVolGap
  , realizedVolatilityFromAverage
  , expectedVolatilityWindowStub
  , tenorTickPath
  , expectedVolatilityUniformTenor
  , volGap
  ) where

import qualified Data.Vector as V
import Pricing.InterestPriceMap (InterestPriceMap, priceTickAt)
import Pricing.InterestSqrt (InterestTick, mkInterestTick, unInterestTick)
import TickPath (TickPath(..))
import Volatility.ImpliedVolatility (ImpliedVolatility, unImpliedVolatility)
import Volatility.TickVolatility
  ( VolatilityAverage(..)
  , averageVolatility
  , unVolatilityAverage
  )

-- | σ^e in Algebra oracle integer units (same as VolatilityAverage).
newtype ExpectedVolatility = ExpectedVolatility Integer
  deriving (Show, Eq)

unExpectedVolatility :: ExpectedVolatility -> Integer
unExpectedVolatility (ExpectedVolatility x) = x

newtype RealizedVolatility = RealizedVolatility Integer
  deriving (Show, Eq)

unRealizedVolatility :: RealizedVolatility -> Integer
unRealizedVolatility (RealizedVolatility x) = x

newtype VolGap = VolGap Integer
  deriving (Show, Eq)

unVolGap :: VolGap -> Integer
unVolGap (VolGap x) = x

data VolHorizon
  = OracleWindowHorizon
  | TenorHorizon InterestTick
  deriving (Show, Eq)

realizedVolatilityFromAverage :: VolatilityAverage -> RealizedVolatility
realizedVolatilityFromAverage (VolatilityAverage x) = RealizedVolatility x

-- VISIBLE NOTE: Slice 1 non-𝔼^Q stub — WINDOW ensemble deferred to Slice 3.
expectedVolatilityWindowStub :: VolatilityAverage -> ExpectedVolatility
expectedVolatilityWindowStub (VolatilityAverage x) = ExpectedVolatility x

tenorTickPath :: InterestPriceMap -> InterestTick -> InterestTick -> TickPath
tenorTickPath ipm t0 tR =
  let
    a = unInterestTick t0
    b = unInterestTick tR
    lo = min a b
    hi = max a b
    n = hi - lo + 1
    vec =
      V.generate n $ \j ->
        priceTickAt ipm (mkInterestTick (lo + j))
  in
    if n >= 2
      then TickPath n vec
      else
        let ti = priceTickAt ipm t0
        in TickPath 2 (V.replicate 2 ti)

expectedVolatilityUniformTenor
  :: InterestPriceMap
  -> InterestTick
  -> InterestTick
  -> ExpectedVolatility
expectedVolatilityUniformTenor ipm t0 tR =
  ExpectedVolatility $
    unVolatilityAverage (averageVolatility (tenorTickPath ipm t0 tR))

volGap :: ImpliedVolatility -> ExpectedVolatility -> VolGap
volGap iv (ExpectedVolatility ev) =
  VolGap (unImpliedVolatility iv - ev)
